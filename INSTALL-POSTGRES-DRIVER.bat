@echo off
REM Script rapido para instalar el driver PostgreSQL

echo ========================================
echo  INSTALANDO DRIVER POSTGRESQL
echo ========================================
echo.

echo [1/3] Descargando PostgreSQL JDBC driver...
curl -L -o target\postgresql-42.7.1.jar https://jdbc.postgresql.org/download/postgresql-42.7.1.jar

if errorlevel 1 (
    echo [ERROR] No se pudo descargar
    echo.
    echo ALTERNATIVA: Descargalo manualmente desde:
    echo https://jdbc.postgresql.org/download/postgresql-42.7.1.jar
    echo.
    echo Y guardalo en: target\postgresql-42.7.1.jar
    exit /b 1
)

echo [OK] Driver descargado

echo.
echo [2/3] Copiando al contenedor Payara...
docker cp target\postgresql-42.7.1.jar pac_devcontainer-appserver-1:/opt/payara/appserver/glassfish/lib/postgresql-42.7.1.jar

if errorlevel 1 (
    echo [ERROR] No se pudo copiar al contenedor
    exit /b 1
)

echo [OK] Driver instalado en Payara

echo.
echo [3/3] Reiniciando Payara para cargar el driver...
docker restart pac_devcontainer-appserver-1

echo [INFO] Esperando que Payara reinicie (20 segundos)...
timeout /t 20 /nobreak

echo.
echo ========================================
echo  DRIVER INSTALADO
echo ========================================
echo.
echo Ahora ejecuta:
echo   DEPLOY-FINAL.bat
echo.
