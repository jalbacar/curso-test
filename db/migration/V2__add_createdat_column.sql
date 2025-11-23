-- ============================================================================
-- MIGRACIÓN V2: Agregar columna createdat a fact_transactions
-- ============================================================================
-- Propósito: Añadir timestamp de creación del registro que falta en la tabla
-- Fecha: 2025-01-XX
-- Autor: Sistema PAC

-- Agregar columna createdat con valor por defecto
ALTER TABLE fact_transactions 
ADD COLUMN createdat TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Crear índice para optimizar búsquedas por fecha de creación
CREATE INDEX idx_fact_transactions_createdat ON fact_transactions(createdat);

-- Agregar columna createdat a raw_transactions también (si no existe)
ALTER TABLE raw_transactions 
ADD COLUMN IF NOT EXISTS createdat TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Comentario de documentación
COMMENT ON COLUMN fact_transactions.createdat IS 'Fecha y hora de inserción del registro procesado';
