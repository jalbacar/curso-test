@echo off
REM Script robusto para desplegar en Payara Server Full
REM Verifica primero la estructura del contenedor

echo ========================================
echo  Desplegando en Payara Server Full
echo ========================================
echo.

if not exist "target\javaee-app.war" (
    echo [ERROR] No se encuentra el archivo WAR
    exit /b 1
)

echo [INFO] WAR encontrado: target\javaee-app.war
echo.

REM Primero, verificar la estructura del contenedor
echo [INFO] Verificando estructura del contenedor...
docker exec pac_devcontainer-appserver-1 ls -la /opt/payara/ 2>nul

echo.
echo [INFO] Buscando asadmin...
docker exec pac_devcontainer-appserver-1 find /opt/payara -name asadmin -type f 2>nul

echo.
echo [INFO] Método 1: Copiar al directorio autodeploy...
docker exec pac_devcontainer-appserver-1 mkdir -p /opt/payara/appserver/glassfish/domains/domain1/autodeploy 2>nul
docker exec pac_devcontainer-appserver-1 mkdir -p /opt/payara/glassfish/domains/domain1/autodeploy 2>nul

REM Copiar el WAR al contenedor primero
echo [INFO] Copiando WAR al contenedor...
docker cp target\javaee-app.war pac_devcontainer-appserver-1:/tmp/javaee-app.war

REM Intentar mover al autodeploy
echo [INFO] Moviendo a autodeploy...
docker exec pac_devcontainer-appserver-1 bash -c "cp /tmp/javaee-app.war /opt/payara/appserver/glassfish/domains/domain1/autodeploy/ 2>/dev/null || cp /tmp/javaee-app.war /opt/payara/glassfish/domains/domain1/autodeploy/ 2>/dev/null || echo 'No se pudo copiar a autodeploy'"

echo.
echo [INFO] Esperando 15 segundos para el despliegue automatico...
timeout /t 15 /nobreak >nul

echo.
echo ========================================
echo  Verificando despliegue
echo ========================================
curl -s http://localhost:8080/api/transactions
echo.
echo.

REM Si no funciona, intentar con asadmin
echo [INFO] Si no funciono, intentando con asadmin...
docker exec pac_devcontainer-appserver-1 bash -c "$(find /opt/payara -name asadmin -type f | head -1) deploy --force=true /tmp/javaee-app.war"

timeout /t 5 /nobreak >nul
curl -s http://localhost:8080/api/transactions

echo.
