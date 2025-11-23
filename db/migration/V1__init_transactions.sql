-- ============================================================================
-- TABLA RAW: raw_transactions
-- ============================================================================
-- Propósito: Almacenar datos crudos tal como vienen del archivo CSV
-- Granularidad: Una fila por línea del CSV original
-- Actualización: Incremental con cada carga de archivo

CREATE TABLE raw_transactions (
    -- ID autoincremental único para cada registro
    id SERIAL PRIMARY KEY,
    
    -- Línea completa del CSV sin procesar
    -- Almacena el texto original para auditoría y reprocesamiento
    csvline TEXT NOT NULL,
    
    -- Timestamp de cuando se insertó el registro en la base de datos
    -- Útil para tracking de carga y auditoría
    createdat TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índice para búsquedas por fecha de ingesta
CREATE INDEX idx_raw_transactions_createdat ON raw_transactions(createdat);

-- Comentarios a nivel de tabla y columnas para documentación
COMMENT ON TABLE raw_transactions IS 'Tabla de staging que almacena líneas crudas del CSV de transacciones sin procesamiento';
COMMENT ON COLUMN raw_transactions.id IS 'Identificador único autoincremental';
COMMENT ON COLUMN raw_transactions.csvline IS 'Línea completa del archivo CSV original para auditoría';
COMMENT ON COLUMN raw_transactions.createdat IS 'Fecha y hora de inserción del registro';


-- ============================================================================
-- TABLA FACT: fact_transactions
-- ============================================================================
-- Propósito: Almacenar transacciones procesadas y validadas
-- Granularidad: Una fila por transacción financiera
-- Actualización: Diaria desde raw_transactions mediante proceso ETL

CREATE TABLE fact_transactions (
    -- ID autoincremental único para cada transacción procesada
    id SERIAL PRIMARY KEY,
    
    -- Fecha en que ocurrió la transacción
    -- Rango esperado: 2020-01-01 a presente
    transactiondate DATE NOT NULL,
    
    -- Monto de la transacción en la moneda local
    -- Rango típico: 0.01 - 50,000.00
    -- Precisión: 2 decimales para centavos
    amount DECIMAL(12, 2) NOT NULL,
    
    -- Descripción textual de la transacción
    -- Incluye detalles del comercio, producto o servicio
    description TEXT NOT NULL,
    
    -- Categoría de la transacción para clasificación
    -- Ejemplos: 'groceries', 'transport', 'entertainment', 'utilities'
    -- Máximo 100 caracteres
    category VARCHAR(100) NOT NULL,
    
    -- Indicador de transacción sospechosa detectada por reglas de negocio
    -- True: requiere revisión manual
    -- False: transacción normal
    issuspicious BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Timestamp de creación del registro en esta tabla
    createdat TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints de validación
    CONSTRAINT chk_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_transactiondate_valid CHECK (transactiondate >= '2020-01-01' AND transactiondate <= CURRENT_DATE)
);

-- Índices para optimizar consultas comunes
CREATE INDEX idx_fact_transactions_date ON fact_transactions(transactiondate);
CREATE INDEX idx_fact_transactions_category ON fact_transactions(category);
CREATE INDEX idx_fact_transactions_suspicious ON fact_transactions(issuspicious);
CREATE INDEX idx_fact_transactions_createdat ON fact_transactions(createdat);

-- Índice compuesto para análisis por categoría y fecha
CREATE INDEX idx_fact_transactions_category_date ON fact_transactions(category, transactiondate);

-- Comentarios a nivel de tabla y columnas para documentación
COMMENT ON TABLE fact_transactions IS 'Tabla de hechos con transacciones procesadas y enriquecidas para análisis';
COMMENT ON COLUMN fact_transactions.id IS 'Identificador único autoincremental de la transacción';
COMMENT ON COLUMN fact_transactions.transactiondate IS 'Fecha de la transacción (sin hora)';
COMMENT ON COLUMN fact_transactions.amount IS 'Monto de la transacción con 2 decimales';
COMMENT ON COLUMN fact_transactions.description IS 'Descripción detallada de la transacción';
COMMENT ON COLUMN fact_transactions.category IS 'Categoría de clasificación de la transacción';
COMMENT ON COLUMN fact_transactions.issuspicious IS 'Indicador booleano de transacción sospechosa';
COMMENT ON COLUMN fact_transactions.createdat IS 'Fecha y hora de inserción del registro procesado';
