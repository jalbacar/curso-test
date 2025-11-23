#!/bin/bash
# Script DEFINITIVO para desplegar desde devcontainer
# Este script genera los comandos que debes ejecutar en tu HOST

echo "============================================"
echo " GUÍA DE DESPLIEGUE DESDE DEVCONTAINER"
echo "============================================"
echo ""

WAR_PATH="/workspace/target/javaee-app.war"

# Verificar WAR
if [ ! -f "$WAR_PATH" ]; then
    echo "⚠️  WAR no encontrado, compilando..."
    mvn package -DskipTests || exit 1
fi

echo "✅ WAR compilado: $(ls -lh $WAR_PATH | awk '{print $5}')"
echo ""

echo "📋 COPIA Y PEGA ESTOS COMANDOS EN TU TERMINAL WINDOWS:"
echo ""
echo "════════════════════════════════════════════"
echo ""

# Generar comandos para Windows
cat << 'COMMANDS'
REM ==================================================
REM PASO 1: Configurar DataSource (solo primera vez)
REM ==================================================

docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin create-jdbc-connection-pool --datasourceclassname org.postgresql.ds.PGSimpleDataSource --restype javax.sql.DataSource --property serverName=database:portNumber=5432:databaseName=curso_db:user=curso_user:password=curso_pass financialPool

docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin create-jdbc-resource --connectionpoolid financialPool jdbc/financialPool

docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ping-connection-pool financialPool

REM ==================================================
REM PASO 2: Desplegar la aplicación
REM ==================================================

docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin deploy --force --contextroot=/ /workspace/target/javaee-app.war

REM ==================================================
REM PASO 3: Verificar el despliegue
REM ==================================================

docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin list-applications

timeout /t 5

curl http://localhost:8080/api/transactions

REM ==================================================
REM FIN - La aplicación debería estar funcionando
REM ==================================================
COMMANDS

echo ""
echo "════════════════════════════════════════════"
echo ""
echo "💡 ALTERNATIVA RÁPIDA (Autodeploy):"
echo ""
echo "docker cp target\\javaee-app.war pac_devcontainer-appserver-1:/opt/payara/glassfish/domains/domain1/autodeploy/"
echo ""
echo "════════════════════════════════════════════"
echo ""
echo "✨ O USA LOS SCRIPTS .BAT YA CREADOS:"
echo ""
echo "   1. setup-datasource.bat       (Configura BD)"
echo "   2. deploy-simple.bat          (Despliega por autodeploy)"
echo ""
echo "════════════════════════════════════════════"
echo ""
