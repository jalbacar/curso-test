#!/bin/bash
# Script para desplegar la aplicación en Payara Server Full

echo "🚀 Desplegando aplicación en Payara Server..."

# Verificar si ya está compilado
if [ ! -f "/workspace/target/javaee-app.war" ]; then
    echo "📦 Compilando aplicación..."
    mvn package -DskipTests
    
    if [ $? -ne 0 ]; then
        echo "❌ Error en la compilación"
        exit 1
    fi
fi

echo "✅ WAR encontrado: /workspace/target/javaee-app.war"

# Mostrar información del WAR
echo "📊 Tamaño: $(du -h /workspace/target/javaee-app.war | cut -f1)"

# Mensaje de instrucciones para desplegar
echo ""
echo "📝 Para desplegar en Payara Server Full, ejecuta desde tu terminal HOST:"
echo ""
echo "   docker exec appserver /opt/payara/bin/asadmin deploy --force=true --contextroot=/ /workspace/target/javaee-app.war"
echo ""
echo "O alternativamente:"
echo ""
echo "   docker exec appserver bash -c 'cp /workspace/target/javaee-app.war /opt/payara/glassfish/domains/domain1/autodeploy/'"
echo ""
echo "🌐 Después podrás acceder a: http://localhost:8080/api/transactions"
