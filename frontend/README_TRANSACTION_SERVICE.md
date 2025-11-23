# 🎯 Guía de Uso del Servicio de Transacciones

## 📦 Archivos Creados

```
frontend/src/
├── types/
│   └── Transaction.ts          # Interfaces y tipos TypeScript
├── services/
│   ├── index.ts               # Barrel export
│   └── transactionService.ts  # Funciones del servicio API
└── components/
    └── TransactionList.tsx    # Ejemplo de uso en React
```

---

## 🔧 Interfaz Transaction

```typescript
interface Transaction {
  id: number;
  transactionDate: string;  // Formato: "YYYY-MM-DD"
  amount: number;
  description: string;
  category: string;
  suspicious: boolean;
  createdAt?: string;
}
```

**Coincide exactamente con el JSON del backend Java EE.**

---

## 📡 Funciones Disponibles

### 1. **fetchTransactions()** - Obtener todas las transacciones

```typescript
import { fetchTransactions } from './services';

const transactions = await fetchTransactions();
// Returns: Transaction[]
```

### 2. **fetchTransactionById(id)** - Obtener una transacción específica

```typescript
import { fetchTransactionById } from './services';

const transaction = await fetchTransactionById(123);
// Returns: Transaction
```

### 3. **fetchSuspiciousTransactions()** - Transacciones sospechosas

```typescript
import { fetchSuspiciousTransactions } from './services';

const suspicious = await fetchSuspiciousTransactions();
// Returns: Transaction[]
```

### 4. **createTransaction(data)** - Crear nueva transacción

```typescript
import { createTransaction } from './services';

const newTransaction = {
  transactionDate: '2024-01-15',
  amount: 150.50,
  description: 'Compra en supermercado',
  category: 'groceries',
  suspicious: false
};

const created = await createTransaction(newTransaction);
// Returns: Transaction (con ID generado)
```

### 5. **updateTransaction(id, data)** - Actualizar transacción

```typescript
import { updateTransaction } from './services';

const updated = await updateTransaction(123, {
  ...existingTransaction,
  suspicious: true
});
// Returns: Transaction
```

### 6. **deleteTransaction(id)** - Eliminar transacción

```typescript
import { deleteTransaction } from './services';

await deleteTransaction(123);
// Returns: void
```

---

## ⚠️ Manejo de Errores

Todas las funciones lanzan `ApiError` en caso de error:

```typescript
import { fetchTransactions, ApiError } from './services';

try {
  const transactions = await fetchTransactions();
  console.log(transactions);
} catch (error) {
  if (error instanceof ApiError) {
    console.error(`Error ${error.status}: ${error.message}`);
    console.error('Status:', error.statusText);
    console.error('Data:', error.data);
  } else {
    console.error('Error de red:', error);
  }
}
```

### Tipos de errores comunes:

| Código | Significado |
|--------|-------------|
| `0` | Error de red (servidor no accesible) |
| `400` | Bad Request (datos inválidos) |
| `404` | Not Found (recurso no existe) |
| `500` | Internal Server Error |

---

## 🎨 Ejemplo de Uso en React Component

```typescript
import { useState, useEffect } from 'react';
import { fetchTransactions, ApiError } from './services';
import type { Transaction } from './types/Transaction';

function MyComponent() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const loadData = async () => {
      try {
        const data = await fetchTransactions();
        setTransactions(data);
      } catch (err) {
        if (err instanceof ApiError) {
          setError(err.message);
        }
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, []);

  if (loading) return <div>Cargando...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <ul>
      {transactions.map(t => (
        <li key={t.id}>
          {t.description} - ${t.amount}
          {t.suspicious && ' ⚠️'}
        </li>
      ))}
    </ul>
  );
}
```

**Ver `components/TransactionList.tsx` para un ejemplo completo con Tailwind CSS.**

---

## 🔗 Endpoints del Backend

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/transactions` | Listar todas |
| `GET` | `/api/transactions/{id}` | Obtener una |
| `GET` | `/api/transactions/suspicious` | Listar sospechosas |
| `POST` | `/api/transactions` | Crear nueva |
| `PUT` | `/api/transactions/{id}` | Actualizar |
| `DELETE` | `/api/transactions/{id}` | Eliminar |

---

## ⚙️ Configuración

Para cambiar la URL del backend, edita en `transactionService.ts`:

```typescript
const API_BASE_URL = 'http://localhost:8080/api';
```

Puedes usar variables de entorno:

```typescript
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api';
```

Y en `.env`:

```env
VITE_API_URL=http://localhost:8080/api
```

---

## 🧪 Testing

Ejemplo de test con Jest/Vitest:

```typescript
import { describe, it, expect, vi } from 'vitest';
import { fetchTransactions } from './services';

describe('transactionService', () => {
  it('should fetch transactions successfully', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => [
        { id: 1, amount: 100, description: 'Test' }
      ]
    });

    const transactions = await fetchTransactions();
    expect(transactions).toHaveLength(1);
    expect(transactions[0].id).toBe(1);
  });
});
```

---

## 📝 Tipos Adicionales

### NewTransaction - Para crear transacciones

```typescript
type NewTransaction = Omit<Transaction, 'id' | 'createdAt'>;
```

### UpdateTransaction - Para actualizaciones parciales

```typescript
type UpdateTransaction = Partial<Transaction> & { id: number };
```

### TransactionStats - Estadísticas

```typescript
interface TransactionStats {
  total: number;
  totalAmount: number;
  averageAmount: number;
  suspiciousCount: number;
}
```

---

## 🚀 Próximos Pasos

1. Implementa el componente `TransactionList` en tu aplicación
2. Añade formularios para crear/editar transacciones
3. Implementa filtros y búsqueda
4. Añade paginación si es necesario
5. Implementa caché con React Query o SWR

---

## 📚 Recursos

- **Backend URL**: http://localhost:8080/api/transactions
- **Componente ejemplo**: `src/components/TransactionList.tsx`
- **Tipos**: `src/types/Transaction.ts`
- **Servicio**: `src/services/transactionService.ts`
