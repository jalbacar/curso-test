#!/bin/bash
# Script para desplegar la aplicación en Payara Server Full Edition
# Ejecutar desde dentro del devcontainer

echo "🚀 Desplegando aplicación en Payara Server Full Edition..."
echo ""

# Verificar que el WAR existe
WAR_PATH="/workspace/target/javaee-app.war"
if [ ! -f "$WAR_PATH" ]; then
    echo "❌ No se encuentra el archivo WAR en $WAR_PATH"
    echo "   Compilando primero..."
    mvn package -DskipTests
    if [ $? -ne 0 ]; then
        echo "❌ Error en la compilación"
        exit 1
    fi
fi

echo "✅ WAR encontrado: $(ls -lh $WAR_PATH | awk '{print $5}')"
echo ""

# Verificar conectividad con Payara Server
echo "🔍 Verificando conectividad con Payara Server..."
PAYARA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://appserver:4848 2>/dev/null || echo "000")

if [ "$PAYARA_STATUS" = "000" ]; then
    echo "❌ No se puede conectar con Payara Server en appserver:4848"
    echo "   Verifica que el contenedor 'appserver' esté corriendo"
    exit 1
fi

echo "✅ Payara Server está corriendo (HTTP $PAYARA_STATUS)"
echo ""

# Primero intentar undeployar si existe
echo "🗑️  Intentando undeployear aplicación existente..."
curl -s -X DELETE \
    -H "X-Requested-By: GlassFish REST HTML interface" \
    "http://appserver:4848/management/domain/applications/application/javaee-app" \
    > /dev/null 2>&1 || true

sleep 2

# Desplegar usando el API REST de Payara con el formato correcto
echo "📤 Desplegando vía API REST de Payara..."
DEPLOY_OUTPUT=$(curl -s -X POST \
    -H "Accept: application/json" \
    -H "X-Requested-By: GlassFish REST HTML interface" \
    -F "id=@${WAR_PATH}" \
    -F "force=true" \
    -F "contextroot=/" \
    -F "availabilityenabled=false" \
    -F "asyncreplication=true" \
    -F "name=javaee-app" \
    "http://appserver:4848/management/domain/applications/application" 2>&1)

echo "$DEPLOY_OUTPUT" > /tmp/deploy_response.txt

# Verificar si hubo éxito en el despliegue
if echo "$DEPLOY_OUTPUT" | grep -q "Application deployed successfully" || \
   echo "$DEPLOY_OUTPUT" | grep -q "exit_code.*SUCCESS" || \
   echo "$DEPLOY_OUTPUT" | grep -q "javaee-app was successfully deployed"; then
    echo "✅ Despliegue completado"
else
    echo "⚠️  Respuesta del servidor:"
    echo "$DEPLOY_OUTPUT" | python3 -m json.tool 2>/dev/null || echo "$DEPLOY_OUTPUT"
fi

# Esperar a que el despliegue se complete
echo ""
echo "⏳ Esperando que la aplicación se despliegue..."
sleep 10

# Verificar el despliegue
echo ""
echo "🧪 Verificando despliegue..."

# Intentar varios endpoints posibles
ENDPOINTS=(
    "http://appserver:8080/api/transactions"
    "http://appserver:8080/javaee-app/api/transactions"
    "http://localhost:8080/api/transactions"
    "http://localhost:8080/javaee-app/api/transactions"
)

SUCCESS=false
for ENDPOINT in "${ENDPOINTS[@]}"; do
    echo "   Probando: $ENDPOINT"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$ENDPOINT" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "   ✅ Endpoint funciona (HTTP $HTTP_CODE)"
        SUCCESS=true
        WORKING_ENDPOINT="$ENDPOINT"
        break
    else
        echo "   ⚠️  HTTP $HTTP_CODE"
    fi
done

echo ""
if [ "$SUCCESS" = true ]; then
    echo "✅ ¡APLICACIÓN DESPLEGADA EXITOSAMENTE!"
    echo ""
    echo "🌐 Endpoints disponibles:"
    echo "   - $WORKING_ENDPOINT"
    echo "   - ${WORKING_ENDPOINT}/suspicious"
    echo ""
    echo "📊 Probando endpoint..."
    curl -s "$WORKING_ENDPOINT" 2>/dev/null | python3 -m json.tool 2>/dev/null | head -50 || curl -s "$WORKING_ENDPOINT" | head -20
else
    echo "⚠️  No se pudo verificar el despliegue automáticamente"
    echo ""
    echo "🔧 Opciones de troubleshooting:"
    echo ""
    echo "1. Verificar logs de Payara:"
    echo "   docker logs appserver --tail 100"
    echo ""
    echo "2. Listar aplicaciones desplegadas:"
    echo "   docker exec appserver /opt/payara/bin/asadmin list-applications"
    echo ""
    echo "3. Desplegar manualmente con asadmin:"
    echo "   docker exec appserver /opt/payara/bin/asadmin deploy --force=true --contextroot=/ /workspace/target/javaee-app.war"
    echo ""
    echo "4. Verificar el datasource:"
    echo "   docker exec appserver /opt/payara/bin/asadmin list-jdbc-resources"
    echo ""
    echo "5. Ver logs del servidor en tiempo real:"
    echo "   docker exec -it appserver tail -f /opt/payara/glassfish/domains/domain1/logs/server.log"
    echo ""
fi
