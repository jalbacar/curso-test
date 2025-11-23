# ETL - Load Raw Transactions

Script Python para cargar transacciones crudas desde CSV a PostgreSQL.

## 📋 Propósito

Este script lee un archivo CSV línea por línea (incluyendo líneas corruptas o malformadas) e inserta cada línea completa en la tabla `raw_transactions` sin validación ni transformación. El objetivo es preservar los datos originales para auditoría y procesamiento posterior.

## 🚀 Uso

### Variables de Entorno Requeridas

```bash
export DB_HOST=database
export DB_PORT=5432
export DB_NAME=curso_db
export DB_USER=curso_user
export DB_PASSWORD=your_password
export CSV_FILE_PATH=/workspace/transactions.csv
```

### Ejecución

```bash
# Desde el directorio raíz del proyecto
python etl/load_raw_transactions.py

# O hacerlo ejecutable
chmod +x etl/load_raw_transactions.py
./etl/load_raw_transactions.py
```

## 📊 Características

- ✅ **Manejo de datos corruptos**: Lee y almacena líneas malformadas sin fallar
- ✅ **Logging completo**: Registra todas las operaciones en archivo y consola
- ✅ **Commits por lotes**: Optimiza performance con commits cada 100 líneas
- ✅ **Manejo robusto de errores**: Captura y registra errores sin detener el proceso
- ✅ **Estadísticas detalladas**: Reporte final con métricas de carga
- ✅ **Docstrings completos**: Documentación en todas las funciones

## 📝 Logging

El script genera dos tipos de logs:

1. **Archivo**: `etl_raw_transactions.log`
2. **Consola**: Salida estándar (stdout)

## 🔄 Flujo del Proceso

1. Validación de variables de entorno
2. Conexión a PostgreSQL
3. Lectura del archivo CSV línea por línea
4. Inserción en `raw_transactions` (sin validación)
5. Commit por lotes (cada 100 líneas)
6. Reporte final de estadísticas

## 🎯 Códigos de Salida

- `0`: Proceso exitoso
- `1`: Error de configuración o conexión
- `2`: Error durante la carga de datos

## 📦 Dependencias

```bash
pip install psycopg2-binary
```

## 🔍 Ejemplo de Salida

```
======================================================================
INICIANDO PROCESO ETL - CARGA RAW TRANSACTIONS
======================================================================
2025-11-23 10:30:00 - __main__ - INFO - Conexión exitosa a PostgreSQL en database
2025-11-23 10:30:00 - __main__ - INFO - Iniciando carga desde archivo: /workspace/transactions.csv
2025-11-23 10:30:05 - __main__ - INFO - Procesadas 100 líneas (100 exitosas, 0 fallidas)
2025-11-23 10:30:10 - __main__ - INFO - Procesadas 200 líneas (200 exitosas, 0 fallidas)
======================================================================
RESUMEN DE CARGA:
Total de líneas procesadas: 234
Inserciones exitosas: 234
Inserciones fallidas: 0
Tasa de éxito: 100.00%
======================================================================
```
