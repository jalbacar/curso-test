-- V1__init_transactions.sql
-- Migración inicial para el sistema de transacciones
-- Compatible con PostgreSQL

-- ============================================================================
-- TABLA: raw_transactions
-- Propósito: Almacenar datos crudos de transacciones sin procesar
-- Uso: Staging area para ingesta de archivos CSV
-- ============================================================================
CREATE TABLE IF NOT EXISTS raw_transactions (
    -- Identificador único autoincremental de cada registro
    id SERIAL PRIMARY KEY,
    
    -- Línea completa del CSV tal como fue importada
    -- Permite trazabilidad y reingesta en caso de errores
    csvline TEXT NOT NULL,
    
    -- Timestamp de cuando se insertó el registro en la base de datos
    -- Útil para auditoría y control de versiones de datos
    createdat TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Comentarios descriptivos para documentación
COMMENT ON TABLE raw_transactions IS 'Tabla de staging para datos crudos de transacciones importadas desde CSV';
COMMENT ON COLUMN raw_transactions.id IS 'Identificador único autoincremental';
COMMENT ON COLUMN raw_transactions.csvline IS 'Contenido completo de la línea CSV sin procesar';
COMMENT ON COLUMN raw_transactions.createdat IS 'Fecha y hora de inserción del registro';

-- ============================================================================
-- TABLA: fact_transactions
-- Propósito: Almacenar transacciones procesadas y limpias
-- Uso: Tabla de hechos para análisis y reportes
-- ============================================================================
CREATE TABLE IF NOT EXISTS fact_transactions (
    -- Identificador único autoincremental de cada transacción
    id SERIAL PRIMARY KEY,
    
    -- Fecha en que ocurrió la transacción (sin hora)
    -- Campo clave para análisis temporal y agrupaciones
    transactiondate DATE NOT NULL,
    
    -- Monto de la transacción con 2 decimales de precisión
    -- Valores positivos = ingresos, negativos = gastos
    amount DECIMAL(10, 2) NOT NULL,
    
    -- Descripción detallada de la transacción
    -- Puede incluir nombre del comercio, concepto, etc.
    description TEXT,
    
    -- Categoría de la transacción (ej: 'Alimentación', 'Transporte', 'Entretenimiento')
    -- Asignada manualmente o por reglas de clasificación automática
    category VARCHAR(100),
    
    -- Indicador de transacción sospechosa
    -- TRUE si cumple con reglas de detección de anomalías (montos inusuales, patrones extraños)
    issuspicious BOOLEAN DEFAULT FALSE NOT NULL
);

-- Comentarios descriptivos para documentación
COMMENT ON TABLE fact_transactions IS 'Tabla de hechos con transacciones procesadas y clasificadas';
COMMENT ON COLUMN fact_transactions.id IS 'Identificador único autoincremental de la transacción';
COMMENT ON COLUMN fact_transactions.transactiondate IS 'Fecha de la transacción sin componente de tiempo';
COMMENT ON COLUMN fact_transactions.amount IS 'Monto de la transacción (positivo=ingreso, negativo=gasto)';
COMMENT ON COLUMN fact_transactions.description IS 'Descripción o concepto de la transacción';
COMMENT ON COLUMN fact_transactions.category IS 'Categoría clasificada de la transacción';
COMMENT ON COLUMN fact_transactions.issuspicious IS 'Indicador de transacción sospechosa o anómala';

-- ============================================================================
-- ÍNDICES
-- Propósito: Optimizar consultas frecuentes
-- ============================================================================

-- Índice para consultas por rango de fechas (muy común en reportes)
CREATE INDEX idx_fact_transactions_date ON fact_transactions(transactiondate);

-- Índice parcial para filtrado rápido de transacciones sospechosas
-- Solo indexa registros donde issuspicious = TRUE para optimizar espacio
CREATE INDEX idx_fact_transactions_suspicious ON fact_transactions(issuspicious) 
WHERE issuspicious = TRUE;

-- Índice para búsquedas por categoría (útil para análisis por tipo de gasto)
CREATE INDEX idx_fact_transactions_category ON fact_transactions(category);
