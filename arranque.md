# Guía de Arranque: Dashboard Financiero (Setup & Run)

Esta guía describe los pasos exactos para inicializar el entorno y ejecutar la solución completa. Sigue este orden para evitar errores de dependencias o conexión.

---

## 1. Inicio del Entorno (DevContainer)

1.  Abre este proyecto en VS Code.
2.  Si te pregunta, haz clic en **"Reopen in Container"**.
3.  Espera a que termine la instalación (puede tardar unos minutos la primera vez mientras descarga las imágenes de Java, Node y Postgres).

### Verificación
Abre una terminal (`Ctrl + ñ`) y ejecuta:
```bash
docker ps
```
Deberías ver 3 contenedores activos: `app` (donde estás tú), `db` (Postgres) y `sonarqube`.

---

## 2. Configuración de Dependencias

Ejecuta estos comandos en la terminal para preparar Python y dbt:

```bash
# 1. Instalar dependencias de Python (dbt, pandas, driver postgres)
pip install -r requirements.txt

# 2. Configurar dbt para que encuentre el profile
# (Esto le dice a dbt dónde buscar el fichero profiles.yml que hemos creado)
export DBT_PROFILES_DIR=$(pwd)/dbt_project
```

---

## 3. Ejecución de la Solución (Paso a Paso)

Sigue este orden lógico. Si un paso falla, no pases al siguiente.

### Paso A: Base de Datos (Flyway)
Primero creamos las tablas vacías.
```bash
# Ejecuta Flyway usando el CLI de Maven (gracias al pom.xml que generarás)
mvn flyway:migrate
```
*Nota: Si aún no has generado el pom.xml con el Prompt 0.1, hazlo primero.*

### Paso B: Ingesta de Datos (Python)
Cargamos el CSV "sucio" en la tabla `raw_transactions`.
```bash
python etl/ingest_data.py
```

### Paso C: Transformación (dbt)
Limpiamos los datos y rellenamos `fact_transactions`.
```bash
cd dbt_project
dbt debug  # Para verificar conexión (opcional)
dbt run
cd ..
```

### Paso D: Backend (Java EE + Payara)
Arrancamos el servidor de aplicaciones. El fichero `payara-resources.xml` ya configurado conectará automáticamente con la BBDD.
```bash
mvn package payara-micro:start
```
*   El servidor estará listo cuando veas: `Payara Micro ... ready in ... ms`.
*   La API estará disponible en: `http://localhost:8080/transactions`

### Paso E: Frontend (React)
En **otra terminal**, levanta el frontend.
```bash
cd frontend
npm install
npm run dev
```
*   Accede a la web en: `http://localhost:5173`

---

## 4. Troubleshooting (Posibles Errores)

*   **Error: "Connection refused" a Postgres**: Asegúrate de que `docker-compose.yml` ha levantado el servicio `db`. El host debe ser `db`, no `localhost` (dentro de los scripts).
*   **Error: "Profile not found" en dbt**: Asegúrate de haber ejecutado el `export DBT_PROFILES_DIR...` o mueve el fichero `profiles.yml` a `~/.dbt/`.
*   **Error: JPA/Hibernate "Schema validation failed"**: Significa que las tablas no coinciden con la Entity Java. Revisa que los campos en `Transaction.java` coincidan exactamente con `fact_transactions`.

---

## Resumen de URLs
*   **Web App**: http://localhost:5173
*   **API JSON**: http://localhost:8080/transactions
*   **SonarQube**: http://localhost:9000 (admin/admin)
