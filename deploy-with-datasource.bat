@echo off
REM Script para configurar el DataSource JDBC en Payara

echo ========================================
echo  CONFIGURANDO DATASOURCE JDBC
echo ========================================
echo.

echo [INFO] 1. Creando JDBC Connection Pool...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
  --user admin --passwordfile /opt/payara/passwordFile ^
  create-jdbc-connection-pool ^
  --datasourceclassname org.postgresql.ds.PGSimpleDataSource ^
  --restype javax.sql.DataSource ^
  --property "serverName=database:user=curso_user:password=curso_pass:databaseName=curso_db:portNumber=5432" ^
  financialPool

echo.
echo [INFO] 2. Creando JDBC Resource...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
  --user admin --passwordfile /opt/payara/passwordFile ^
  create-jdbc-resource ^
  --connectionpoolid financialPool ^
  jdbc/financialPool

echo.
echo [INFO] 3. Verificando configuracion...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
  --user admin --passwordfile /opt/payara/passwordFile ^
  list-jdbc-resources

echo.
echo [INFO] 4. Testeando conexion...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
  --user admin --passwordfile /opt/payara/passwordFile ^
  ping-connection-pool financialPool

echo.
echo ========================================
echo  DESPLEGANDO APLICACION
echo ========================================
echo.

docker cp target\javaee-app.war pac_devcontainer-appserver-1:/tmp/javaee-app.war

docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
  --user admin --passwordfile /opt/payara/passwordFile ^
  deploy --force=true --name javaee-app --contextroot / /tmp/javaee-app.war

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo  DESPLIEGUE EXITOSO!
    echo ========================================
    echo.
    timeout /t 5 /nobreak >nul
    
    echo Probando endpoint:
    curl -s http://localhost:8080/api/transactions
    echo.
    echo.
    echo Aplicacion disponible en:
    echo   - http://localhost:8080/api/transactions
    echo   - http://localhost:8080/api/transactions/suspicious
) else (
    echo.
    echo [ERROR] Fallo el despliegue
    docker exec pac_devcontainer-appserver-1 tail -50 /opt/payara/appserver/glassfish/domains/domain1/logs/server.log
)
