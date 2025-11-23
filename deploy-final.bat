@echo off
REM Script final usando el passwordfile correcto de Payara

echo ========================================
echo  DESPLIEGUE DEFINITIVO CON DATASOURCE
echo ========================================
echo.

echo [1/5] Verificando WAR...
if not exist "target\javaee-app.war" (
    echo [ERROR] No existe target\javaee-app.war
    exit /b 1
)
echo [OK] WAR encontrado

echo.
echo [2/5] Instalando driver PostgreSQL...
echo [INFO] Descargando PostgreSQL JDBC driver...
curl -L -o target\postgresql-42.7.1.jar https://jdbc.postgresql.org/download/postgresql-42.7.1.jar 2>nul
if errorlevel 1 (
    echo [WARN] No se pudo descargar, verificando si ya existe...
    if not exist "target\postgresql-42.7.1.jar" (
        echo [ERROR] Driver no disponible
        exit /b 1
    )
)

echo [INFO] Copiando driver al contenedor Payara...
docker cp target\postgresql-42.7.1.jar pac_devcontainer-appserver-1:/opt/payara/appserver/glassfish/lib/postgresql-42.7.1.jar
echo [OK] Driver instalado

echo.
echo [3/5] Configurando DataSource...

REM Crear connection pool
echo [INFO] Creando JDBC Connection Pool...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin --user admin --passwordfile /opt/payara/passwordFile create-jdbc-connection-pool --datasourceclassname org.postgresql.ds.PGSimpleDataSource --restype javax.sql.DataSource --property serverName=database:portNumber=5432:databaseName=curso_db:user=curso_user:password=curso_pass financialPool 2>nul
if errorlevel 1 (
    echo [WARN] Pool ya existe o error menor, continuando...
) else (
    echo [OK] Connection pool creado
)

REM Crear JDBC resource
echo [INFO] Creando JDBC Resource...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin --user admin --passwordfile /opt/payara/passwordFile create-jdbc-resource --connectionpoolid financialPool jdbc/financialPool 2>nul
if errorlevel 1 (
    echo [WARN] Resource ya existe o error menor, continuando...
) else (
    echo [OK] JDBC resource creado
)

REM Probar conexion
echo [INFO] Probando conexion al pool...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin --user admin --passwordfile /opt/payara/passwordFile ping-connection-pool financialPool
if errorlevel 1 (
    echo [ERROR] No se puede conectar al pool PostgreSQL
    echo [INFO] Verifica que el contenedor database este corriendo
    exit /b 1
)
echo [OK] Conexion exitosa al pool

echo.
echo [4/5] Copiando WAR al contenedor...
docker cp target\javaee-app.war pac_devcontainer-appserver-1:/tmp/javaee-app.war

echo.
echo [5/5] Desplegando aplicacion...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin --user admin --passwordfile /opt/payara/passwordFile deploy --force=true --name javaee-app --contextroot / /tmp/javaee-app.war

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo  DESPLIEGUE EXITOSO!
    echo ========================================
    echo.
    echo [6/6] Esperando que la aplicacion inicie...
    timeout /t 8 /nobreak >nul
    
    echo.
    echo [INFO] Verificando aplicaciones desplegadas:
    docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin --user admin --passwordfile /opt/payara/passwordFile list-applications
    
    echo.
    echo ========================================
    echo  PROBANDO ENDPOINTS
    echo ========================================
    echo.
    
    echo [GET] /api/transactions
    curl -s http://localhost:8080/api/transactions
    echo.
    echo.
    
    echo [GET] /api/transactions/suspicious
    curl -s http://localhost:8080/api/transactions/suspicious
    echo.
    echo.
    
    echo Endpoints disponibles:
    echo   - http://localhost:8080/api/transactions
    echo   - http://localhost:8080/api/transactions/suspicious
    echo   - http://localhost:8080/api/transactions/stats
    echo   - http://localhost:8080/api/transactions/high-value
    echo.
) else (
    echo.
    echo [ERROR] Fallo el despliegue
    echo.
    echo Mostrando ultimas 30 lineas del log:
    docker exec pac_devcontainer-appserver-1 tail -30 /opt/payara/appserver/glassfish/domains/domain1/logs/server.log
)

echo.
