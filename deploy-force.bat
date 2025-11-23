@echo off
REM Script para verificar el estado y forzar despliegue

echo ========================================
echo  DIAGNOSTICO Y DESPLIEGUE FORZADO
echo ========================================
echo.

echo [INFO] 1. Verificando contenedor...
docker ps | findstr appserver

echo.
echo [INFO] 2. Verificando aplicaciones desplegadas...
curl -s "http://localhost:4848/management/domain/applications/application" 2>nul | find "javaee-app"

echo.
echo [INFO] 3. Copiando WAR al contenedor...
docker cp target\javaee-app.war pac_devcontainer-appserver-1:/tmp/app.war

echo.
echo [INFO] 4. Creando archivo de password vacio...
docker exec pac_devcontainer-appserver-1 bash -c "echo 'AS_ADMIN_PASSWORD=' > /tmp/pwdfile"

echo.
echo [INFO] 5. Intentando desplegar con asadmin y passwordfile...
docker exec pac_devcontainer-appserver-1 bash -c "/opt/payara/appserver/bin/asadmin --user admin --passwordfile /tmp/pwdfile deploy --force=true --name javaee-app --contextroot / /tmp/app.war"

if %errorlevel% neq 0 (
    echo.
    echo [WARN] Fallo con appserver path, intentando con glassfish path...
    docker exec pac_devcontainer-appserver-1 bash -c "/opt/payara/glassfish/bin/asadmin --user admin --passwordfile /tmp/pwdfile deploy --force=true --name javaee-app --contextroot / /tmp/app.war"
)

echo.
echo [INFO] 6. Verificando logs del servidor...
docker exec pac_devcontainer-appserver-1 tail -50 /opt/payara/appserver/glassfish/domains/domain1/logs/server.log 2>nul

echo.
echo [INFO] 7. Listando aplicaciones desplegadas...
docker exec pac_devcontainer-appserver-1 bash -c "ls -la /opt/payara/appserver/glassfish/domains/domain1/applications/ 2>/dev/null || ls -la /opt/payara/glassfish/domains/domain1/applications/"

echo.
echo [INFO] 8. Esperando 5 segundos...
timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo  VERIFICACION FINAL
echo ========================================
curl -v http://localhost:8080/api/transactions 2>&1 | find "HTTP"

echo.
echo Si ves "HTTP/1.1 200" arriba, funciono!
echo Si ves "HTTP/1.1 404", la app no esta desplegada correctamente.
echo.
