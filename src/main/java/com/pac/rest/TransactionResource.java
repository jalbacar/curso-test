package com.pac.rest;

import com.pac.entity.Transaction;
import com.pac.repository.TransactionRepository;

import javax.ejb.EJB;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Recurso REST JAX-RS para gestionar transacciones.
 * 
 * Este endpoint expone operaciones CRUD y consultas sobre transacciones
 * financieras con soporte CORS para aplicaciones frontend.
 * 
 * Base URL: /api/transactions
 * CORS habilitado para: http://localhost:5173
 * 
 * @author Sistema PAC
 * @version 1.0.0
 */
@Path("/transactions")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class TransactionResource {
    
    private static final Logger LOGGER = Logger.getLogger(TransactionResource.class.getName());
    
    /**
     * Repositorio de transacciones inyectado por el contenedor EJB.
     */
    @EJB
    private TransactionRepository transactionRepository;
    
    // ========================================================================
    // ENDPOINTS PRINCIPALES
    // ========================================================================
    
    /**
     * Recupera todas las transacciones.
     * 
     * GET /api/transactions
     * 
     * @return Response con lista de todas las transacciones en JSON
     *         Status 200 si éxito
     *         Status 500 si error del servidor
     */
    @GET
    public Response getAllTransactions() {
        try {
            LOGGER.info("Fetching all transactions");
            List<Transaction> transactions = transactionRepository.findAll();
            LOGGER.info(String.format("Found %d transactions", transactions.size()));
            return Response.ok(transactions).build();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error fetching all transactions", e);
            return Response.serverError()
                    .entity(new ErrorResponse("Error retrieving transactions: " + e.getMessage()))
                    .build();
        }
    }
    
    /**
     * Recupera solo las transacciones marcadas como sospechosas.
     * 
     * GET /api/transactions/suspicious
     * 
     * @return Response con lista de transacciones sospechosas en JSON
     *         Status 200 si éxito
     *         Status 500 si error del servidor
     */
    @GET
    @Path("/suspicious")
    public Response getSuspiciousTransactions() {
        try {
            LOGGER.info("Fetching suspicious transactions");
            List<Transaction> suspiciousTransactions = transactionRepository.findSuspicious();
            LOGGER.info(String.format("Found %d suspicious transactions", suspiciousTransactions.size()));
            return Response.ok(suspiciousTransactions).build();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error fetching suspicious transactions", e);
            return Response.serverError()
                    .entity(new ErrorResponse("Error retrieving suspicious transactions: " + e.getMessage()))
                    .build();
        }
    }
    
    // ========================================================================
    // ENDPOINTS ADICIONALES
    // ========================================================================
    
    /**
     * Recupera una transacción específica por ID.
     * 
     * GET /api/transactions/{id}
     * 
     * @param id Identificador de la transacción
     * @return Response con la transacción si existe
     *         Status 200 si encontrada
     *         Status 404 si no existe
     *         Status 500 si error del servidor
     */
    @GET
    @Path("/{id}")
    public Response getTransactionById(@PathParam("id") Long id) {
        try {
            LOGGER.info(String.format("Fetching transaction with ID: %d", id));
            return transactionRepository.findById(id)
                    .map(transaction -> Response.ok(transaction).build())
                    .orElse(Response.status(Response.Status.NOT_FOUND)
                            .entity(new ErrorResponse("Transaction not found with ID: " + id))
                            .build());
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, String.format("Error fetching transaction ID: %d", id), e);
            return Response.serverError()
                    .entity(new ErrorResponse("Error retrieving transaction: " + e.getMessage()))
                    .build();
        }
    }
    
    /**
     * Recupera transacciones filtradas por categoría.
     * 
     * GET /api/transactions/category/{category}
     * 
     * @param category Categoría a filtrar (groceries, housing, transport, etc.)
     * @return Response con lista de transacciones de la categoría
     */
    @GET
    @Path("/category/{category}")
    public Response getTransactionsByCategory(@PathParam("category") String category) {
        try {
            LOGGER.info(String.format("Fetching transactions for category: %s", category));
            List<Transaction> transactions = transactionRepository.findByCategory(category);
            LOGGER.info(String.format("Found %d transactions for category %s", transactions.size(), category));
            return Response.ok(transactions).build();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, String.format("Error fetching transactions for category: %s", category), e);
            return Response.serverError()
                    .entity(new ErrorResponse("Error retrieving transactions by category: " + e.getMessage()))
                    .build();
        }
    }
    
    /**
     * Recupera transacciones de alto valor (>= 2000).
     * 
     * GET /api/transactions/high-value
     * 
     * @return Response con lista de transacciones de alto valor
     */
    @GET
    @Path("/high-value")
    public Response getHighValueTransactions() {
        try {
            LOGGER.info("Fetching high value transactions");
            List<Transaction> transactions = transactionRepository.findHighValue();
            LOGGER.info(String.format("Found %d high value transactions", transactions.size()));
            return Response.ok(transactions).build();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error fetching high value transactions", e);
            return Response.serverError()
                    .entity(new ErrorResponse("Error retrieving high value transactions: " + e.getMessage()))
                    .build();
        }
    }
    
    /**
     * Recupera transacciones recientes (últimos N días).
     * 
     * GET /api/transactions/recent?days=30
     * 
     * @param days Número de días hacia atrás (default: 30)
     * @return Response con lista de transacciones recientes
     */
    @GET
    @Path("/recent")
    public Response getRecentTransactions(@QueryParam("days") @DefaultValue("30") int days) {
        try {
            LOGGER.info(String.format("Fetching transactions from last %d days", days));
            List<Transaction> transactions = transactionRepository.findRecent(days);
            LOGGER.info(String.format("Found %d recent transactions", transactions.size()));
            return Response.ok(transactions).build();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, String.format("Error fetching recent transactions (%d days)", days), e);
            return Response.serverError()
                    .entity(new ErrorResponse("Error retrieving recent transactions: " + e.getMessage()))
                    .build();
        }
    }
    
    // ========================================================================
    // ENDPOINTS DE ESTADÍSTICAS
    // ========================================================================
    
    /**
     * Recupera estadísticas generales de transacciones.
     * 
     * GET /api/transactions/stats
     * 
     * @return Response con objeto de estadísticas
     */
    @GET
    @Path("/stats")
    public Response getStatistics() {
        try {
            LOGGER.info("Fetching transaction statistics");
            TransactionStats stats = new TransactionStats(
                    transactionRepository.count(),
                    transactionRepository.countSuspicious(),
                    transactionRepository.sumTotal(),
                    transactionRepository.average()
            );
            return Response.ok(stats).build();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error fetching statistics", e);
            return Response.serverError()
                    .entity(new ErrorResponse("Error retrieving statistics: " + e.getMessage()))
                    .build();
        }
    }
    
    /**
     * Recupera conteo de transacciones agrupadas por categoría.
     * 
     * GET /api/transactions/stats/by-category
     * 
     * @return Response con lista de objetos [categoría, count]
     */
    @GET
    @Path("/stats/by-category")
    public Response getCountByCategory() {
        try {
            LOGGER.info("Fetching transaction count by category");
            List<Object[]> stats = transactionRepository.countByCategory();
            return Response.ok(stats).build();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error fetching count by category", e);
            return Response.serverError()
                    .entity(new ErrorResponse("Error retrieving category statistics: " + e.getMessage()))
                    .build();
        }
    }
    
    // ========================================================================
    // CLASE INTERNA PARA RESPUESTAS DE ERROR
    // ========================================================================
    
    /**
     * Clase para encapsular mensajes de error en respuestas JSON.
     */
    public static class ErrorResponse {
        private String error;
        private long timestamp;
        
        public ErrorResponse(String error) {
            this.error = error;
            this.timestamp = System.currentTimeMillis();
        }
        
        public String getError() {
            return error;
        }
        
        public void setError(String error) {
            this.error = error;
        }
        
        public long getTimestamp() {
            return timestamp;
        }
        
        public void setTimestamp(long timestamp) {
            this.timestamp = timestamp;
        }
    }
    
    // ========================================================================
    // CLASE INTERNA PARA ESTADÍSTICAS
    // ========================================================================
    
    /**
     * Clase para encapsular estadísticas de transacciones.
     */
    public static class TransactionStats {
        private Long totalCount;
        private Long suspiciousCount;
        private java.math.BigDecimal totalAmount;
        private java.math.BigDecimal averageAmount;
        
        public TransactionStats(Long totalCount, Long suspiciousCount, 
                               java.math.BigDecimal totalAmount, java.math.BigDecimal averageAmount) {
            this.totalCount = totalCount;
            this.suspiciousCount = suspiciousCount;
            this.totalAmount = totalAmount;
            this.averageAmount = averageAmount;
        }
        
        public Long getTotalCount() {
            return totalCount;
        }
        
        public void setTotalCount(Long totalCount) {
            this.totalCount = totalCount;
        }
        
        public Long getSuspiciousCount() {
            return suspiciousCount;
        }
        
        public void setSuspiciousCount(Long suspiciousCount) {
            this.suspiciousCount = suspiciousCount;
        }
        
        public java.math.BigDecimal getTotalAmount() {
            return totalAmount;
        }
        
        public void setTotalAmount(java.math.BigDecimal totalAmount) {
            this.totalAmount = totalAmount;
        }
        
        public java.math.BigDecimal getAverageAmount() {
            return averageAmount;
        }
        
        public void setAverageAmount(java.math.BigDecimal averageAmount) {
            this.averageAmount = averageAmount;
        }
    }
}
