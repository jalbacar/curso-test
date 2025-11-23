/**
 * Interfaz TypeScript que representa una transacción financiera.
 * 
 * Esta interfaz coincide exactamente con el JSON devuelto por el backend Java EE.
 * Endpoint: http://localhost:8080/api/transactions
 * 
 * Esquema de la tabla fact_transactions:
 * - id: SERIAL PRIMARY KEY
 * - transactiondate: DATE NOT NULL
 * - amount: DECIMAL(12,2) NOT NULL
 * - description: TEXT NOT NULL
 * - category: VARCHAR(100) NOT NULL
 * - issuspicious: BOOLEAN NOT NULL DEFAULT FALSE
 * - createdat: TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
 */
export interface Transaction {
  /**
   * Identificador único de la transacción (autoincremental).
   */
  id: number;

  /**
   * Fecha de la transacción.
   * Formato esperado del backend: "YYYY-MM-DD"
   * Ejemplo: "2024-01-15"
   */
  transactionDate: string;

  /**
   * Monto de la transacción en formato decimal.
   * Rango típico: 0.01 - 50,000.00
   */
  amount: number;

  /**
   * Descripción textual de la transacción.
   * Incluye detalles del comercio, producto o servicio.
   */
  description: string;

  /**
   * Categoría de la transacción para clasificación.
   * Valores posibles: 'groceries', 'housing', 'transport', 'food', 
   * 'transfer', 'online', 'suspicious', 'other'
   */
  category: string;

  /**
   * Indicador de transacción sospechosa.
   * true: requiere revisión manual
   * false: transacción normal
   * 
   * Nota: En el backend Java el campo se llama "issuspicious" pero
   * el getter/setter sigue la convención "isSuspicious/setSuspicious"
   * y el JSON se serializa como "suspicious"
   */
  suspicious: boolean;

  /**
   * Timestamp de creación del registro (opcional, puede no venir del backend).
   * Formato ISO 8601: "2024-01-15T10:30:00"
   */
  createdAt?: string;
}

/**
 * Tipo para crear una nueva transacción (sin ID ni createdAt).
 * Usado en formularios de creación.
 */
export type NewTransaction = Omit<Transaction, 'id' | 'createdAt'>;

/**
 * Tipo para actualizar una transacción existente.
 * Todos los campos son opcionales excepto el ID.
 */
export type UpdateTransaction = Partial<Transaction> & { id: number };

/**
 * Estadísticas de transacciones agregadas.
 */
export interface TransactionStats {
  total: number;
  totalAmount: number;
  averageAmount: number;
  suspiciousCount: number;
  categoryBreakdown: {
    category: string;
    count: number;
    totalAmount: number;
  }[];
}

/**
 * Respuesta paginada de transacciones (para implementaciones futuras).
 */
export interface TransactionPage {
  content: Transaction[];
  totalElements: number;
  totalPages: number;
  page: number;
  size: number;
}
