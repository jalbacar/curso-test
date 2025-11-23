import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import TransactionList from '../TransactionList';
import * as transactionService from '../../services/transactionService';
import type { Transaction } from '../../types/Transaction';

// Mock del servicio de transacciones
vi.mock('../../services/transactionService', () => ({
  fetchTransactions: vi.fn(),
  ApiError: class ApiError extends Error {
    constructor(
      message: string,
      public status: number,
      public statusText: string,
      public data?: unknown
    ) {
      super(message);
      this.name = 'ApiError';
    }
  },
}));

describe('TransactionList', () => {
  // Datos de prueba
  const mockTransactions: Transaction[] = [
    {
      id: 1,
      transactionDate: '2024-01-15',
      amount: 100.50,
      description: 'Supermercado',
      category: 'Alimentación',
      suspicious: false,
      createdAt: '2024-01-15T10:30:00',
    },
    {
      id: 2,
      transactionDate: '2024-01-16',
      amount: 5000.00,
      description: 'Transferencia sospechosa',
      category: 'Transferencia',
      suspicious: true,
      createdAt: '2024-01-16T14:20:00',
    },
    {
      id: 3,
      transactionDate: '2024-01-17',
      amount: 75.30,
      description: 'Gasolina',
      category: 'Transporte',
      suspicious: false,
      createdAt: '2024-01-17T08:15:00',
    },
  ];

  beforeEach(() => {
    // Limpiar todos los mocks antes de cada test
    vi.clearAllMocks();
  });

  describe('Renderizado con datos', () => {
    it('debería renderizar la tabla correctamente con datos simulados', async () => {
      // Arrange: Mock del servicio retornando datos
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue(mockTransactions);

      // Act: Renderizar el componente
      render(<TransactionList />);

      // Assert: Verificar que se muestra el estado de carga inicialmente
      expect(screen.getByText('Cargando transacciones...')).toBeInTheDocument();

      // Assert: Esperar a que se carguen los datos
      await waitFor(() => {
        expect(screen.getByText('Transacciones')).toBeInTheDocument();
      });

      // Assert: Verificar que la tabla está presente
      expect(screen.getByRole('table')).toBeInTheDocument();

      // Assert: Verificar los encabezados de la tabla
      expect(screen.getByText('ID')).toBeInTheDocument();
      expect(screen.getByText('Fecha')).toBeInTheDocument();
      expect(screen.getByText('Descripción')).toBeInTheDocument();
      expect(screen.getByText('Categoría')).toBeInTheDocument();
      expect(screen.getByText('Monto')).toBeInTheDocument();
      expect(screen.getByText('Estado')).toBeInTheDocument();

      // Assert: Verificar que se muestran todas las transacciones
      expect(screen.getByText('Supermercado')).toBeInTheDocument();
      expect(screen.getByText('Transferencia sospechosa')).toBeInTheDocument();
      expect(screen.getByText('Gasolina')).toBeInTheDocument();

      // Assert: Verificar que se muestran los montos correctamente
      expect(screen.getByText('$100.50')).toBeInTheDocument();
      expect(screen.getByText('$5000.00')).toBeInTheDocument();
      expect(screen.getByText('$75.30')).toBeInTheDocument();

      // Assert: Verificar el contador de transacciones
      expect(screen.getByText('Total de transacciones: 3')).toBeInTheDocument();
    });

    it('debería mostrar todas las columnas de datos correctamente', async () => {
      // Arrange
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue([mockTransactions[0]]);

      // Act
      render(<TransactionList />);

      // Assert
      await waitFor(() => {
        // Verificar ID
        expect(screen.getByText('1')).toBeInTheDocument();
        
        // Verificar descripción
        expect(screen.getByText('Supermercado')).toBeInTheDocument();
        
        // Verificar categoría
        expect(screen.getByText('Alimentación')).toBeInTheDocument();
        
        // Verificar monto
        expect(screen.getByText('$100.50')).toBeInTheDocument();
        
        // Verificar estado normal
        expect(screen.getByText('Normal')).toBeInTheDocument();
      });
    });
  });

  describe('Transacciones sospechosas', () => {
    it('debería aplicar clase CSS de color rojo a transacciones sospechosas', async () => {
      // Arrange
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue(mockTransactions);

      // Act
      render(<TransactionList />);

      // Assert: Esperar a que se carguen los datos
      await waitFor(() => {
        expect(screen.getByText('Transacciones')).toBeInTheDocument();
      });

      // Assert: Verificar que las transacciones sospechosas tienen el badge rojo
      const suspiciousBadges = screen.getAllByText('Sospechosa');
      expect(suspiciousBadges).toHaveLength(1);
      
      // Verificar que el badge tiene las clases CSS correctas (bg-red-100, text-red-800)
      const suspiciousBadge = suspiciousBadges[0];
      expect(suspiciousBadge).toHaveClass('bg-red-100');
      expect(suspiciousBadge).toHaveClass('text-red-800');
    });

    it('debería aplicar clase CSS de color verde a transacciones normales', async () => {
      // Arrange
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue(mockTransactions);

      // Act
      render(<TransactionList />);

      // Assert
      await waitFor(() => {
        expect(screen.getByText('Transacciones')).toBeInTheDocument();
      });

      // Assert: Verificar que las transacciones normales tienen el badge verde
      const normalBadges = screen.getAllByText('Normal');
      expect(normalBadges).toHaveLength(2);
      
      // Verificar que todos los badges normales tienen las clases CSS correctas
      normalBadges.forEach(badge => {
        expect(badge).toHaveClass('bg-green-100');
        expect(badge).toHaveClass('text-green-800');
      });
    });

    it('debería distinguir visualmente entre transacciones sospechosas y normales', async () => {
      // Arrange
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue(mockTransactions);

      // Act
      render(<TransactionList />);

      // Assert
      await waitFor(() => {
        expect(screen.getByText('Transacciones')).toBeInTheDocument();
      });

      // Assert: Verificar que hay exactamente 1 transacción sospechosa
      const suspiciousBadges = screen.getAllByText('Sospechosa');
      expect(suspiciousBadges).toHaveLength(1);

      // Assert: Verificar que hay exactamente 2 transacciones normales
      const normalBadges = screen.getAllByText('Normal');
      expect(normalBadges).toHaveLength(2);
    });
  });

  describe('Estado vacío', () => {
    it('debería mostrar mensaje "No hay transacciones disponibles" si la lista está vacía', async () => {
      // Arrange: Mock del servicio retornando array vacío
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue([]);

      // Act
      render(<TransactionList />);

      // Assert: Esperar a que se carguen los datos
      await waitFor(() => {
        expect(screen.getByText('No hay transacciones disponibles')).toBeInTheDocument();
      });

      // Assert: Verificar que NO se muestra la tabla
      expect(screen.queryByRole('table')).not.toBeInTheDocument();

      // Assert: Verificar que NO se muestra el título
      expect(screen.queryByText('Transacciones')).not.toBeInTheDocument();
    });

    it('debería mostrar el mensaje de vacío en lugar del estado de carga', async () => {
      // Arrange
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue([]);

      // Act
      render(<TransactionList />);

      // Assert: Inicialmente debe mostrar "Cargando..."
      expect(screen.getByText('Cargando transacciones...')).toBeInTheDocument();

      // Assert: Después debe mostrar el mensaje de vacío
      await waitFor(() => {
        expect(screen.getByText('No hay transacciones disponibles')).toBeInTheDocument();
      });

      // Assert: No debe mostrar más el mensaje de carga
      expect(screen.queryByText('Cargando transacciones...')).not.toBeInTheDocument();
    });
  });

  describe('Estado de carga', () => {
    it('debería mostrar el indicador de carga inicialmente', () => {
      // Arrange: Mock que nunca se resuelve para mantener el estado de carga
      vi.mocked(transactionService.fetchTransactions).mockImplementation(
        () => new Promise(() => {}) // Promise que nunca se resuelve
      );

      // Act
      render(<TransactionList />);

      // Assert
      expect(screen.getByText('Cargando transacciones...')).toBeInTheDocument();
      expect(screen.queryByRole('table')).not.toBeInTheDocument();
    });
  });

  describe('Manejo de errores', () => {
    it('debería mostrar mensaje de error cuando falla la petición', async () => {
      // Arrange: Mock del servicio lanzando ApiError
      const apiError = new transactionService.ApiError(
        'Internal Server Error',
        500,
        'Internal Server Error'
      );
      vi.mocked(transactionService.fetchTransactions).mockRejectedValue(apiError);

      // Act
      render(<TransactionList />);

      // Assert: Esperar a que se muestre el error
      await waitFor(() => {
        expect(screen.getByText(/Error 500:/)).toBeInTheDocument();
      });

      // Assert: Verificar que NO se muestra la tabla
      expect(screen.queryByRole('table')).not.toBeInTheDocument();

      // Assert: Verificar el estilo del error (clase de Tailwind)
      const errorElement = screen.getByText(/Error 500:/).parentElement;
      expect(errorElement).toHaveClass('text-red-700');
    });

    it('debería mostrar error genérico para errores no esperados', async () => {
      // Arrange: Mock lanzando error genérico
      vi.mocked(transactionService.fetchTransactions).mockRejectedValue(
        new Error('Network error')
      );

      // Act
      render(<TransactionList />);

      // Assert
      await waitFor(() => {
        expect(screen.getByText('Error inesperado al cargar las transacciones')).toBeInTheDocument();
      });
    });
  });

  describe('Formato de datos', () => {
    it('debería formatear las fechas correctamente', async () => {
      // Arrange
      const transactionWithDate: Transaction = {
        id: 1,
        transactionDate: '2024-01-15',
        amount: 100.00,
        description: 'Test',
        category: 'Test',
        suspicious: false,
        createdAt: '2024-01-15T10:00:00',
      };
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue([transactionWithDate]);

      // Act
      render(<TransactionList />);

      // Assert
      await waitFor(() => {
        // Verificar que la fecha se formatea (el formato exacto depende del locale)
        const dateElement = screen.getByText(/1\/15\/2024|15\/1\/2024/);
        expect(dateElement).toBeInTheDocument();
      });
    });

    it('debería formatear los montos con 2 decimales', async () => {
      // Arrange
      const transactionWithAmount: Transaction = {
        id: 1,
        transactionDate: '2024-01-15',
        amount: 1234.5, // Solo 1 decimal
        description: 'Test',
        category: 'Test',
        suspicious: false,
        createdAt: '2024-01-15T10:00:00',
      };
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue([transactionWithAmount]);

      // Act
      render(<TransactionList />);

      // Assert
      await waitFor(() => {
        // Debe mostrar 2 decimales: $1234.50
        expect(screen.getByText('$1234.50')).toBeInTheDocument();
      });
    });
  });

  describe('Categorías', () => {
    it('debería mostrar las categorías con badge azul', async () => {
      // Arrange
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue([mockTransactions[0]]);

      // Act
      render(<TransactionList />);

      // Assert
      await waitFor(() => {
        const categoryBadge = screen.getByText('Alimentación');
        expect(categoryBadge).toHaveClass('bg-blue-100');
        expect(categoryBadge).toHaveClass('text-blue-800');
      });
    });
  });

  describe('Interacciones del servicio', () => {
    it('debería llamar al servicio fetchTransactions al montar el componente', async () => {
      // Arrange
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue(mockTransactions);

      // Act
      render(<TransactionList />);

      // Assert
      await waitFor(() => {
        expect(transactionService.fetchTransactions).toHaveBeenCalledTimes(1);
      });
    });

    it('debería llamar al servicio solo una vez al montar', async () => {
      // Arrange
      vi.mocked(transactionService.fetchTransactions).mockResolvedValue(mockTransactions);

      // Act
      render(<TransactionList />);

      // Assert
      await waitFor(() => {
        expect(screen.getByText('Transacciones')).toBeInTheDocument();
      });

      // Verificar que solo se llamó una vez
      expect(transactionService.fetchTransactions).toHaveBeenCalledTimes(1);
    });
  });
});
