/*
================================================================================
MODELO STAGING: stg_transactions
================================================================================
Propósito: Limpiar y normalizar datos crudos de raw_transactions

Transformaciones aplicadas:
- Parseo de líneas CSV a columnas estructuradas
- Normalización de fechas (formato yyyy-mm-dd)
- Filtrado de registros con valores nulos críticos
- Categorización automática de transacciones
- Detección de transacciones sospechosas
- Enriquecimiento con metadata de procesamiento

Fuente: raw_transactions (tabla de staging con líneas CSV crudas)
Granularidad: Una fila por transacción válida
Actualización: Diaria mediante proceso ETL
================================================================================
*/

WITH source AS (
    -- Seleccionar todas las líneas crudas de raw_transactions
    SELECT
        id AS raw_id,
        csvline,
        createdat AS ingested_at
    FROM {{ source('raw', 'raw_transactions') }}
),

parsed_data AS (
    -- Parsear el CSV usando split_part para extraer columnas
    -- Formato esperado: date,amount,description
    SELECT
        raw_id,
        csvline AS original_line,
        ingested_at,
        
        -- Extraer campos del CSV (delimitado por comas)
        TRIM(SPLIT_PART(csvline, ',', 1)) AS raw_date,
        TRIM(SPLIT_PART(csvline, ',', 2)) AS raw_amount,
        TRIM(SPLIT_PART(csvline, ',', 3)) AS raw_description
    FROM source
    
    -- Filtrar línea de encabezado y líneas vacías
    WHERE csvline NOT ILIKE 'date,amount,description%'
      AND LENGTH(TRIM(csvline)) > 0
),

cleaned_data AS (
    -- Limpiar y convertir tipos de datos
    SELECT
        raw_id,
        original_line,
        ingested_at,
        
        -- Normalizar fecha: convertir formatos variados a DATE
        -- Maneja: yyyy-mm-dd y yyyy/mm/dd
        CASE
            WHEN raw_date ~ '^\d{4}-\d{2}-\d{2}$' THEN raw_date::DATE
            WHEN raw_date ~ '^\d{4}/\d{2}/\d{2}$' THEN 
                TO_DATE(raw_date, 'YYYY/MM/DD')
            ELSE NULL
        END AS transaction_date,
        
        -- Convertir amount a DECIMAL, manejar valores vacíos
        CASE
            WHEN raw_amount ~ '^\d+\.?\d*$' THEN raw_amount::DECIMAL(12,2)
            ELSE NULL
        END AS amount,
        
        -- Limpiar descripción: trim y null si está vacío
        NULLIF(TRIM(raw_description), '') AS description
    FROM parsed_data
),

categorized_data AS (
    -- Categorizar transacciones basado en palabras clave en descripción
    SELECT
        raw_id,
        original_line,
        ingested_at,
        transaction_date,
        amount,
        description,
        
        -- Lógica de categorización por palabras clave
        CASE
            WHEN LOWER(description) LIKE '%supermercado%' 
                 OR LOWER(description) LIKE '%compra%' THEN 'groceries'
            WHEN LOWER(description) LIKE '%alquiler%' 
                 OR LOWER(description) LIKE '%renta%' THEN 'housing'
            WHEN LOWER(description) LIKE '%uber%' 
                 OR LOWER(description) LIKE '%taxi%' 
                 OR LOWER(description) LIKE '%transporte%' THEN 'transport'
            WHEN LOWER(description) LIKE '%restaurante%' 
                 OR LOWER(description) LIKE '%cena%' 
                 OR LOWER(description) LIKE '%comida%' THEN 'food'
            WHEN LOWER(description) LIKE '%transferencia%' 
                 OR LOWER(description) LIKE '%pago%' THEN 'transfer'
            WHEN LOWER(description) LIKE '%online%' 
                 OR LOWER(description) LIKE '%internet%' THEN 'online'
            WHEN LOWER(description) LIKE '%fraude%' 
                 OR LOWER(description) LIKE '%sospechosa%' THEN 'suspicious'
            ELSE 'other'
        END AS category,
        
        -- Detección de transacciones sospechosas
        -- Criterios: montos muy altos, palabras clave sospechosas
        CASE
            WHEN amount >= 2000.00 THEN TRUE
            WHEN LOWER(description) LIKE '%fraude%' THEN TRUE
            WHEN LOWER(description) LIKE '%sospechosa%' THEN TRUE
            WHEN LOWER(description) LIKE '%error%' THEN TRUE
            ELSE FALSE
        END AS is_suspicious
    FROM cleaned_data
    
    -- Filtrar registros con valores nulos en campos críticos
    -- Registros con fecha o monto nulo no son válidos
    WHERE transaction_date IS NOT NULL
      AND amount IS NOT NULL
      AND description IS NOT NULL
      AND amount > 0  -- Montos deben ser positivos
)

-- Selección final con columnas ordenadas y renombradas
SELECT
    ROW_NUMBER() OVER (ORDER BY transaction_date, amount) AS id,
    transaction_date,
    amount,
    description,
    category,
    is_suspicious,
    original_line,
    ingested_at,
    CURRENT_TIMESTAMP AS processed_at
FROM categorized_data

-- Ordenar por fecha de transacción y monto
ORDER BY transaction_date DESC, amount DESC
