package com.pac.rest.filter;

import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.ext.Provider;
import java.io.IOException;

/**
 * Filtro JAX-RS para configurar CORS (Cross-Origin Resource Sharing).
 * 
 * Este filtro agrega los headers necesarios para permitir peticiones
 * desde orígenes diferentes (cross-origin), específicamente desde
 * aplicaciones frontend como React/Vite en localhost:5173.
 * 
 * Headers configurados:
 * - Access-Control-Allow-Origin: Orígenes permitidos
 * - Access-Control-Allow-Methods: Métodos HTTP permitidos
 * - Access-Control-Allow-Headers: Headers personalizados permitidos
 * - Access-Control-Max-Age: Tiempo de caché de preflight
 * 
 * @author Sistema PAC
 * @version 1.0.0
 */
@Provider
public class CorsFilter implements ContainerResponseFilter {
    
    /**
     * Filtro que se ejecuta después de cada respuesta HTTP.
     * Agrega los headers CORS necesarios a todas las respuestas.
     * 
     * @param requestContext Contexto de la petición HTTP
     * @param responseContext Contexto de la respuesta HTTP
     * @throws IOException Si hay error procesando la respuesta
     */
    @Override
    public void filter(ContainerRequestContext requestContext,
                      ContainerResponseContext responseContext) throws IOException {
        
        // Permitir peticiones desde el frontend local (Vite dev server)
        // En producción, cambiar por el dominio real
        responseContext.getHeaders().add(
                "Access-Control-Allow-Origin", "http://localhost:5173");
        
        // También permitir otros puertos comunes de desarrollo
        // responseContext.getHeaders().add("Access-Control-Allow-Origin", "http://localhost:3000");
        
        // Permitir credenciales (cookies, authorization headers)
        responseContext.getHeaders().add(
                "Access-Control-Allow-Credentials", "true");
        
        // Métodos HTTP permitidos
        responseContext.getHeaders().add(
                "Access-Control-Allow-Methods", 
                "GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH");
        
        // Headers personalizados permitidos en las peticiones
        responseContext.getHeaders().add(
                "Access-Control-Allow-Headers",
                "origin, content-type, accept, authorization, x-requested-with");
        
        // Headers que el cliente puede leer en la respuesta
        responseContext.getHeaders().add(
                "Access-Control-Expose-Headers",
                "location, content-disposition");
        
        // Tiempo de caché de la respuesta preflight (24 horas)
        responseContext.getHeaders().add(
                "Access-Control-Max-Age", "86400");
    }
}
