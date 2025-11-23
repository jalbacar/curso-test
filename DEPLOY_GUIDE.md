# 📦 Guía de Despliegue en Payara Server Full Edition

## ✅ Pre-requisitos

La aplicación ya está compilada:
- **WAR File**: `/workspace/target/javaee-app.war` (1.2 MB)
- **Payara Server**: Corriendo en el contenedor `appserver` (puerto 8080 y 4848)

---

## 🚀 Método 1: Despliegue usando asadmin (RECOMENDADO)

### Desde tu terminal HOST (fuera del devcontainer):

```bash
# 1. Desplegar la aplicación con asadmin
docker exec appserver /opt/payara/bin/asadmin deploy \
  --force=true \
  --contextroot=/ \
  --name=javaee-app \
  /workspace/target/javaee-app.war
```

### Verificar el despliegue:

```bash
# 2. Listar aplicaciones desplegadas
docker exec appserver /opt/payara/bin/asadmin list-applications

# 3. Probar el endpoint
curl http://localhost:8080/api/transactions | python -m json.tool
```

---

## 🔄 Método 2: Despliegue por Autodeploy

### Copiar WAR al directorio autodeploy:

```bash
# 1. Copiar WAR al directorio autodeploy de Payara
docker cp /ruta/al/proyecto/target/javaee-app.war \
  appserver:/opt/payara/glassfish/domains/domain1/autodeploy/

# 2. Esperar unos segundos y verificar
sleep 10
curl http://localhost:8080/api/transactions
```

---

## 🔧 Método 3: Usando el volumen compartido

Si el volumen está correctamente montado en docker-compose:

```bash
# El WAR ya debería estar accesible en /workspace dentro de appserver
docker exec appserver ls -lh /workspace/target/javaee-app.war

# Desplegar desde allí
docker exec appserver /opt/payara/bin/asadmin deploy \
  --force=true \
  --contextroot=/ \
  /workspace/target/javaee-app.war
```

---

## 🩺 Troubleshooting

### Ver logs en tiempo real:

```bash
docker logs -f appserver
```

O ver el log del servidor directamente:

```bash
docker exec -it appserver tail -f \
  /opt/payara/glassfish/domains/domain1/logs/server.log
```

### Verificar el DataSource:

```bash
docker exec appserver /opt/payara/bin/asadmin list-jdbc-resources
docker exec appserver /opt/payara/bin/asadmin list-jdbc-connection-pools
```

### Ping al DataSource:

```bash
docker exec appserver /opt/payara/bin/asadmin ping-connection-pool financialPool
```

### Undeployar aplicación:

```bash
docker exec appserver /opt/payara/bin/asadmin undeploy javaee-app
```

### Reiniciar Payara Server:

```bash
docker restart appserver
```

### Ver información del servidor:

```bash
docker exec appserver /opt/payara/bin/asadmin version
docker exec appserver /opt/payara/bin/asadmin list-domains
```

---

## 🌐 Endpoints de la Aplicación

Una vez desplegada, los endpoints estarán disponibles en:

| Endpoint | Descripción |
|----------|-------------|
| `http://localhost:8080/api/transactions` | Listar todas las transacciones |
| `http://localhost:8080/api/transactions/suspicious` | Transacciones sospechosas |
| `http://localhost:8080/api/transactions/{id}` | Obtener transacción por ID |

### Ejemplos de uso:

```bash
# Listar todas las transacciones
curl http://localhost:8080/api/transactions

# Obtener transacciones sospechosas
curl http://localhost:8080/api/transactions/suspicious

# Obtener transacción específica
curl http://localhost:8080/api/transactions/1

# Crear nueva transacción (POST)
curl -X POST http://localhost:8080/api/transactions \
  -H "Content-Type: application/json" \
  -d '{
    "transactionDate": "2024-01-15",
    "amount": 150.50,
    "description": "Compra en supermercado",
    "category": "groceries",
    "suspicious": false
  }'
```

---

## 📊 Consola de Administración

Accede a la consola de administración de Payara:

- **URL**: http://localhost:4848
- **Usuario**: admin (sin password por defecto)

---

## 🐛 Problemas Comunes

### 1. Error 404 - Aplicación no encontrada

**Solución**: Verifica que la aplicación esté desplegada:
```bash
docker exec appserver /opt/payara/bin/asadmin list-applications
```

### 2. Error de DataSource

**Solución**: Verifica que el post-boot-commands se haya ejecutado:
```bash
docker exec appserver /opt/payara/bin/asadmin list-jdbc-resources
# Debería mostrar: jdbc/financialPool
```

Si no aparece, ejecuta manualmente:
```bash
docker exec appserver /opt/payara/bin/asadmin create-jdbc-connection-pool \
  --datasourceclassname org.postgresql.ds.PGSimpleDataSource \
  --restype javax.sql.DataSource \
  --property serverName=database:portNumber=5432:databaseName=curso_db:user=curso_user:password=curso_pass \
  financialPool

docker exec appserver /opt/payara/bin/asadmin create-jdbc-resource \
  --connectionpoolid financialPool \
  jdbc/financialPool
```

### 3. Error de conexión a PostgreSQL

**Solución**: Verifica que el contenedor database esté corriendo:
```bash
docker ps | grep database
```

Prueba la conexión:
```bash
docker exec database psql -U curso_user -d curso_db -c "SELECT version();"
```

### 4. Aplicación desplegada pero no responde

**Solución**: Revisa los logs para errores de JPA o persistencia:
```bash
docker logs appserver 2>&1 | grep -E "(ERROR|Exception|persistence)"
```

---

## 🔄 Script de Redeploy Rápido

Guarda esto como `redeploy.sh` en tu máquina HOST:

```bash
#!/bin/bash
# Script para redesplegar rápidamente desde el HOST

echo "🔄 Recompilando..."
docker exec devcontainer bash -c "cd /workspace && mvn package -DskipTests"

echo "🗑️  Undeploy anterior..."
docker exec appserver /opt/payara/bin/asadmin undeploy javaee-app 2>/dev/null || true

echo "📤 Desplegando..."
docker exec appserver /opt/payara/bin/asadmin deploy \
  --force=true \
  --contextroot=/ \
  /workspace/target/javaee-app.war

echo "⏳ Esperando..."
sleep 5

echo "🧪 Probando..."
curl http://localhost:8080/api/transactions | python -m json.tool

echo "✅ Listo!"
```

Hazlo ejecutable:
```bash
chmod +x redeploy.sh
./redeploy.sh
```

---

## 📝 Notas Adicionales

- El WAR se compila en `/workspace/target/javaee-app.war`
- El datasource configurado es `jdbc/financialPool`
- La persistence unit se llama `primary`
- PostgreSQL corre en `database:5432`
- Base de datos: `curso_db`, usuario: `curso_user`, password: `curso_pass`
