@echo off
REM Script para configurar el DataSource en Payara Server
REM Ejecutar desde Windows HOST antes de desplegar la aplicacion

echo ============================================
echo  CONFIGURANDO DATASOURCE EN PAYARA
echo ============================================
echo.

echo [INFO] Paso 1: Creando JDBC Connection Pool...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
  create-jdbc-connection-pool ^
  --datasourceclassname org.postgresql.ds.PGSimpleDataSource ^
  --restype javax.sql.DataSource ^
  --property serverName=database:portNumber=5432:databaseName=curso_db:user=curso_user:password=curso_pass ^
  financialPool

if errorlevel 1 (
    echo [WARN] El pool ya existe o hubo un error, continuando...
) else (
    echo [OK] Pool creado exitosamente
)

echo.
echo [INFO] Paso 2: Creando JDBC Resource...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
  create-jdbc-resource ^
  --connectionpoolid financialPool ^
  jdbc/financialPool

if errorlevel 1 (
    echo [WARN] El resource ya existe o hubo un error
) else (
    echo [OK] Resource creado exitosamente
)

echo.
echo [INFO] Paso 3: Verificando configuracion...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
  list-jdbc-resources

echo.
echo [INFO] Paso 4: Probando conexion al pool...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
  ping-connection-pool financialPool

if errorlevel 1 (
    echo.
    echo [ERROR] No se pudo conectar al pool
    echo [INFO] Verifica que el contenedor 'database' este corriendo:
    echo        docker ps ^| findstr database
    echo.
    echo [INFO] Y que PostgreSQL este accesible:
    echo        docker exec pac_devcontainer-database-1 psql -U curso_user -d curso_db -c "SELECT 1"
    exit /b 1
) else (
    echo [OK] Conexion al pool exitosa!
)

echo.
echo ============================================
echo  DATASOURCE CONFIGURADO CORRECTAMENTE
echo ============================================
echo.
echo Ahora puedes desplegar la aplicacion:
echo   deploy-simple.bat
echo.
echo O manualmente:
echo   docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin deploy --force /workspace/target/javaee-app.war
echo.
