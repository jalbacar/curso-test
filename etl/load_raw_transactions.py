#!/usr/bin/env python3
"""
Script ETL para carga de transacciones crudas desde CSV a PostgreSQL.

Este script lee un archivo CSV línea por línea (incluyendo líneas corruptas)
e inserta cada línea completa en la tabla raw_transactions para posterior
procesamiento y limpieza.

Autor: Sistema ETL
Fecha: 2025-11-23
"""

import os
import sys
import logging
import psycopg2
from datetime import datetime
from typing import Optional, Tuple
from pathlib import Path

# Cargar variables de entorno desde archivo .env
try:
    from dotenv import load_dotenv
    # Buscar .env en la raíz del proyecto (dos niveles arriba del script)
    env_path = Path(__file__).parent.parent / '.env'
    if env_path.exists():
        load_dotenv(dotenv_path=env_path)
    else:
        # Intentar en el directorio del script como fallback
        env_path = Path(__file__).parent / '.env'
        load_dotenv(dotenv_path=env_path)
except ImportError:
    # Si python-dotenv no está instalado, continuar sin él
    pass

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('etl_raw_transactions.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


def get_database_connection() -> Optional[psycopg2.extensions.connection]:
    """
    Establece conexión a la base de datos PostgreSQL usando variables de entorno.
    
    Variables de entorno requeridas:
        - DB_HOST: Host del servidor PostgreSQL
        - DB_PORT: Puerto del servidor (default: 5432)
        - DB_NAME: Nombre de la base de datos
        - DB_USER: Usuario de la base de datos
        - DB_PASSWORD: Contraseña del usuario
    
    Returns:
        psycopg2.extensions.connection: Objeto de conexión a PostgreSQL
        None: Si ocurre un error en la conexión
    
    Raises:
        psycopg2.Error: Si hay problemas al conectar a la base de datos
    """
    try:
        connection = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            port=os.getenv('DB_PORT', '5432'),
            database=os.getenv('DB_NAME', 'curso_db'),
            user=os.getenv('DB_USER', 'curso_user'),
            password=os.getenv('DB_PASSWORD', '')
        )
        logger.info(f"Conexión exitosa a PostgreSQL en {os.getenv('DB_HOST', 'localhost')}")
        return connection
    except psycopg2.Error as e:
        logger.error(f"Error al conectar a PostgreSQL: {e}")
        return None


def insert_raw_line(
    cursor: psycopg2.extensions.cursor,
    csv_line: str,
    line_number: int
) -> bool:
    """
    Inserta una línea cruda del CSV en la tabla raw_transactions.
    
    Args:
        cursor: Cursor de la conexión a PostgreSQL
        csv_line: Línea completa del archivo CSV (puede estar corrupta)
        line_number: Número de línea en el archivo (para tracking)
    
    Returns:
        bool: True si la inserción fue exitosa, False en caso contrario
    
    Notes:
        - No valida el contenido de la línea
        - Almacena la línea tal cual para auditoría
        - El timestamp createdat se genera automáticamente en la BD
    """
    try:
        # Query de inserción - csvline y createdat
        insert_query = """
            INSERT INTO raw_transactions (csvline, createdat)
            VALUES (%s, %s)
        """
        cursor.execute(insert_query, (csv_line.strip(), datetime.now()))
        return True
    except psycopg2.Error as e:
        logger.error(f"Error al insertar línea {line_number}: {e}")
        return False


def load_csv_to_raw(
    csv_file_path: str,
    connection: psycopg2.extensions.connection
) -> Tuple[int, int, int]:
    """
    Lee archivo CSV línea por línea e inserta en raw_transactions.
    
    Este proceso NO valida ni limpia los datos. El objetivo es preservar
    el contenido original del CSV para auditoría y reprocesamiento posterior.
    
    Args:
        csv_file_path: Ruta completa al archivo CSV a procesar
        connection: Conexión activa a PostgreSQL
    
    Returns:
        Tuple[int, int, int]: (total_lines, successful_inserts, failed_inserts)
    
    Raises:
        FileNotFoundError: Si el archivo CSV no existe
        IOError: Si hay problemas al leer el archivo
    
    Notes:
        - Procesa líneas corruptas sin fallar
        - Hace commit cada 100 líneas para optimizar performance
        - Registra estadísticas detalladas en el log
    """
    total_lines = 0
    successful_inserts = 0
    failed_inserts = 0
    batch_size = 100
    
    try:
        cursor = connection.cursor()
        logger.info(f"Iniciando carga desde archivo: {csv_file_path}")
        
        with open(csv_file_path, 'r', encoding='utf-8', errors='replace') as csv_file:
            for line_number, line in enumerate(csv_file, start=1):
                total_lines += 1
                
                # Insertar línea cruda (incluso si está corrupta)
                if insert_raw_line(cursor, line, line_number):
                    successful_inserts += 1
                else:
                    failed_inserts += 1
                
                # Commit por lotes para optimizar performance
                if total_lines % batch_size == 0:
                    connection.commit()
                    logger.info(
                        f"Procesadas {total_lines} líneas "
                        f"({successful_inserts} exitosas, {failed_inserts} fallidas)"
                    )
        
        # Commit final de las líneas restantes
        connection.commit()
        cursor.close()
        
        logger.info("=" * 70)
        logger.info("RESUMEN DE CARGA:")
        logger.info(f"Total de líneas procesadas: {total_lines}")
        logger.info(f"Inserciones exitosas: {successful_inserts}")
        logger.info(f"Inserciones fallidas: {failed_inserts}")
        logger.info(f"Tasa de éxito: {(successful_inserts/total_lines*100):.2f}%")
        logger.info("=" * 70)
        
        return total_lines, successful_inserts, failed_inserts
        
    except FileNotFoundError:
        logger.error(f"Archivo no encontrado: {csv_file_path}")
        raise
    except IOError as e:
        logger.error(f"Error al leer archivo CSV: {e}")
        raise
    except Exception as e:
        logger.error(f"Error inesperado durante la carga: {e}")
        connection.rollback()
        raise


def validate_environment_variables() -> bool:
    """
    Valida que las variables de entorno necesarias estén configuradas.
    
    Returns:
        bool: True si todas las variables requeridas están presentes
    
    Notes:
        - Verifica DB_HOST, DB_NAME, DB_USER, DB_PASSWORD
        - DB_PORT es opcional (default: 5432)
    """
    required_vars = ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD']
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        logger.error(f"Variables de entorno faltantes: {', '.join(missing_vars)}")
        logger.error("Configure las siguientes variables:")
        for var in required_vars:
            logger.error(f"  export {var}=<valor>")
        return False
    
    return True


def main():
    """
    Función principal que orquesta el proceso ETL de carga raw.
    
    Flujo:
        1. Valida variables de entorno
        2. Establece conexión a PostgreSQL
        3. Lee y carga el archivo CSV línea por línea
        4. Cierra la conexión
        5. Retorna código de salida apropiado
    
    Exit Codes:
        0: Proceso exitoso
        1: Error de configuración o conexión
        2: Error durante la carga de datos
    """
    logger.info("=" * 70)
    logger.info("INICIANDO PROCESO ETL - CARGA RAW TRANSACTIONS")
    logger.info("=" * 70)
    
    # Validar configuración
    if not validate_environment_variables():
        logger.error("Proceso abortado por falta de configuración")
        sys.exit(1)
    
    # Ruta al archivo CSV (relativa o absoluta)
    csv_file_path = os.getenv('CSV_FILE_PATH', '/workspace/transactions.csv')
    
    if not os.path.exists(csv_file_path):
        logger.error(f"El archivo CSV no existe: {csv_file_path}")
        logger.error("Especifique la ruta con la variable CSV_FILE_PATH")
        sys.exit(1)
    
    # Conectar a la base de datos
    connection = get_database_connection()
    if not connection:
        logger.error("No se pudo establecer conexión a PostgreSQL")
        sys.exit(1)
    
    try:
        # Ejecutar carga de datos
        total, success, failed = load_csv_to_raw(csv_file_path, connection)
        
        if failed > 0:
            logger.warning(f"Proceso completado con {failed} fallos")
            sys.exit(2)
        else:
            logger.info("Proceso completado exitosamente")
            sys.exit(0)
            
    except Exception as e:
        logger.error(f"Error crítico en el proceso ETL: {e}")
        sys.exit(2)
    finally:
        if connection:
            connection.close()
            logger.info("Conexión a PostgreSQL cerrada")


if __name__ == "__main__":
    main()
