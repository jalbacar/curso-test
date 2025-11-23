package com.pac.rest;

import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;

/**
 * Clase de configuración de la aplicación JAX-RS.
 * 
 * Define el path base para todos los recursos REST.
 * Todos los endpoints estarán disponibles bajo /api/*
 * 
 * Ejemplo:
 * - TransactionResource estará en: /api/transactions
 * - Otros recursos estarán en: /api/{resource-path}
 * 
 * @author Sistema PAC
 * @version 1.0.0
 */
@ApplicationPath("/api")
public class JaxRsApplication extends Application {
    // No es necesario implementar métodos adicionales
    // La anotación @ApplicationPath es suficiente para activar JAX-RS
}
