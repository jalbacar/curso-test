package com.pac.repository;

import com.pac.entity.Transaction;

import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Repositorio stateless EJB para gestionar operaciones de persistencia de Transaction.
 * 
 * Este repositorio proporciona métodos CRUD y consultas especializadas para
 * la entidad Transaction usando JPA/JPQL.
 * 
 * @author Sistema PAC
 * @version 1.0.0
 */
@Stateless
public class TransactionRepository {
    
    /**
     * EntityManager inyectado por el contenedor.
     * Gestiona el contexto de persistencia definido en persistence.xml
     */
    @PersistenceContext(unitName = "primary")
    private EntityManager entityManager;
    
    // ========================================================================
    // MÉTODOS CRUD BÁSICOS
    // ========================================================================
    
    /**
     * Persiste una nueva transacción en la base de datos.
     * 
     * @param transaction Entidad Transaction a persistir
     * @return La transacción persistida con el ID generado
     * @throws IllegalArgumentException si la transacción es null o no es válida
     */
    public Transaction create(Transaction transaction) {
        if (transaction == null) {
            throw new IllegalArgumentException("Transaction cannot be null");
        }
        if (!transaction.isValid()) {
            throw new IllegalArgumentException("Transaction data is not valid");
        }
        entityManager.persist(transaction);
        entityManager.flush(); // Forzar escritura para obtener el ID
        return transaction;
    }
    
    /**
     * Busca una transacción por su identificador único.
     * 
     * @param id Identificador de la transacción
     * @return Optional con la transacción si existe, Optional.empty() si no
     */
    public Optional<Transaction> findById(Long id) {
        if (id == null) {
            return Optional.empty();
        }
        Transaction transaction = entityManager.find(Transaction.class, id);
        return Optional.ofNullable(transaction);
    }
    
    /**
     * Recupera todas las transacciones de la base de datos.
     * Las transacciones se ordenan por fecha descendente (más recientes primero).
     * 
     * @return Lista de todas las transacciones
     */
    public List<Transaction> findAll() {
        String jpql = "SELECT t FROM Transaction t ORDER BY t.transactionDate DESC, t.amount DESC";
        TypedQuery<Transaction> query = entityManager.createQuery(jpql, Transaction.class);
        return query.getResultList();
    }
    
    /**
     * Actualiza una transacción existente.
     * 
     * @param transaction Transacción con los datos actualizados
     * @return La transacción actualizada
     * @throws IllegalArgumentException si la transacción es null o no tiene ID
     */
    public Transaction update(Transaction transaction) {
        if (transaction == null || transaction.getId() == null) {
            throw new IllegalArgumentException("Transaction and ID cannot be null for update");
        }
        return entityManager.merge(transaction);
    }
    
    /**
     * Elimina una transacción de la base de datos.
     * 
     * @param id Identificador de la transacción a eliminar
     * @return true si se eliminó exitosamente, false si no existía
     */
    public boolean delete(Long id) {
        Optional<Transaction> transaction = findById(id);
        if (transaction.isPresent()) {
            entityManager.remove(transaction.get());
            return true;
        }
        return false;
    }
    
    // ========================================================================
    // CONSULTAS ESPECIALIZADAS
    // ========================================================================
    
    /**
     * Recupera todas las transacciones marcadas como sospechosas.
     * Las transacciones sospechosas requieren revisión manual.
     * 
     * @return Lista de transacciones con flag suspicious = true
     */
    public List<Transaction> findSuspicious() {
        String jpql = "SELECT t FROM Transaction t WHERE t.suspicious = true " +
                     "ORDER BY t.transactionDate DESC, t.amount DESC";
        TypedQuery<Transaction> query = entityManager.createQuery(jpql, Transaction.class);
        return query.getResultList();
    }
    
    /**
     * Recupera transacciones por categoría específica.
     * 
     * @param category Categoría a buscar (groceries, housing, transport, etc.)
     * @return Lista de transacciones de la categoría especificada
     */
    public List<Transaction> findByCategory(String category) {
        if (category == null || category.trim().isEmpty()) {
            return List.of();
        }
        String jpql = "SELECT t FROM Transaction t WHERE t.category = :category " +
                     "ORDER BY t.transactionDate DESC";
        TypedQuery<Transaction> query = entityManager.createQuery(jpql, Transaction.class);
        query.setParameter("category", category);
        return query.getResultList();
    }
    
    /**
     * Recupera transacciones en un rango de fechas.
     * 
     * @param startDate Fecha inicial del rango (inclusiva)
     * @param endDate Fecha final del rango (inclusiva)
     * @return Lista de transacciones en el rango de fechas
     */
    public List<Transaction> findByDateRange(LocalDate startDate, LocalDate endDate) {
        if (startDate == null || endDate == null) {
            throw new IllegalArgumentException("Start date and end date cannot be null");
        }
        String jpql = "SELECT t FROM Transaction t " +
                     "WHERE t.transactionDate BETWEEN :startDate AND :endDate " +
                     "ORDER BY t.transactionDate DESC";
        TypedQuery<Transaction> query = entityManager.createQuery(jpql, Transaction.class);
        query.setParameter("startDate", startDate);
        query.setParameter("endDate", endDate);
        return query.getResultList();
    }
    
    /**
     * Recupera transacciones con monto mayor o igual al especificado.
     * Útil para detectar transacciones de alto valor.
     * 
     * @param minAmount Monto mínimo de la transacción
     * @return Lista de transacciones con monto >= minAmount
     */
    public List<Transaction> findByMinAmount(BigDecimal minAmount) {
        if (minAmount == null) {
            throw new IllegalArgumentException("Minimum amount cannot be null");
        }
        String jpql = "SELECT t FROM Transaction t " +
                     "WHERE t.amount >= :minAmount " +
                     "ORDER BY t.amount DESC";
        TypedQuery<Transaction> query = entityManager.createQuery(jpql, Transaction.class);
        query.setParameter("minAmount", minAmount);
        return query.getResultList();
    }
    
    /**
     * Recupera transacciones de alto valor (>= 2000).
     * Estas transacciones típicamente se marcan como sospechosas.
     * 
     * @return Lista de transacciones de alto valor
     */
    public List<Transaction> findHighValue() {
        return findByMinAmount(new BigDecimal("2000.00"));
    }
    
    /**
     * Busca transacciones por descripción (búsqueda parcial case-insensitive).
     * 
     * @param searchTerm Término de búsqueda en la descripción
     * @return Lista de transacciones que contienen el término en la descripción
     */
    public List<Transaction> findByDescriptionContaining(String searchTerm) {
        if (searchTerm == null || searchTerm.trim().isEmpty()) {
            return List.of();
        }
        String jpql = "SELECT t FROM Transaction t " +
                     "WHERE LOWER(t.description) LIKE LOWER(:searchTerm) " +
                     "ORDER BY t.transactionDate DESC";
        TypedQuery<Transaction> query = entityManager.createQuery(jpql, Transaction.class);
        query.setParameter("searchTerm", "%" + searchTerm + "%");
        return query.getResultList();
    }
    
    /**
     * Recupera transacciones recientes (últimos N días).
     * 
     * @param days Número de días hacia atrás desde hoy
     * @return Lista de transacciones de los últimos N días
     */
    public List<Transaction> findRecent(int days) {
        if (days <= 0) {
            throw new IllegalArgumentException("Days must be positive");
        }
        LocalDate startDate = LocalDate.now().minusDays(days);
        String jpql = "SELECT t FROM Transaction t " +
                     "WHERE t.transactionDate >= :startDate " +
                     "ORDER BY t.transactionDate DESC";
        TypedQuery<Transaction> query = entityManager.createQuery(jpql, Transaction.class);
        query.setParameter("startDate", startDate);
        return query.getResultList();
    }
    
    // ========================================================================
    // MÉTODOS DE AGREGACIÓN Y ESTADÍSTICAS
    // ========================================================================
    
    /**
     * Cuenta el total de transacciones en la base de datos.
     * 
     * @return Número total de transacciones
     */
    public Long count() {
        String jpql = "SELECT COUNT(t) FROM Transaction t";
        TypedQuery<Long> query = entityManager.createQuery(jpql, Long.class);
        return query.getSingleResult();
    }
    
    /**
     * Cuenta el número de transacciones sospechosas.
     * 
     * @return Número de transacciones con suspicious = true
     */
    public Long countSuspicious() {
        String jpql = "SELECT COUNT(t) FROM Transaction t WHERE t.suspicious = true";
        TypedQuery<Long> query = entityManager.createQuery(jpql, Long.class);
        return query.getSingleResult();
    }
    
    /**
     * Calcula la suma total de todas las transacciones.
     * 
     * @return Suma total de montos de todas las transacciones
     */
    public BigDecimal sumTotal() {
        String jpql = "SELECT COALESCE(SUM(t.amount), 0) FROM Transaction t";
        TypedQuery<BigDecimal> query = entityManager.createQuery(jpql, BigDecimal.class);
        return query.getSingleResult();
    }
    
    /**
     * Calcula el monto promedio de las transacciones.
     * 
     * @return Monto promedio, 0 si no hay transacciones
     */
    public BigDecimal average() {
        String jpql = "SELECT COALESCE(AVG(t.amount), 0) FROM Transaction t";
        TypedQuery<BigDecimal> query = entityManager.createQuery(jpql, BigDecimal.class);
        return query.getSingleResult();
    }
    
    /**
     * Cuenta transacciones agrupadas por categoría.
     * 
     * @return Lista de arrays [categoría, count] con el conteo por categoría
     */
    public List<Object[]> countByCategory() {
        String jpql = "SELECT t.category, COUNT(t) FROM Transaction t " +
                     "GROUP BY t.category " +
                     "ORDER BY COUNT(t) DESC";
        TypedQuery<Object[]> query = entityManager.createQuery(jpql, Object[].class);
        return query.getResultList();
    }
    
    /**
     * Calcula el monto total por categoría.
     * 
     * @return Lista de arrays [categoría, sum] con el total por categoría
     */
    public List<Object[]> sumByCategory() {
        String jpql = "SELECT t.category, SUM(t.amount) FROM Transaction t " +
                     "GROUP BY t.category " +
                     "ORDER BY SUM(t.amount) DESC";
        TypedQuery<Object[]> query = entityManager.createQuery(jpql, Object[].class);
        return query.getResultList();
    }
    
    // ========================================================================
    // MÉTODOS DE UTILIDAD
    // ========================================================================
    
    /**
     * Verifica si existe una transacción con el ID especificado.
     * 
     * @param id Identificador a verificar
     * @return true si existe, false en caso contrario
     */
    public boolean exists(Long id) {
        if (id == null) {
            return false;
        }
        String jpql = "SELECT COUNT(t) FROM Transaction t WHERE t.id = :id";
        TypedQuery<Long> query = entityManager.createQuery(jpql, Long.class);
        query.setParameter("id", id);
        return query.getSingleResult() > 0;
    }
    
    /**
     * Limpia el contexto de persistencia.
     * Útil para liberar memoria en operaciones batch.
     */
    public void clear() {
        entityManager.clear();
    }
    
    /**
     * Fuerza la sincronización del contexto de persistencia con la base de datos.
     */
    public void flush() {
        entityManager.flush();
    }
}
