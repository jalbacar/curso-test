@echo off
REM Script simplificado - Copia WAR al directorio autodeploy
REM Este metodo no requiere autenticacion

echo ============================================
echo  DESPLIEGUE POR AUTODEPLOY
echo ============================================
echo.

REM Verificar que el WAR existe
if not exist "target\javaee-app.war" (
    echo [ERROR] No se encuentra target\javaee-app.war
    echo [INFO] Compilando...
    docker exec pac_devcontainer-devcontainer-1 bash -c "cd /workspace && mvn package -DskipTests"
)

echo [INFO] Copiando WAR al directorio autodeploy...
docker cp target\javaee-app.war pac_devcontainer-appserver-1:/opt/payara/glassfish/domains/domain1/autodeploy/javaee-app.war

echo [OK] WAR copiado
echo.
echo [INFO] Esperando que Payara despliegue automaticamente...
echo       Esto puede tomar 10-15 segundos...
timeout /t 15 /nobreak

echo.
echo [INFO] Verificando despliegue...
curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://localhost:8080/api/transactions

echo.
echo ============================================
echo  ENDPOINTS
echo ============================================
echo  http://localhost:8080/api/transactions
echo  http://localhost:8080/api/transactions/suspicious
echo ============================================
echo.

curl -s http://localhost:8080/api/transactions

echo.
echo [OK] Completado!
