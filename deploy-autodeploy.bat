@echo off
REM Script alternativo usando autodeploy en lugar de asadmin

echo ========================================
echo  Desplegando via AUTODEPLOY
echo ========================================
echo.

if not exist "target\javaee-app.war" (
    echo [ERROR] No se encuentra el archivo WAR
    exit /b 1
)

echo [INFO] Copiando WAR al directorio autodeploy...
docker exec pac_devcontainer-appserver-1 mkdir -p /opt/payara/glassfish/domains/domain1/autodeploy
docker cp target\javaee-app.war pac_devcontainer-appserver-1:/opt/payara/glassfish/domains/domain1/autodeploy/

echo.
echo [INFO] Esperando despliegue automatico...
timeout /t 10 /nobreak

echo.
echo ========================================
echo  Verificando despliegue
echo ========================================
curl -s http://localhost:8080/api/transactions
echo.
