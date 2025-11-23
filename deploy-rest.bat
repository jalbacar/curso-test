@echo off
REM Script definitivo usando API REST de Payara

echo ========================================
echo  Desplegando via API REST de Payara
echo ========================================
echo.

if not exist "target\javaee-app.war" (
    echo [ERROR] No se encuentra el archivo WAR
    exit /b 1
)

echo [INFO] WAR encontrado: target\javaee-app.war
echo.

REM Primero, desplegar una aplicación vacia si existe
echo [INFO] Eliminando aplicacion anterior si existe...
curl -X DELETE "http://localhost:4848/management/domain/applications/application/javaee-app" 2>nul

echo.
echo [INFO] Desplegando aplicacion via API REST...

REM Usar curl para subir el WAR via REST API
curl -X POST ^
  -H "X-Requested-By: GlassFish REST HTML interface" ^
  -F "id=javaee-app" ^
  -F "force=true" ^
  -F "contextroot=/" ^
  -F "enabled=true" ^
  -F "DEFAULT=@target/javaee-app.war" ^
  "http://localhost:4848/management/domain/applications/application"

echo.
echo.
echo [INFO] Esperando que el servidor procese el despliegue...
timeout /t 10 /nobreak >nul

echo.
echo ========================================
echo  Verificando despliegue
echo ========================================

REM Verificar aplicaciones desplegadas
echo [INFO] Aplicaciones desplegadas:
curl -s "http://localhost:4848/management/domain/applications/application" 2>nul

echo.
echo.
echo [INFO] Probando endpoint...
curl -s http://localhost:8080/api/transactions 2>nul

if %errorlevel% equ 0 (
    echo.
    echo.
    echo ========================================
    echo  ^Despliegue Exitoso!
    echo ========================================
    echo.
    echo Endpoints disponibles:
    echo   - http://localhost:8080/api/transactions
    echo   - http://localhost:8080/api/transactions/suspicious
    echo   - http://localhost:8080/api/transactions/stats
) else (
    echo.
    echo [ERROR] La aplicacion no responde
    echo Verifica los logs del servidor
)

echo.
