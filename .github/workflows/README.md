# GitHub Actions CI/CD

Este proyecto utiliza GitHub Actions para ejecutar automáticamente tests y análisis de código.

## 📋 Workflow CI Pipeline

El workflow se ejecuta automáticamente en:
- **Push** a la rama `main`
- **Pull Requests** hacia `main`

### Jobs del Pipeline

#### 1️⃣ Backend Tests (Java 11)
**Servicios:**
- PostgreSQL 15 (container de pruebas)

**Pasos:**
1. Checkout del código
2. Setup de Java 11 (Temurin)
3. Ejecución de migraciones Flyway
4. Ejecución de tests con Maven (`mvn test`)
5. Generación de reporte de cobertura JaCoCo
6. Upload de resultados y cobertura como artifacts

**Artefactos generados:**
- `backend-test-results` - Reportes de Surefire
- `backend-coverage` - Reporte de cobertura JaCoCo

#### 2️⃣ Frontend Tests (Node 18)
**Pasos:**
1. Checkout del código
2. Setup de Node.js 18
3. Instalación de dependencias (`npm ci`)
4. Linting con ESLint
5. Ejecución de tests con Vitest
6. Build de producción
7. Upload de build y resultados como artifacts

**Artefactos generados:**
- `frontend-build` - Build de producción (dist/)
- `frontend-test-results` - Cobertura de tests

#### 3️⃣ SonarQube Analysis (Opcional)
**Condiciones:**
- Solo se ejecuta en push a `main`
- Requiere que backend y frontend tests pasen exitosamente

**Requisitos:**
Configurar los siguientes secrets en GitHub:
- `SONAR_HOST_URL` - URL del servidor SonarQube
- `SONAR_TOKEN` - Token de autenticación de SonarQube

**Comando:**
```bash
mvn clean verify sonar:sonar \
  -Dsonar.projectKey=financial-transactions \
  -Dsonar.projectName="Financial Transactions App" \
  -Dsonar.host.url=$SONAR_HOST_URL \
  -Dsonar.token=$SONAR_TOKEN
```

#### 4️⃣ Build Summary
Genera un resumen con el estado de todos los jobs.

## 🔧 Configuración de Secrets

Para que el workflow funcione completamente, configura estos secrets en:
**Settings → Secrets and variables → Actions**

| Secret | Descripción | Requerido |
|--------|-------------|-----------|
| `SONAR_HOST_URL` | URL del servidor SonarQube (ej: http://sonarqube:9000) | ⚠️ Solo para análisis SonarQube |
| `SONAR_TOKEN` | Token de autenticación SonarQube | ⚠️ Solo para análisis SonarQube |

### Generar Token de SonarQube

1. Accede a tu instancia de SonarQube
2. Ve a **My Account → Security → Generate Tokens**
3. Crea un token con permisos de análisis
4. Copia el token y agrégalo como secret en GitHub

## 📊 Visualización de Resultados

### GitHub Actions
Los resultados se pueden ver en:
- **Actions** tab del repositorio
- Cada commit/PR muestra el estado del workflow

### Artifacts
Los artifacts están disponibles por 90 días:
1. Ve al workflow ejecutado
2. Sección **Artifacts** al final de la página
3. Descarga los reportes que necesites

### SonarQube
Si está configurado:
1. Accede a la URL de SonarQube
2. Busca el proyecto `financial-transactions`
3. Revisa métricas de calidad, cobertura y vulnerabilidades

## 🚀 Ejecución Local

### Backend Tests
```bash
mvn test
```

### Frontend Tests
```bash
cd frontend
npm test
```

### SonarQube Local
```bash
mvn clean verify sonar:sonar \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=YOUR_TOKEN
```

## 🔍 Troubleshooting

### ❌ Backend tests fallan
- Verificar que PostgreSQL service está corriendo
- Revisar logs de Flyway migrations
- Comprobar configuración de base de datos

### ❌ Frontend tests fallan
- Verificar que `package-lock.json` está committeado
- Limpiar node_modules: `npm ci`
- Revisar compatibilidad de versiones de Node

### ❌ SonarQube analysis falla
- Verificar que `SONAR_HOST_URL` y `SONAR_TOKEN` están configurados
- Comprobar conectividad al servidor SonarQube
- Revisar permisos del token

### ⚠️ Cache issues
Limpiar caches de GitHub Actions:
1. Settings → Actions → Caches
2. Eliminar caches antiguas

## 📝 Mantenimiento

### Actualizar versiones
Para actualizar las versiones de Java/Node:

1. Modificar `.github/workflows/ci.yml`
2. Cambiar `java-version` o `node-version`
3. Actualizar `pom.xml` y `package.json` si es necesario

### Modificar triggers
Para ejecutar en más ramas:

```yaml
on:
  push:
    branches:
      - main
      - develop
      - 'release/**'
```

### Agregar más jobs
Ejemplo para agregar deploy:

```yaml
deploy:
  name: Deploy to Production
  runs-on: ubuntu-latest
  needs: [backend-tests, frontend-tests]
  if: github.ref == 'refs/heads/main'
  steps:
    - name: Deploy
      run: echo "Deploy steps here"
```

## 🎯 Best Practices

✅ **DO:**
- Usar `npm ci` en lugar de `npm install` para builds reproducibles
- Cachear dependencias (Maven, npm) para builds más rápidos
- Usar `continue-on-error: true` para steps opcionales
- Generar artifacts de test results para debugging

❌ **DON'T:**
- Commitear secrets o tokens
- Ejecutar tests de integración pesados en cada commit
- Ignorar warnings de seguridad
- Usar `latest` para versiones de actions

## 📚 Referencias

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Maven GitHub Actions Guide](https://docs.github.com/en/actions/guides/building-and-testing-java-with-maven)
- [Node.js GitHub Actions Guide](https://docs.github.com/en/actions/guides/building-and-testing-nodejs)
- [SonarQube Scanner for Maven](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-maven/)
