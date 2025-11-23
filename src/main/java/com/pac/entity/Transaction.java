package com.pac.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Entidad JPA que mapea la tabla fact_transactions.
 * 
 * Esta tabla almacena transacciones procesadas y enriquecidas para análisis.
 * 
 * Esquema de la tabla:
 * - id: SERIAL PRIMARY KEY
 * - transactiondate: DATE NOT NULL
 * - amount: DECIMAL(12,2) NOT NULL
 * - description: TEXT NOT NULL
 * - category: VARCHAR(100) NOT NULL
 * - issuspicious: BOOLEAN NOT NULL DEFAULT FALSE
 * - createdat: TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
 * 
 * @author Sistema PAC
 * @version 1.0.0
 */
@Entity
@Table(name = "fact_transactions")
public class Transaction implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    /**
     * Identificador único autoincremental de la transacción.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;
    
    /**
     * Fecha de la transacción.
     * Rango esperado: 2020-01-01 a presente
     */
    @Column(name = "transactiondate", nullable = false)
    private LocalDate transactionDate;
    
    /**
     * Monto de la transacción en la moneda local.
     * Rango típico: 0.01 - 50,000.00
     * Precisión: 2 decimales
     */
    @Column(name = "amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;
    
    /**
     * Descripción textual de la transacción.
     * Incluye detalles del comercio, producto o servicio.
     */
    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;
    
    /**
     * Categoría de la transacción para clasificación.
     * Valores posibles: groceries, housing, transport, food, 
     * transfer, online, suspicious, other
     */
    @Column(name = "category", nullable = false, length = 100)
    private String category;
    
    /**
     * Indicador de transacción sospechosa detectada por reglas de negocio.
     * true: requiere revisión manual
     * false: transacción normal
     * 
     * IMPORTANTE: El nombre del campo en la BD es "issuspicious" (sin guión bajo)
     * pero el getter/setter sigue la convención Java "isSuspicious/setSuspicious"
     */
    @Column(name = "issuspicious", nullable = false)
    private Boolean suspicious = false;
    
    /**
     * Timestamp de creación del registro en esta tabla.
     * Se genera automáticamente al insertar el registro.
     */
    @Column(name = "createdat", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    // ========================================================================
    // CONSTRUCTORES
    // ========================================================================
    
    /**
     * Constructor por defecto requerido por JPA.
     */
    public Transaction() {
        this.createdAt = LocalDateTime.now();
    }
    
    /**
     * Constructor con todos los campos obligatorios.
     * 
     * @param transactionDate Fecha de la transacción
     * @param amount Monto de la transacción
     * @param description Descripción de la transacción
     * @param category Categoría de la transacción
     */
    public Transaction(LocalDate transactionDate, BigDecimal amount, 
                      String description, String category) {
        this();
        this.transactionDate = transactionDate;
        this.amount = amount;
        this.description = description;
        this.category = category;
    }
    
    /**
     * Constructor completo con todos los campos.
     * 
     * @param transactionDate Fecha de la transacción
     * @param amount Monto de la transacción
     * @param description Descripción de la transacción
     * @param category Categoría de la transacción
     * @param suspicious Indicador de transacción sospechosa
     */
    public Transaction(LocalDate transactionDate, BigDecimal amount, 
                      String description, String category, Boolean suspicious) {
        this(transactionDate, amount, description, category);
        this.suspicious = suspicious;
    }
    
    // ========================================================================
    // GETTERS Y SETTERS
    // ========================================================================
    
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public LocalDate getTransactionDate() {
        return transactionDate;
    }
    
    public void setTransactionDate(LocalDate transactionDate) {
        this.transactionDate = transactionDate;
    }
    
    public BigDecimal getAmount() {
        return amount;
    }
    
    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public String getCategory() {
        return category;
    }
    
    public void setCategory(String category) {
        this.category = category;
    }
    
    /**
     * Obtiene el indicador de transacción sospechosa.
     * Nota: El nombre del getter sigue la convención Java para booleanos.
     * 
     * @return true si la transacción es sospechosa, false en caso contrario
     */
    public Boolean isSuspicious() {
        return suspicious;
    }
    
    /**
     * Establece el indicador de transacción sospechosa.
     * 
     * @param suspicious true para marcar como sospechosa, false en caso contrario
     */
    public void setSuspicious(Boolean suspicious) {
        this.suspicious = suspicious;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    // ========================================================================
    // MÉTODOS LIFECYCLE CALLBACKS DE JPA
    // ========================================================================
    
    /**
     * Callback ejecutado antes de persistir la entidad.
     * Establece la fecha de creación si no está definida.
     */
    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
        if (this.suspicious == null) {
            this.suspicious = false;
        }
    }
    
    // ========================================================================
    // MÉTODOS EQUALS, HASHCODE Y TOSTRING
    // ========================================================================
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Transaction that = (Transaction) o;
        return Objects.equals(id, that.id);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
    
    @Override
    public String toString() {
        return "Transaction{" +
                "id=" + id +
                ", transactionDate=" + transactionDate +
                ", amount=" + amount +
                ", description='" + description + '\'' +
                ", category='" + category + '\'' +
                ", suspicious=" + suspicious +
                ", createdAt=" + createdAt +
                '}';
    }
    
    // ========================================================================
    // MÉTODOS DE NEGOCIO (HELPERS)
    // ========================================================================
    
    /**
     * Valida si la transacción cumple con las reglas básicas de negocio.
     * 
     * @return true si la transacción es válida, false en caso contrario
     */
    public boolean isValid() {
        return transactionDate != null 
            && amount != null 
            && amount.compareTo(BigDecimal.ZERO) > 0
            && description != null 
            && !description.trim().isEmpty()
            && category != null 
            && !category.trim().isEmpty();
    }
    
    /**
     * Verifica si la transacción es de alto valor (>= 2000).
     * Las transacciones de alto valor suelen marcarse como sospechosas.
     * 
     * @return true si el monto es >= 2000, false en caso contrario
     */
    public boolean isHighValue() {
        return amount != null && amount.compareTo(new BigDecimal("2000.00")) >= 0;
    }
    
    /**
     * Verifica si la transacción es reciente (últimos 30 días).
     * 
     * @return true si la transacción es de los últimos 30 días
     */
    public boolean isRecent() {
        if (transactionDate == null) return false;
        LocalDate thirtyDaysAgo = LocalDate.now().minusDays(30);
        return transactionDate.isAfter(thirtyDaysAgo) || transactionDate.isEqual(thirtyDaysAgo);
    }
}
