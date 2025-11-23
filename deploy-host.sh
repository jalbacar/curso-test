#!/bin/bash
# Script para desplegar la aplicación en Payara Server desde Linux/Mac
# Ejecutar este archivo desde el directorio raíz del proyecto

echo "========================================"
echo " Desplegando en Payara Server Full"
echo "========================================"
echo ""

# Verificar si el WAR existe
if [ ! -f "target/javaee-app.war" ]; then
    echo "[ERROR] No se encuentra el archivo WAR"
    echo "Por favor, compila primero con: mvn package"
    exit 1
fi

echo "[INFO] WAR encontrado: target/javaee-app.war"
echo ""

# Desplegar usando asadmin (Payara Server Full)
echo "[INFO] Desplegando aplicación..."
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin deploy --force=true /workspace/target/javaee-app.war

# Si falla con la ruta de Server Full, intentar con la ruta alternativa
if [ $? -ne 0 ]; then
    echo "[WARN] Intento 1 falló, probando ruta alternativa..."
    docker exec pac_devcontainer-appserver-1 /opt/payara/glassfish/bin/asadmin deploy --force=true /workspace/target/javaee-app.war
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo " Despliegue Exitoso!"
    echo "========================================"
    echo ""
    echo "Endpoints disponibles:"
    echo "  - http://localhost:8080/api/transactions"
    echo "  - http://localhost:8080/api/transactions/suspicious"
    echo "  - http://localhost:8080/api/transactions/high-value"
    echo "  - http://localhost:8080/api/transactions/stats"
    echo ""
    echo "Probando endpoint..."
    sleep 3
    curl -s http://localhost:8080/api/transactions | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/api/transactions
    echo ""
else
    echo ""
    echo "[ERROR] Falló el despliegue"
    echo "Verifica que el contenedor appserver esté corriendo"
    exit 1
fi
