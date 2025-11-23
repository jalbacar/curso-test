package com.pac.repository;

import com.pac.entity.Transaction;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import javax.persistence.EntityManager;
import javax.persistence.TypedQuery;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Test unitarios para TransactionRepository usando JUnit 5 y Mockito.
 * 
 * Estos tests verifican la lógica de negocio del repositorio mockeando
 * el EntityManager para aislar las pruebas de la base de datos.
 * 
 * @author Sistema PAC
 * @version 1.0.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("TransactionRepository Unit Tests")
class TransactionRepositoryTest {
    
    @Mock
    private EntityManager entityManager;
    
    @Mock
    private TypedQuery<Transaction> typedQuery;
    
    @Mock
    private TypedQuery<Long> longQuery;
    
    @Mock
    private TypedQuery<BigDecimal> bigDecimalQuery;
    
    @Mock
    private TypedQuery<Object[]> objectArrayQuery;
    
    @InjectMocks
    private TransactionRepository repository;
    
    private Transaction testTransaction;
    private List<Transaction> testTransactionList;
    
    /**
     * Configuración inicial antes de cada test.
     * Crea datos de prueba reutilizables.
     */
    @BeforeEach
    void setUp() {
        testTransaction = new Transaction(
            LocalDate.of(2024, 1, 15),
            new BigDecimal("100.00"),
            "Test transaction",
            "groceries"
        );
        testTransaction.setId(1L);
        testTransaction.setSuspicious(false);
        
        testTransactionList = new ArrayList<>();
        testTransactionList.add(testTransaction);
    }
    
    // ========================================================================
    // TESTS: CRUD BÁSICO
    // ========================================================================
    
    @Test
    @DisplayName("create() - Debería persistir una transacción válida")
    void testCreate_ValidTransaction_ShouldPersist() {
        // Given
        Transaction newTransaction = new Transaction(
            LocalDate.of(2024, 1, 20),
            new BigDecimal("250.00"),
            "New test transaction",
            "transport"
        );
        
        // When
        Transaction result = repository.create(newTransaction);
        
        // Then
        verify(entityManager).persist(newTransaction);
        verify(entityManager).flush();
        assertEquals(newTransaction, result);
    }
    
    @Test
    @DisplayName("create() - Debería lanzar excepción con transacción null")
    void testCreate_NullTransaction_ShouldThrowException() {
        // When & Then
        assertThrows(IllegalArgumentException.class, () -> {
            repository.create(null);
        });
        
        verify(entityManager, never()).persist(any());
    }
    
    @Test
    @DisplayName("create() - Debería lanzar excepción con transacción inválida")
    void testCreate_InvalidTransaction_ShouldThrowException() {
        // Given
        Transaction invalidTransaction = new Transaction();
        // transacción sin datos obligatorios
        
        // When & Then
        assertThrows(IllegalArgumentException.class, () -> {
            repository.create(invalidTransaction);
        });
        
        verify(entityManager, never()).persist(any());
    }
    
    @Test
    @DisplayName("findById() - Debería retornar transacción cuando existe")
    void testFindById_ExistingId_ShouldReturnTransaction() {
        // Given
        Long id = 1L;
        when(entityManager.find(Transaction.class, id)).thenReturn(testTransaction);
        
        // When
        Optional<Transaction> result = repository.findById(id);
        
        // Then
        assertTrue(result.isPresent());
        assertEquals(testTransaction, result.get());
        verify(entityManager).find(Transaction.class, id);
    }
    
    @Test
    @DisplayName("findById() - Debería retornar Optional.empty() cuando no existe")
    void testFindById_NonExistingId_ShouldReturnEmpty() {
        // Given
        Long id = 999L;
        when(entityManager.find(Transaction.class, id)).thenReturn(null);
        
        // When
        Optional<Transaction> result = repository.findById(id);
        
        // Then
        assertFalse(result.isPresent());
        verify(entityManager).find(Transaction.class, id);
    }
    
    @Test
    @DisplayName("findById() - Debería retornar Optional.empty() con ID null")
    void testFindById_NullId_ShouldReturnEmpty() {
        // When
        Optional<Transaction> result = repository.findById(null);
        
        // Then
        assertFalse(result.isPresent());
        verify(entityManager, never()).find(any(), any());
    }
    
    @Test
    @DisplayName("findAll() - Debería retornar lista de transacciones")
    void testFindAll_ShouldReturnTransactionList() {
        // Given
        String expectedJpql = "SELECT t FROM Transaction t ORDER BY t.transactionDate DESC, t.amount DESC";
        when(entityManager.createQuery(expectedJpql, Transaction.class)).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(testTransactionList);
        
        // When
        List<Transaction> result = repository.findAll();
        
        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(testTransaction, result.get(0));
        verify(entityManager).createQuery(expectedJpql, Transaction.class);
        verify(typedQuery).getResultList();
    }
    
    @Test
    @DisplayName("update() - Debería actualizar transacción existente")
    void testUpdate_ValidTransaction_ShouldUpdate() {
        // Given
        testTransaction.setDescription("Updated description");
        when(entityManager.merge(testTransaction)).thenReturn(testTransaction);
        
        // When
        Transaction result = repository.update(testTransaction);
        
        // Then
        assertEquals(testTransaction, result);
        verify(entityManager).merge(testTransaction);
    }
    
    @Test
    @DisplayName("update() - Debería lanzar excepción con transacción null")
    void testUpdate_NullTransaction_ShouldThrowException() {
        // When & Then
        assertThrows(IllegalArgumentException.class, () -> {
            repository.update(null);
        });
        
        verify(entityManager, never()).merge(any());
    }
    
    @Test
    @DisplayName("delete() - Debería eliminar transacción existente")
    void testDelete_ExistingId_ShouldReturnTrue() {
        // Given
        Long id = 1L;
        when(entityManager.find(Transaction.class, id)).thenReturn(testTransaction);
        
        // When
        boolean result = repository.delete(id);
        
        // Then
        assertTrue(result);
        verify(entityManager).find(Transaction.class, id);
        verify(entityManager).remove(testTransaction);
    }
    
    @Test
    @DisplayName("delete() - Debería retornar false cuando no existe")
    void testDelete_NonExistingId_ShouldReturnFalse() {
        // Given
        Long id = 999L;
        when(entityManager.find(Transaction.class, id)).thenReturn(null);
        
        // When
        boolean result = repository.delete(id);
        
        // Then
        assertFalse(result);
        verify(entityManager).find(Transaction.class, id);
        verify(entityManager, never()).remove(any());
    }
    
    // ========================================================================
    // TESTS: CONSULTAS ESPECIALIZADAS
    // ========================================================================
    
    @Test
    @DisplayName("findSuspicious() - Debería llamar a createQuery con parámetros correctos")
    void testFindSuspicious_ShouldCallCreateQueryWithCorrectParameters() {
        // Given
        String expectedJpql = "SELECT t FROM Transaction t WHERE t.suspicious = true " +
                             "ORDER BY t.transactionDate DESC, t.amount DESC";
        
        Transaction suspiciousTransaction = new Transaction(
            LocalDate.of(2024, 1, 20),
            new BigDecimal("5000.00"),
            "Suspicious transaction",
            "suspicious"
        );
        suspiciousTransaction.setId(2L);
        suspiciousTransaction.setSuspicious(true);
        
        List<Transaction> suspiciousList = List.of(suspiciousTransaction);
        
        when(entityManager.createQuery(expectedJpql, Transaction.class)).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(suspiciousList);
        
        // When
        List<Transaction> result = repository.findSuspicious();
        
        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertTrue(result.get(0).isSuspicious());
        verify(entityManager).createQuery(expectedJpql, Transaction.class);
        verify(typedQuery).getResultList();
    }
    
    @Test
    @DisplayName("findSuspicious() - Debería manejar lista vacía correctamente")
    void testFindSuspicious_EmptyList_ShouldReturnEmptyList() {
        // Given
        String expectedJpql = "SELECT t FROM Transaction t WHERE t.suspicious = true " +
                             "ORDER BY t.transactionDate DESC, t.amount DESC";
        
        List<Transaction> emptyList = new ArrayList<>();
        
        when(entityManager.createQuery(expectedJpql, Transaction.class)).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(emptyList);
        
        // When
        List<Transaction> result = repository.findSuspicious();
        
        // Then
        assertNotNull(result);
        assertTrue(result.isEmpty());
        assertEquals(0, result.size());
        verify(entityManager).createQuery(expectedJpql, Transaction.class);
        verify(typedQuery).getResultList();
    }
    
    @Test
    @DisplayName("findByCategory() - Debería retornar transacciones de la categoría")
    void testFindByCategory_ValidCategory_ShouldReturnTransactions() {
        // Given
        String category = "groceries";
        String expectedJpql = "SELECT t FROM Transaction t WHERE t.category = :category " +
                             "ORDER BY t.transactionDate DESC";
        
        when(entityManager.createQuery(expectedJpql, Transaction.class)).thenReturn(typedQuery);
        when(typedQuery.setParameter("category", category)).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(testTransactionList);
        
        // When
        List<Transaction> result = repository.findByCategory(category);
        
        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        verify(entityManager).createQuery(expectedJpql, Transaction.class);
        verify(typedQuery).setParameter("category", category);
        verify(typedQuery).getResultList();
    }
    
    @Test
    @DisplayName("findByCategory() - Debería retornar lista vacía con categoría null")
    void testFindByCategory_NullCategory_ShouldReturnEmptyList() {
        // When
        List<Transaction> result = repository.findByCategory(null);
        
        // Then
        assertNotNull(result);
        assertTrue(result.isEmpty());
        verify(entityManager, never()).createQuery(anyString(), eq(Transaction.class));
    }
    
    @Test
    @DisplayName("findByCategory() - Debería retornar lista vacía con categoría vacía")
    void testFindByCategory_EmptyCategory_ShouldReturnEmptyList() {
        // When
        List<Transaction> result = repository.findByCategory("   ");
        
        // Then
        assertNotNull(result);
        assertTrue(result.isEmpty());
        verify(entityManager, never()).createQuery(anyString(), eq(Transaction.class));
    }
    
    @Test
    @DisplayName("findByDateRange() - Debería retornar transacciones en el rango")
    void testFindByDateRange_ValidRange_ShouldReturnTransactions() {
        // Given
        LocalDate startDate = LocalDate.of(2024, 1, 1);
        LocalDate endDate = LocalDate.of(2024, 1, 31);
        String expectedJpql = "SELECT t FROM Transaction t " +
                             "WHERE t.transactionDate BETWEEN :startDate AND :endDate " +
                             "ORDER BY t.transactionDate DESC";
        
        when(entityManager.createQuery(expectedJpql, Transaction.class)).thenReturn(typedQuery);
        when(typedQuery.setParameter("startDate", startDate)).thenReturn(typedQuery);
        when(typedQuery.setParameter("endDate", endDate)).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(testTransactionList);
        
        // When
        List<Transaction> result = repository.findByDateRange(startDate, endDate);
        
        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        verify(entityManager).createQuery(expectedJpql, Transaction.class);
        verify(typedQuery).setParameter("startDate", startDate);
        verify(typedQuery).setParameter("endDate", endDate);
        verify(typedQuery).getResultList();
    }
    
    @Test
    @DisplayName("findByDateRange() - Debería lanzar excepción con fechas null")
    void testFindByDateRange_NullDates_ShouldThrowException() {
        // When & Then
        assertThrows(IllegalArgumentException.class, () -> {
            repository.findByDateRange(null, LocalDate.now());
        });
        
        assertThrows(IllegalArgumentException.class, () -> {
            repository.findByDateRange(LocalDate.now(), null);
        });
        
        verify(entityManager, never()).createQuery(anyString(), eq(Transaction.class));
    }
    
    @Test
    @DisplayName("findByMinAmount() - Debería retornar transacciones >= monto mínimo")
    void testFindByMinAmount_ValidAmount_ShouldReturnTransactions() {
        // Given
        BigDecimal minAmount = new BigDecimal("50.00");
        String expectedJpql = "SELECT t FROM Transaction t " +
                             "WHERE t.amount >= :minAmount " +
                             "ORDER BY t.amount DESC";
        
        when(entityManager.createQuery(expectedJpql, Transaction.class)).thenReturn(typedQuery);
        when(typedQuery.setParameter("minAmount", minAmount)).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(testTransactionList);
        
        // When
        List<Transaction> result = repository.findByMinAmount(minAmount);
        
        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        verify(entityManager).createQuery(expectedJpql, Transaction.class);
        verify(typedQuery).setParameter("minAmount", minAmount);
        verify(typedQuery).getResultList();
    }
    
    @Test
    @DisplayName("findByMinAmount() - Debería lanzar excepción con monto null")
    void testFindByMinAmount_NullAmount_ShouldThrowException() {
        // When & Then
        assertThrows(IllegalArgumentException.class, () -> {
            repository.findByMinAmount(null);
        });
        
        verify(entityManager, never()).createQuery(anyString(), eq(Transaction.class));
    }
    
    @Test
    @DisplayName("findHighValue() - Debería retornar transacciones >= 2000")
    void testFindHighValue_ShouldReturnHighValueTransactions() {
        // Given
        BigDecimal highValueThreshold = new BigDecimal("2000.00");
        Transaction highValueTransaction = new Transaction(
            LocalDate.of(2024, 1, 20),
            new BigDecimal("3500.00"),
            "High value transaction",
            "transfer"
        );
        List<Transaction> highValueList = List.of(highValueTransaction);
        
        String expectedJpql = "SELECT t FROM Transaction t " +
                             "WHERE t.amount >= :minAmount " +
                             "ORDER BY t.amount DESC";
        
        when(entityManager.createQuery(expectedJpql, Transaction.class)).thenReturn(typedQuery);
        when(typedQuery.setParameter("minAmount", highValueThreshold)).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(highValueList);
        
        // When
        List<Transaction> result = repository.findHighValue();
        
        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        verify(typedQuery).setParameter("minAmount", highValueThreshold);
    }
    
    // ========================================================================
    // TESTS: AGREGACIONES Y ESTADÍSTICAS
    // ========================================================================
    
    @Test
    @DisplayName("count() - Debería retornar el total de transacciones")
    void testCount_ShouldReturnTotalCount() {
        // Given
        Long expectedCount = 10L;
        String expectedJpql = "SELECT COUNT(t) FROM Transaction t";
        
        when(entityManager.createQuery(expectedJpql, Long.class)).thenReturn(longQuery);
        when(longQuery.getSingleResult()).thenReturn(expectedCount);
        
        // When
        Long result = repository.count();
        
        // Then
        assertEquals(expectedCount, result);
        verify(entityManager).createQuery(expectedJpql, Long.class);
        verify(longQuery).getSingleResult();
    }
    
    @Test
    @DisplayName("countSuspicious() - Debería retornar el conteo de sospechosas")
    void testCountSuspicious_ShouldReturnSuspiciousCount() {
        // Given
        Long expectedCount = 3L;
        String expectedJpql = "SELECT COUNT(t) FROM Transaction t WHERE t.suspicious = true";
        
        when(entityManager.createQuery(expectedJpql, Long.class)).thenReturn(longQuery);
        when(longQuery.getSingleResult()).thenReturn(expectedCount);
        
        // When
        Long result = repository.countSuspicious();
        
        // Then
        assertEquals(expectedCount, result);
        verify(entityManager).createQuery(expectedJpql, Long.class);
        verify(longQuery).getSingleResult();
    }
    
    @Test
    @DisplayName("sumTotal() - Debería retornar la suma total")
    void testSumTotal_ShouldReturnTotalSum() {
        // Given
        BigDecimal expectedSum = new BigDecimal("1500.50");
        String expectedJpql = "SELECT COALESCE(SUM(t.amount), 0) FROM Transaction t";
        
        when(entityManager.createQuery(expectedJpql, BigDecimal.class)).thenReturn(bigDecimalQuery);
        when(bigDecimalQuery.getSingleResult()).thenReturn(expectedSum);
        
        // When
        BigDecimal result = repository.sumTotal();
        
        // Then
        assertEquals(expectedSum, result);
        verify(entityManager).createQuery(expectedJpql, BigDecimal.class);
        verify(bigDecimalQuery).getSingleResult();
    }
    
    @Test
    @DisplayName("average() - Debería retornar el promedio")
    void testAverage_ShouldReturnAverage() {
        // Given
        BigDecimal expectedAvg = new BigDecimal("150.05");
        String expectedJpql = "SELECT COALESCE(AVG(t.amount), 0) FROM Transaction t";
        
        when(entityManager.createQuery(expectedJpql, BigDecimal.class)).thenReturn(bigDecimalQuery);
        when(bigDecimalQuery.getSingleResult()).thenReturn(expectedAvg);
        
        // When
        BigDecimal result = repository.average();
        
        // Then
        assertEquals(expectedAvg, result);
        verify(entityManager).createQuery(expectedJpql, BigDecimal.class);
        verify(bigDecimalQuery).getSingleResult();
    }
    
    @Test
    @DisplayName("countByCategory() - Debería retornar conteo agrupado")
    void testCountByCategory_ShouldReturnGroupedCount() {
        // Given
        String expectedJpql = "SELECT t.category, COUNT(t) FROM Transaction t " +
                             "GROUP BY t.category " +
                             "ORDER BY COUNT(t) DESC";
        List<Object[]> expectedResult = List.of(
            new Object[]{"groceries", 5L},
            new Object[]{"transport", 3L}
        );
        
        when(entityManager.createQuery(expectedJpql, Object[].class)).thenReturn(objectArrayQuery);
        when(objectArrayQuery.getResultList()).thenReturn(expectedResult);
        
        // When
        List<Object[]> result = repository.countByCategory();
        
        // Then
        assertNotNull(result);
        assertEquals(2, result.size());
        verify(entityManager).createQuery(expectedJpql, Object[].class);
        verify(objectArrayQuery).getResultList();
    }
    
    // ========================================================================
    // TESTS: UTILIDADES
    // ========================================================================
    
    @Test
    @DisplayName("exists() - Debería retornar true cuando existe")
    void testExists_ExistingId_ShouldReturnTrue() {
        // Given
        Long id = 1L;
        String expectedJpql = "SELECT COUNT(t) FROM Transaction t WHERE t.id = :id";
        
        when(entityManager.createQuery(expectedJpql, Long.class)).thenReturn(longQuery);
        when(longQuery.setParameter("id", id)).thenReturn(longQuery);
        when(longQuery.getSingleResult()).thenReturn(1L);
        
        // When
        boolean result = repository.exists(id);
        
        // Then
        assertTrue(result);
        verify(longQuery).setParameter("id", id);
    }
    
    @Test
    @DisplayName("exists() - Debería retornar false con ID null")
    void testExists_NullId_ShouldReturnFalse() {
        // When
        boolean result = repository.exists(null);
        
        // Then
        assertFalse(result);
        verify(entityManager, never()).createQuery(anyString(), eq(Long.class));
    }
    
    @Test
    @DisplayName("clear() - Debería limpiar el contexto de persistencia")
    void testClear_ShouldClearEntityManager() {
        // When
        repository.clear();
        
        // Then
        verify(entityManager).clear();
    }
    
    @Test
    @DisplayName("flush() - Debería forzar sincronización")
    void testFlush_ShouldFlushEntityManager() {
        // When
        repository.flush();
        
        // Then
        verify(entityManager).flush();
    }
}
