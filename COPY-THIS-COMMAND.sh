#!/bin/bash
# Script para generar el comando EXACTO que necesitas ejecutar en Windows

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 SOLUCIÓN DEFINITIVA - COPIA ESTE COMANDO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Ejecuta esto en tu terminal Windows (CMD):"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat << 'EOF'
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin create-jdbc-connection-pool --datasourceclassname org.postgresql.ds.PGSimpleDataSource --restype javax.sql.DataSource --property serverName=database:portNumber=5432:databaseName=curso_db:user=curso_user:password=curso_pass financialPool && docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin create-jdbc-resource --connectionpoolid financialPool jdbc/financialPool && docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin deploy --force --contextroot=/ /workspace/target/javaee-app.war && timeout /t 10 && curl http://localhost:8080/api/transactions
EOF
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "O ejecuta el script más limpio:"
echo ""
echo "  DEPLOY-FINAL.bat"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 EXPLICACIÓN DEL PROBLEMA:"
echo ""
echo "  - Estás en el devcontainer (no tienes comando 'docker')"
echo "  - Necesitas ejecutar comandos EN el contenedor appserver"
echo "  - Desde Windows HOST puedes usar 'docker exec'"
echo "  - El WAR ya está en /workspace/target/ (volumen compartido)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
