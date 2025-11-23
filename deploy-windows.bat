@echo off
REM Script para desplegar en Payara Server desde Windows HOST
REM Ejecutar desde la raiz del proyecto (fuera del devcontainer)

echo ============================================
echo  DESPLEGANDO EN PAYARA SERVER FULL
echo ============================================
echo.

REM Verificar que el WAR existe
if not exist "target\javaee-app.war" (
    echo [ERROR] No se encuentra el archivo WAR en target\javaee-app.war
    echo [INFO] Compilando primero...
    docker exec pac_devcontainer-devcontainer-1 bash -c "cd /workspace && mvn package -DskipTests"
    if errorlevel 1 (
        echo [ERROR] Fallo la compilacion
        exit /b 1
    )
)

echo [OK] WAR encontrado
echo.

REM Metodo 1: Intentar con asadmin sin autenticacion (passwordfile vacio)
echo [INFO] Metodo 1: Desplegando con asadmin...
echo.

docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
  --user admin ^
  --passwordfile=/dev/null ^
  deploy ^
  --force=true ^
  --contextroot=/ ^
  --name=javaee-app ^
  /workspace/target/javaee-app.war

if errorlevel 1 (
    echo.
    echo [WARN] Metodo 1 fallo, intentando Metodo 2...
    echo.
    
    REM Metodo 2: Sin usuario (remote=false)
    docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
      deploy ^
      --force=true ^
      --contextroot=/ ^
      --name=javaee-app ^
      /workspace/target/javaee-app.war
    
    if errorlevel 1 (
        echo.
        echo [WARN] Metodo 2 fallo, intentando Metodo 3...
        echo.
        
        REM Metodo 3: Habilitar secure admin primero
        echo [INFO] Deshabilitando autenticacion segura...
        docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
          --user admin ^
          --passwordfile=/dev/null ^
          disable-secure-admin
        
        REM Reiniciar el dominio
        echo [INFO] Reiniciando dominio...
        docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin stop-domain
        timeout /t 3 /nobreak >nul
        docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin start-domain
        timeout /t 10 /nobreak >nul
        
        REM Intentar desplegar nuevamente
        echo [INFO] Desplegando nuevamente...
        docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin ^
          deploy ^
          --force=true ^
          --contextroot=/ ^
          --name=javaee-app ^
          /workspace/target/javaee-app.war
        
        if errorlevel 1 (
            echo.
            echo [ERROR] Todos los metodos fallaron
            echo.
            echo SOLUCION ALTERNATIVA:
            echo 1. Copiar WAR al autodeploy:
            echo    docker cp target\javaee-app.war pac_devcontainer-appserver-1:/opt/payara/glassfish/domains/domain1/autodeploy/
            echo.
            echo 2. O entrar al contenedor y desplegar manualmente:
            echo    docker exec -it pac_devcontainer-appserver-1 bash
            echo    /opt/payara/bin/asadmin deploy --force /workspace/target/javaee-app.war
            exit /b 1
        )
    )
)

echo.
echo ============================================
echo  DESPLIEGUE COMPLETADO
echo ============================================
echo.
echo Esperando que la aplicacion inicie...
timeout /t 8 /nobreak >nul

echo.
echo Verificando despliegue...
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin list-applications

echo.
echo ============================================
echo  ENDPOINTS DISPONIBLES
echo ============================================
echo  http://localhost:8080/api/transactions
echo  http://localhost:8080/api/transactions/suspicious
echo ============================================
echo.

echo Probando endpoint...
curl -s http://localhost:8080/api/transactions

echo.
echo [OK] Listo!
