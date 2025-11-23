@echo off
REM Script para deshabilitar HTTPS en la consola de administracion de Payara
REM Esto permite acceder via HTTP en http://localhost:4848

echo ============================================
echo  DESHABILITANDO SECURE ADMIN EN PAYARA
echo ============================================
echo.
echo [INFO] Esto permitira acceder a la consola de administracion
echo        via HTTP (sin HTTPS) en: http://localhost:4848
echo.

echo [INFO] Verificando estado actual de secure-admin...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin get secure-admin.enabled

echo.
echo [INFO] Deshabilitando secure-admin...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin disable-secure-admin

if errorlevel 1 (
    echo.
    echo [WARN] No se pudo deshabilitar (probablemente ya estaba deshabilitado)
    echo.
) else (
    echo [OK] Secure admin deshabilitado
    echo.
    echo [INFO] Reiniciando el dominio para aplicar cambios...
    docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin restart-domain
    
    if errorlevel 1 (
        echo [ERROR] Error al reiniciar
        exit /b 1
    )
    
    echo [OK] Dominio reiniciado
    echo.
    echo [INFO] Esperando que el servidor inicie...
    timeout /t 15 /nobreak >nul
)

echo.
echo [INFO] Verificando acceso a la consola...
curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://localhost:4848/

echo.
echo ============================================
echo  CONSOLA DE ADMINISTRACION LISTA
echo ============================================
echo.
echo Accede en tu navegador a:
echo   http://localhost:4848
echo.
echo Usuario: admin
echo Password: [vacio - solo presiona ENTER]
echo.
echo Si sigue sin funcionar, verifica:
echo 1. docker ps ^| findstr appserver
echo 2. docker logs pac_devcontainer-appserver-1 --tail 50
echo.
