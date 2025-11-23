@echo off
REM Script para desplegar la aplicación en Payara Server desde Windows
REM Ejecutar este archivo desde el directorio raíz del proyecto

echo ========================================
echo  Desplegando en Payara Server Full
echo ========================================
echo.

REM Verificar si el WAR existe
if not exist "target\javaee-app.war" (
    echo [ERROR] No se encuentra el archivo WAR
    echo Por favor, compila primero con: mvn package
    exit /b 1
)

echo [INFO] WAR encontrado: target\javaee-app.war
echo.

REM Desplegar usando asadmin (Payara Server Full)
echo [INFO] Desplegando aplicación...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin deploy --force=true /workspace/target/javaee-app.war

REM Si falla con la ruta de Server Full, intentar con la ruta alternativa
if not %errorlevel% equ 0 (
    echo [WARN] Intento 1 falló, probando ruta alternativa...
    docker exec pac_devcontainer-appserver-1 /opt/payara/glassfish/bin/asadmin deploy --force=true /workspace/target/javaee-app.war
)

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo  Despliegue Exitoso!
    echo ========================================
    echo.
    echo Endpoints disponibles:
    echo   - http://localhost:8080/api/transactions
    echo   - http://localhost:8080/api/transactions/suspicious
    echo   - http://localhost:8080/api/transactions/high-value
    echo   - http://localhost:8080/api/transactions/stats
    echo.
    echo Probando endpoint...
    timeout /t 3 /nobreak >nul
    curl -s http://localhost:8080/api/transactions
    echo.
) else (
    echo.
    echo [ERROR] Fallo el despliegue
    echo Verifica que el contenedor appserver este corriendo
    exit /b 1
)
