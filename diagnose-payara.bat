@echo off
REM Script de diagnostico para la consola de administracion de Payara

echo ============================================
echo  DIAGNOSTICO DE PAYARA ADMIN CONSOLE
echo ============================================
echo.

echo [1] Verificando contenedor appserver...
docker ps | findstr appserver
if errorlevel 1 (
    echo [ERROR] El contenedor appserver no esta corriendo
    echo [FIX] Ejecuta: docker-compose -f .devcontainer/docker-compose.yml up -d appserver
    exit /b 1
)
echo [OK] Contenedor corriendo
echo.

echo [2] Verificando puerto 4848...
curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://localhost:4848/
echo.

echo [3] Verificando secure-admin...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin get secure-admin.enabled 2>nul
if errorlevel 1 (
    echo [WARN] No se pudo verificar secure-admin
)
echo.

echo [4] Verificando estado del dominio...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin list-domains 2>nul
echo.

echo [5] Verificando aplicaciones desplegadas...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin list-applications 2>nul
echo.

echo [6] Probando acceso HTTPS...
curl -k -s -o nul -w "HTTPS Status: %%{http_code}\n" https://localhost:4848/
echo.

echo [7] Verificando logs recientes...
echo Ultimas 10 lineas del log:
docker logs pac_devcontainer-appserver-1 --tail 10
echo.

echo ============================================
echo  SOLUCIONES SUGERIDAS
echo ============================================
echo.
echo Si ves HTTP 302:
echo   - El servidor redirige a HTTPS
echo   - Solucion: fix-admin-console.bat
echo.
echo Si ves HTTP 404:
echo   - La consola no esta disponible
echo   - Solucion: Reiniciar contenedor
echo.
echo Si no accedes por navegador:
echo   - Certificado autofirmado rechazado
echo   - Solucion: Usar http://localhost:4848 despues de fix-admin-console.bat
echo.
echo Si ves "Connection refused":
echo   - Payara no esta escuchando en 4848
echo   - Solucion: docker restart pac_devcontainer-appserver-1
echo.
