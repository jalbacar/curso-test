/**
 * Barrel export para los servicios del frontend.
 * Permite importar todo desde 'services' en lugar de rutas individuales.
 * 
 * @example
 * ```typescript
 * import { fetchTransactions, ApiError } from './services';
 * import transactionService from './services';
 * ```
 */

export {
  fetchTransactions,
  fetchTransactionById,
  fetchSuspiciousTransactions,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  fetchTransactionStats,
  ApiError,
} from './transactionService';

export { default as transactionService } from './transactionService';
