#!/bin/bash
# Script para desplegar la aplicación en Payara Server
# Este script se ejecuta DESDE DENTRO del devcontainer

echo "🚀 Desplegando aplicación en Payara Server..."

# Compilar la aplicación
echo "📦 Compilando aplicación..."
mvn package -DskipTests

if [ $? -ne 0 ]; then
    echo "❌ Error en la compilación"
    exit 1
fi

echo "✅ Compilación exitosa"

# El WAR está en /workspace/target/javaee-app.war
WAR_PATH="/workspace/target/javaee-app.war"

# Verificar que el WAR existe
if [ ! -f "$WAR_PATH" ]; then
    echo "❌ No se encuentra el archivo WAR en $WAR_PATH"
    exit 1
fi

echo "📤 Desplegando en Payara Server Full..."

# Método 1: Intentar usando el API REST de administración de Payara
echo "Usando API REST de Payara..."
DEPLOY_RESPONSE=$(curl -s -o /tmp/deploy_response.txt -w "%{http_code}" \
    -X POST \
    -H "X-Requested-By: GlassFish REST HTML interface" \
    -F "id=@${WAR_PATH}" \
    -F "force=true" \
    -F "DEFAULT=@${WAR_PATH}" \
    "http://appserver:4848/management/domain/applications/application")

if [ "$DEPLOY_RESPONSE" = "200" ] || [ "$DEPLOY_RESPONSE" = "201" ]; then
    echo "✅ Aplicación desplegada exitosamente"
    echo "🌐 Endpoints disponibles:"
    echo "   - http://localhost:8080/api/transactions"
    echo "   - http://localhost:8080/api/transactions/suspicious"
    echo ""
    echo "🧪 Probando endpoint..."
    sleep 5
    curl -s http://appserver:8080/api/transactions 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -s http://appserver:8080/api/transactions
else
    echo "⚠️  API REST no funcionó (HTTP $DEPLOY_RESPONSE), intentando método alternativo..."
    cat /tmp/deploy_response.txt
    echo ""
    echo "🔧 Copiando al directorio autodeploy..."
    
    # Método 2: Usar autodeploy copiando el archivo
    # Nota: Esto requiere que el contenedor tenga acceso al filesystem compartido
    AUTODEPLOY_DIR="/opt/payara/glassfish/domains/domain1/autodeploy"
    
    # Verificar si podemos acceder al autodeploy via volumen compartido
    if [ -d "/payara-autodeploy" ]; then
        cp "$WAR_PATH" /payara-autodeploy/javaee-app.war
        echo "✅ WAR copiado a autodeploy"
    else
        echo "❌ No se puede acceder al directorio autodeploy"
        echo ""
        echo "💡 Ejecuta manualmente desde tu terminal HOST:"
        echo "   docker exec appserver /opt/payara/bin/asadmin deploy --force=true /workspace/target/javaee-app.war"
        exit 1
    fi
    
    echo "⏳ Esperando que Payara procese el despliegue automático..."
    sleep 10
    
    echo "🧪 Verificando despliegue..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://appserver:8080/api/transactions)
    if [ "$RESPONSE" = "200" ]; then
        echo "✅ Aplicación desplegada correctamente"
    else
        echo "⚠️  La aplicación puede estar desplegándose todavía (HTTP $RESPONSE)"
        echo "   Espera unos segundos e intenta: curl http://localhost:8080/api/transactions"
    fi
fi
