# Estrategia de Prompts para "Dashboard Financiero" (Java EE + React)

Este documento contiene la **secuencia de prompts** diseñada para que los alumnos construyan la aplicación paso a paso utilizando GitHub Copilot. La solución utiliza:
*   **Backend**: Java EE (Jakarta EE 8) sobre Payara Micro.
*   **Frontend**: React 19 + Vite + TailwindCSS.
*   **Data**: Postgres, Python (Ingesta), dbt (Transformación).
*   **DevOps**: Flyway, GitHub Actions, SonarQube.

---

## Fase 0: Configuración Inicial (Scaffolding)

### Prompt 0.1: Estructura del Proyecto Java
> **Contexto**: Workspace raíz.
> **Prompt**: "Genera un archivo `pom.xml` para una aplicación Java EE 8 con soporte para Payara Micro, JUnit 5, Mockito y el driver de PostgreSQL. Incluye los plugins maven-compiler-plugin (Java 11 o 17) y payara-micro-maven-plugin. La estructura de directorios debe seguir el estándar Maven."

**✅ Verificación:**
```bash
mvn validate
# Debe mostrar "BUILD SUCCESS" sin errores de dependencias
```

### Prompt 0.2: Estructura del Proyecto React (Vite)
> **Contexto**: Terminal.
> **Prompt**: "Dame el comando para crear una nueva aplicación React con TypeScript usando Vite en una carpeta llamada `frontend`. También dame los comandos para instalar TailwindCSS y configurarlo."

---

## Fase 1: Capa de Datos (Ingesta y Transformación)

### Prompt 1.1: Migración Inicial (Flyway)
> **Contexto**: Archivo `src/main/resources/db/migration/V1__init_transactions.sql` (créalo vacío).
> **Prompt**: "Genera un script SQL para PostgreSQL que cree dos tablas:
> 1. `raw_transactions`: id (serial), csv_line (text), created_at (timestamp).
> 2. `fact_transactions`: id (serial), transaction_date (date), amount (decimal), description (text), category (varchar), is_suspicious (boolean).
> Añade comentarios explicando cada campo."

**✅ Verificación:**
```bash
mvn flyway:migrate
# Luego verifica las tablas creadas:
psql -h db -U postgres -d financial_db -c "\dt"
# Debe mostrar: raw_transactions y fact_transactions
psql -h db -U postgres -d financial_db -c "\d fact_transactions"
# Debe mostrar la estructura completa con los 6 campos
```

### Prompt 1.2: Script de Ingesta (Python)
> **Contexto**: Archivo `etl/ingest_data.py`.
> **Prompt**: "Crea un script de Python que lea un archivo CSV corrupto (simulado) llamado `transactions.csv`. El script debe:
> 1. Conectarse a PostgreSQL usando `psycopg2` (usa variables de entorno para credenciales).
> 2. Leer el CSV línea por línea.
> 3. Insertar cada línea tal cual en la tabla `raw_transactions`.
> 4. Incluir manejo de errores y logging.
> 5. Generar docstrings para todas las funciones."

**✅ Verificación:**
```bash
export PGHOST=db PGUSER=postgres PGPASSWORD=password PGDATABASE=financial_db
python etl/ingest_data.py
# Verifica que los datos se insertaron:
psql -h db -U postgres -d financial_db -c "SELECT COUNT(*) FROM raw_transactions;"
# Debe mostrar el número de líneas del CSV (ej: 9)
```

### Prompt 1.3: Transformación con dbt
> **Contexto**: Carpeta `dbt_project/models`.
> **Prompt**: "Genera un modelo SQL de dbt llamado `stg_transactions.sql` que limpie los datos de `raw_transactions`.
> 1. Lógica: Parsea el CSV, filtra nulos y categoriza gastos.
> 2. **Importante**: Genera también el archivo `schema.yml` definiendo tests básicos (`unique`, `not_null`) para las columnas `id` y `amount`."

**✅ Verificación:**
```bash
cd dbt_project
dbt run
# Debe ejecutar el modelo stg_transactions sin errores
dbt test
# Debe pasar los tests de unique y not_null
psql -h db -U postgres -d financial_db -c "SELECT COUNT(*) FROM fact_transactions;"
# Debe mostrar transacciones limpias (menos que raw si hubo filtrado)
```

---

## Fase 2: Backend (Java EE / Jakarta EE)

### Prompt 2.1: Entidad JPA
> **Contexto**: Archivo `src/main/java/com/pac/model/Transaction.java`.
> **Prompt**: "Genera una entidad JPA llamada `Transaction` que mapee a la tabla `fact_transactions`. Usa anotaciones de `javax.persistence`. Incluye Lombok @Data si es posible, o genera getters y setters. Asegúrate de mapear `is_suspicious` correctamente."

**✅ Verificación:**
```bash
mvn compile
# Debe compilar sin errores. Verifica que el mapeo coincide:
grep -A 5 "@Table" src/main/java/com/pac/model/Transaction.java
# Debe mostrar @Table(name="fact_transactions")
```

### Prompt 2.2: Repositorio / DAO
> **Contexto**: Archivo `src/main/java/com/pac/repository/TransactionRepository.java`.
> **Prompt**: "Crea una clase Repository stateless (`@Stateless`) para `Transaction`. Implementa un método `findAll` usando JPQL y un método `findSuspicious` que devuelva transacciones con flag sospechoso. Usa `EntityManager`."

**✅ Verificación:**
```bash
mvn compile
# Verifica que usa EntityManager correctamente:
grep "@PersistenceContext" src/main/java/com/pac/repository/TransactionRepository.java
```

### Prompt 2.3: Servicio REST (JAX-RS)
> **Contexto**: Archivo `src/main/java/com/pac/resource/TransactionResource.java`.
> **Prompt**: "Crea un recurso REST JAX-RS (`@Path('/transactions')`) que inyecte `TransactionRepository`. Expon dos endpoints GET: uno para listar todas y otro para filtrar las sospechosas. Devuelve respuestas en formato JSON (`@Produces(MediaType.APPLICATION_JSON)`). **IMPORTANTE**: Añade la anotación `@CrossOrigin` o configura CORS para permitir peticiones desde http://localhost:5173. Gestiona posibles excepciones con `Response.serverError()`."

**✅ Verificación:**
```bash
mvn package payara-micro:start
# Espera a que arranque, luego en otra terminal:
curl http://localhost:8080/transactions
# Debe devolver un JSON con el array de transacciones
curl http://localhost:8080/transactions/suspicious
# Debe devolver solo las transacciones con is_suspicious=true
```

### Prompt 2.4: Refactorización SonarQube (Calidad)
> **Contexto**: Archivo `src/main/java/com/pac/resource/TransactionResource.java`.
> **Prompt**: "Actúa como un experto en SonarQube. Analiza el código de `TransactionResource` y `TransactionRepository`:
> 1. Identifica posibles 'Code Smells' (ej. inyección de dependencias por campo vs constructor, manejo de excepciones genéricas).
> 2. Reescribe el código aplicando las correcciones para cumplir con 'Clean Code'."

**✅ Verificación:**
```bash
mvn sonar:sonar -Dsonar.host.url=http://localhost:9000
# Accede a http://localhost:9000 y verifica que no hay Code Smells críticos
# O simplemente revisa manualmente que usa constructor injection
```

---

## Fase 3: Frontend (React + Vite)

### Prompt 3.1: Modelo y Servicio
> **Contexto**: Archivo `frontend/src/services/api.ts`.
> **Prompt**: "Crea una interfaz TypeScript `Transaction` que coincida con el JSON del backend (id, transaction_date, amount, description, category, is_suspicious). Luego, crea una función `fetchTransactions` usando `fetch` que llame al endpoint `http://localhost:8080/transactions` y devuelva una promesa tipada. Incluye manejo de errores."

**✅ Verificación:**
```bash
cd frontend
npm run build
# Debe compilar sin errores de TypeScript
# Verifica que la interfaz tiene todos los campos:
grep -A 6 "interface Transaction" src/services/api.ts
```

### Prompt 3.2: Componente de Tabla
> **Contexto**: Archivo `frontend/src/components/TransactionTable.tsx`.
> **Prompt**: "Crea un componente React que reciba un array de `Transaction`. Renderiza una tabla moderna usando clases de TailwindCSS.
> **Requisito clave**: Si `amount` es mayor a 1000 o `is_suspicious` es true, resalta la fila en rojo suave. Si es un ingreso (positivo), en verde suave."

**✅ Verificación:**
```bash
cd frontend
npm run dev
# El servidor arranca en http://localhost:5173
# Abre el navegador en tu HOST (fuera del contenedor) y accede a esa URL
# Verifica visualmente:
# - Transacciones > 1000 o sospechosas deben estar en rojo
# - Ingresos positivos en verde
```

### Prompt 3.3: Dashboard Principal
> **Contexto**: Archivo `frontend/src/App.tsx`.
> **Prompt**: "Modifica App.tsx para que use `useEffect` y cargue las transacciones usando el servicio `api.ts`. Muestra un estado de 'Cargando...' mientras espera, y renderiza `TransactionTable` cuando lleguen los datos. Maneja errores de red mostrando un mensaje de alerta."

**✅ Verificación:**
```bash
# Con el backend corriendo (mvn payara-micro:start):
cd frontend
npm run dev
# Abre http://localhost:5173 en tu navegador (HOST) y verifica:
# 1. Aparece "Cargando..." brevemente
# 2. Se muestra la tabla con datos del backend
# 3. Si detienes el backend, debe mostrar error
```

### Prompt 3.4: Verificación de Conectividad Frontend-Backend
> **Contexto**: Terminal dentro del DevContainer.
> **Prompt**: "Dame un comando curl para verificar que el backend está respondiendo correctamente con datos JSON. También dame un snippet de código JavaScript que pueda ejecutar en la consola del navegador para probar la conectividad desde el frontend."

**✅ Verificación:**
```bash
# Desde el terminal del DevContainer:
curl -v http://localhost:8080/transactions
# Debe devolver:
# - HTTP 200 OK
# - Content-Type: application/json
# - Array de transacciones en formato JSON

# Desde la consola del navegador (F12 > Console):
fetch('http://localhost:8080/transactions')
  .then(r => r.json())
  .then(data => console.log('✅ Conectado:', data))
  .catch(err => console.error('❌ Error CORS o conexión:', err));
# Debe mostrar "✅ Conectado:" seguido del array de transacciones
# Si muestra error CORS, revisa el Prompt 2.3 (configuración CORS en el backend)
```

---

## Fase 4: Calidad y Testing Automatizado

### Prompt 4.1: Tests Unitarios Backend (JUnit 5 + Mockito)
> **Contexto**: Archivo `src/test/java/com/pac/repository/TransactionRepositoryTest.java`.
> **Prompt**: "Genera una clase de test para `TransactionRepository` usando JUnit 5 y Mockito.
> 1. Mockea el `EntityManager`.
> 2. Crea un test `testFindSuspicious` que verifique que se llama a `createNamedQuery` con los parámetros correctos.
> 3. Crea un test para verificar el manejo de una lista vacía."

**✅ Verificación:**
```bash
mvn test
# Debe mostrar "Tests run: X, Failures: 0, Errors: 0"
# Verifica que el test específico pasó:
mvn test -Dtest=TransactionRepositoryTest
```

### Prompt 4.2: Tests de Componentes Frontend (Vitest/Jest)
> **Contexto**: Archivo `src/components/TransactionTable.test.tsx`.
> **Prompt**: "Genera un test para el componente `TransactionTable` usando React Testing Library.
> 1. Verifica que la tabla se renderiza correctamente con una lista de datos simulada.
> 2. Comprueba que las filas con `is_suspicious: true` tienen la clase CSS de color rojo (o el estilo correspondiente).
> 3. Verifica que se muestra un mensaje de 'No hay datos' si la lista está vacía."

**✅ Verificación:**
```bash
cd frontend
npm run test
# Debe mostrar "Test Suites: 1 passed" (o similar)
# Verifica que los 3 tests pasaron
```

### Prompt 4.3: Workflow de GitHub Actions (CI/CD)
> **Contexto**: Archivo `.github/workflows/ci.yml`.
> **Prompt**: "Crea un workflow de GitHub Actions que se ejecute en `push` a `main`. Pasos:
> 1. Checkout del código.
> 2. Setup de Java 17 y Node 18.
> 3. Ejecutar `mvn test` para el backend.
> 4. Ejecutar `npm install` y `npm run test` para el frontend.
> 5. (Opcional) Ejecutar análisis de SonarQube usando el plugin de Maven."

**✅ Verificación:**
```bash
git add .github/workflows/ci.yml
git commit -m "Add CI workflow"
git push origin main
# Ve a GitHub Actions y verifica que el workflow se ejecuta sin errores
# O valida localmente con: act (si tienes act instalado)
```

---

## Fase 5: Automatización Avanzada

### Prompt 5.1: Generación de Documentación Automática
> **Contexto**: Archivo `dbt_project/schema.yml` (y/o terminal).
> **Prompt**: "Ayúdame a generar la documentación de los modelos dbt.
> 1. Genera un bloque de configuración en `schema.yml` para `fact_transactions` que incluya descripciones para cada columna.
> 2. Dame el comando para generar el sitio estático de documentación de dbt (`dbt docs generate`)."

**✅ Verificación:**
```bash
cd dbt_project
dbt docs generate
dbt docs serve
# Abre http://localhost:8080 en tu navegador (HOST) y verifica la documentación
# Debe mostrar fact_transactions con descripciones de columnas
```

### Prompt 5.2: Script de Orquestación (Deploy)
> **Contexto**: Archivo `scripts/deploy_local.sh`.
> **Prompt**: "Crea un script de Bash robusto para levantar todo el entorno localmente.
> El script debe:
> 1. Esperar a que Postgres esté listo (usando `pg_isready` o un bucle con sleep).
> 2. Ejecutar migraciones de Flyway (`mvn flyway:migrate`).
> 3. Ejecutar la ingesta de Python.
> 4. Ejecutar transformaciones de dbt.
> 5. Iniciar Payara Micro en segundo plano.
> 6. Mostrar logs de colores indicando éxito o fallo en cada paso."

**✅ Verificación:**
```bash
chmod +x scripts/deploy_local.sh
./scripts/deploy_local.sh
# Debe ejecutar todos los pasos en orden y mostrar mensajes de éxito
# Al final, verifica que el backend responde:
curl http://localhost:8080/transactions
```

### Prompt 5.3: Documentación de Código (Javadoc & Storybook)
> **Contexto**: Archivo `src/main/java/com/pac/resource/TransactionResource.java` o componentes React.
> **Prompt**: "Mejora la documentación del proyecto:
> 1. Para Java: Genera Javadoc para la clase `TransactionResource` y sus métodos, explicando los códigos de respuesta HTTP y el formato JSON de retorno.
> 2. Para React: Genera comentarios JSDoc para el componente `TransactionTable`, describiendo las props que recibe y la lógica de visualización (colores condicionales)."

**✅ Verificación:**
```bash
# Para Java:
mvn javadoc:javadoc
# Abre en tu navegador (HOST): file:///<ruta-workspace>/target/site/apidocs/index.html
# O simplemente verifica que se generó:
ls -la target/site/apidocs/index.html

# Para React:
grep -A 3 "/**" frontend/src/components/TransactionTable.tsx
# Debe mostrar los comentarios JSDoc