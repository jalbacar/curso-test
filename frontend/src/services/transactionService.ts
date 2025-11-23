import type { Transaction, NewTransaction, TransactionStats } from '../types/Transaction';

/**
 * Configuración base del API.
 * Cambia esto si el backend está en otro puerto o dominio.
 */
const API_BASE_URL = 'http://localhost:8080/api';

/**
 * Clase de error personalizada para errores del API.
 */
export class ApiError extends Error {
  status: number;
  statusText: string;
  data?: any;

  constructor(
    message: string,
    status: number,
    statusText: string,
    data?: any
  ) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.statusText = statusText;
    this.data = data;
  }
}

/**
 * Función auxiliar para manejar respuestas HTTP y errores.
 * 
 * @param response - Respuesta de fetch
 * @returns Datos parseados como JSON
 * @throws {ApiError} Si la respuesta no es exitosa
 */
async function handleResponse<T>(response: Response): Promise<T> {
  // Si la respuesta no es OK (status 200-299)
  if (!response.ok) {
    let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
    let errorData;

    try {
      // Intentar parsear el cuerpo del error como JSON
      errorData = await response.json();
      errorMessage = errorData.message || errorMessage;
    } catch {
      // Si no es JSON, intentar como texto
      try {
        const text = await response.text();
        if (text) errorMessage = text;
      } catch {
        // Usar mensaje por defecto
      }
    }

    throw new ApiError(errorMessage, response.status, response.statusText, errorData);
  }

  // Parsear respuesta exitosa como JSON
  try {
    return await response.json();
  } catch (error) {
    throw new ApiError(
      'Error al parsear la respuesta JSON del servidor',
      response.status,
      response.statusText
    );
  }
}

/**
 * Obtiene todas las transacciones del backend.
 * 
 * Endpoint: GET /api/transactions
 * 
 * @returns Promise con array de transacciones
 * @throws {ApiError} Si hay error en la petición o respuesta
 * 
 * @example
 * ```typescript
 * try {
 *   const transactions = await fetchTransactions();
 *   console.log(`Total transacciones: ${transactions.length}`);
 * } catch (error) {
 *   if (error instanceof ApiError) {
 *     console.error(`Error ${error.status}: ${error.message}`);
 *   } else {
 *     console.error('Error de red:', error);
 *   }
 * }
 * ```
 */
export async function fetchTransactions(): Promise<Transaction[]> {
  try {
    const response = await fetch(`${API_BASE_URL}/transactions`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    return await handleResponse<Transaction[]>(response);
  } catch (error) {
    // Si es un error de red (no ApiError)
    if (!(error instanceof ApiError)) {
      throw new ApiError(
        'Error de conexión: No se pudo conectar con el servidor',
        0,
        'Network Error'
      );
    }
    throw error;
  }
}

/**
 * Obtiene una transacción específica por su ID.
 * 
 * Endpoint: GET /api/transactions/{id}
 * 
 * @param id - ID de la transacción
 * @returns Promise con la transacción encontrada
 * @throws {ApiError} Si hay error o la transacción no existe (404)
 * 
 * @example
 * ```typescript
 * const transaction = await fetchTransactionById(123);
 * console.log(transaction.description);
 * ```
 */
export async function fetchTransactionById(id: number): Promise<Transaction> {
  try {
    const response = await fetch(`${API_BASE_URL}/transactions/${id}`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    return await handleResponse<Transaction>(response);
  } catch (error) {
    if (!(error instanceof ApiError)) {
      throw new ApiError(
        'Error de conexión: No se pudo conectar con el servidor',
        0,
        'Network Error'
      );
    }
    throw error;
  }
}

/**
 * Obtiene todas las transacciones marcadas como sospechosas.
 * 
 * Endpoint: GET /api/transactions/suspicious
 * 
 * @returns Promise con array de transacciones sospechosas
 * @throws {ApiError} Si hay error en la petición o respuesta
 * 
 * @example
 * ```typescript
 * const suspicious = await fetchSuspiciousTransactions();
 * console.log(`Transacciones sospechosas: ${suspicious.length}`);
 * ```
 */
export async function fetchSuspiciousTransactions(): Promise<Transaction[]> {
  try {
    const response = await fetch(`${API_BASE_URL}/transactions/suspicious`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    return await handleResponse<Transaction[]>(response);
  } catch (error) {
    if (!(error instanceof ApiError)) {
      throw new ApiError(
        'Error de conexión: No se pudo conectar con el servidor',
        0,
        'Network Error'
      );
    }
    throw error;
  }
}

/**
 * Crea una nueva transacción.
 * 
 * Endpoint: POST /api/transactions
 * 
 * @param transaction - Datos de la nueva transacción (sin ID)
 * @returns Promise con la transacción creada (incluye ID generado)
 * @throws {ApiError} Si hay error en la validación o creación
 * 
 * @example
 * ```typescript
 * const newTransaction: NewTransaction = {
 *   transactionDate: '2024-01-15',
 *   amount: 150.50,
 *   description: 'Compra en supermercado',
 *   category: 'groceries',
 *   suspicious: false
 * };
 * 
 * const created = await createTransaction(newTransaction);
 * console.log(`Transacción creada con ID: ${created.id}`);
 * ```
 */
export async function createTransaction(transaction: NewTransaction): Promise<Transaction> {
  try {
    const response = await fetch(`${API_BASE_URL}/transactions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(transaction),
    });

    return await handleResponse<Transaction>(response);
  } catch (error) {
    if (!(error instanceof ApiError)) {
      throw new ApiError(
        'Error de conexión: No se pudo conectar con el servidor',
        0,
        'Network Error'
      );
    }
    throw error;
  }
}

/**
 * Actualiza una transacción existente.
 * 
 * Endpoint: PUT /api/transactions/{id}
 * 
 * @param id - ID de la transacción a actualizar
 * @param transaction - Datos actualizados de la transacción
 * @returns Promise con la transacción actualizada
 * @throws {ApiError} Si hay error o la transacción no existe
 * 
 * @example
 * ```typescript
 * const updated = await updateTransaction(123, {
 *   ...existingTransaction,
 *   suspicious: true
 * });
 * ```
 */
export async function updateTransaction(id: number, transaction: Transaction): Promise<Transaction> {
  try {
    const response = await fetch(`${API_BASE_URL}/transactions/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(transaction),
    });

    return await handleResponse<Transaction>(response);
  } catch (error) {
    if (!(error instanceof ApiError)) {
      throw new ApiError(
        'Error de conexión: No se pudo conectar con el servidor',
        0,
        'Network Error'
      );
    }
    throw error;
  }
}

/**
 * Elimina una transacción.
 * 
 * Endpoint: DELETE /api/transactions/{id}
 * 
 * @param id - ID de la transacción a eliminar
 * @returns Promise que se resuelve cuando la eliminación es exitosa
 * @throws {ApiError} Si hay error o la transacción no existe
 * 
 * @example
 * ```typescript
 * await deleteTransaction(123);
 * console.log('Transacción eliminada');
 * ```
 */
export async function deleteTransaction(id: number): Promise<void> {
  try {
    const response = await fetch(`${API_BASE_URL}/transactions/${id}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
      },
    });

    // Para DELETE, puede que no haya cuerpo de respuesta
    if (!response.ok) {
      await handleResponse(response); // Esto lanzará el error apropiado
    }
  } catch (error) {
    if (!(error instanceof ApiError)) {
      throw new ApiError(
        'Error de conexión: No se pudo conectar con el servidor',
        0,
        'Network Error'
      );
    }
    throw error;
  }
}

/**
 * Obtiene estadísticas agregadas de las transacciones.
 * 
 * Nota: Este endpoint podría no estar implementado en el backend todavía.
 * Es un ejemplo de cómo añadir nuevos endpoints.
 * 
 * @returns Promise con estadísticas de transacciones
 * @throws {ApiError} Si hay error en la petición
 */
export async function fetchTransactionStats(): Promise<TransactionStats> {
  try {
    const response = await fetch(`${API_BASE_URL}/transactions/stats`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    return await handleResponse<TransactionStats>(response);
  } catch (error) {
    if (!(error instanceof ApiError)) {
      throw new ApiError(
        'Error de conexión: No se pudo conectar con el servidor',
        0,
        'Network Error'
      );
    }
    throw error;
  }
}

/**
 * Exportación por defecto de todas las funciones del servicio.
 */
export default {
  fetchTransactions,
  fetchTransactionById,
  fetchSuspiciousTransactions,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  fetchTransactionStats,
};
