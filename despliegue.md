# Guía de Despliegue - Dashboard Financiero

Esta guía te ayudará a **poner en marcha la aplicación completa** después de haber aplicado los 19 prompts, y a **desplegarla en GitHub Pages** (frontend) y un servidor compatible con Java EE (backend).

---

## 📋 Prerequisitos

Antes de comenzar, asegúrate de haber completado:
- ✅ Los 19 prompts de `prompts.md`
- ✅ Todas las verificaciones han pasado correctamente
- ✅ El DevContainer está funcionando
- ✅ Tienes VS Code con la extensión "Dev Containers" instalada

---

## 🏗️ Entendiendo el Entorno DevContainer

Antes de empezar, es importante entender cómo funciona el DevContainer:

### Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│  TU MÁQUINA (Windows HOST)                              │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  VS Code (Editor)                              │    │
│  │  - Archivos del proyecto en: D:\Docs\...      │    │
│  │  - Navegador web (Chrome/Edge/Firefox)        │    │
│  └────────────────────────────────────────────────┘    │
│                         ↕                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Docker Desktop                                │    │
│  │                                                 │    │
│  │  ┌──────────────────────────────────────────┐ │    │
│  │  │ DevContainer (app)                       │ │    │
│  │  │ - Java 17, Maven, Node.js, Python, dbt  │ │    │
│  │  │ - Terminal: aquí ejecutas comandos       │ │    │
│  │  │ - Puerto 8080 → HOST:8080                │ │    │
│  │  │ - Puerto 5173 → HOST:5173                │ │    │
│  │  └──────────────────────────────────────────┘ │    │
│  │                                                 │    │
│  │  ┌──────────────────────────────────────────┐ │    │
│  │  │ PostgreSQL (db)                          │ │    │
│  │  │ - Puerto 5432 → HOST:5432                │ │    │
│  │  └──────────────────────────────────────────┘ │    │
│  │                                                 │    │
│  │  ┌──────────────────────────────────────────┐ │    │
│  │  │ SonarQube                                │ │    │
│  │  │ - Puerto 9000 → HOST:9000                │ │    │
│  │  └──────────────────────────────────────────┘ │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### ¿Dónde ejecuto cada cosa?

| Acción | Dónde | Cómo |
|--------|-------|------|
| **Comandos de desarrollo** (`mvn`, `npm`, `python`, `dbt`, `psql`) | 🐳 **DevContainer** | Terminal de VS Code (Ctrl+`) |
| **Editar archivos** | 💻 **HOST (Windows)** | VS Code (los archivos están sincronizados) |
| **Abrir navegador** | 💻 **HOST (Windows)** | Chrome/Edge/Firefox en Windows |
| **Comandos Git** | 🐳 **DevContainer** o 💻 **HOST** | Ambos funcionan (recomendado: DevContainer) |
| **Ver logs del backend** | 🐳 **DevContainer** | Terminal donde ejecutaste `mvn payara-micro:start` |
| **Acceder a la app** | 💻 **HOST (Windows)** | `http://localhost:5173` en tu navegador |

### Puertos Mapeados

Gracias a `forwardPorts` en `devcontainer.json`, estos puertos son accesibles desde tu Windows:

- **5173**: Frontend React (Vite)
- **8080**: Backend Java (Payara Micro)
- **5432**: PostgreSQL
- **9000**: SonarQube

---

## 🚀 Parte 1: Arranque Local Completo (Dentro del DevContainer)

> **⚠️ IMPORTANTE**: Todos los comandos de esta sección se ejecutan **DENTRO del terminal del DevContainer** en VS Code.

### Paso 1: Verificar que estás dentro del DevContainer

```bash
# Abre una terminal en VS Code (Ctrl+` o Cmd+`)
# Deberías ver algo como: vscode ➜ /workspaces/PAC $

# Verifica que estás en el contenedor:
echo $REMOTE_CONTAINERS
# Debe mostrar: true

# O simplemente verifica que tienes acceso a los servicios:
ping -c 1 db
# Debe responder desde el contenedor de PostgreSQL
```

### Paso 2: Verificar que PostgreSQL está activo

```bash
# Dentro del DevContainer, ejecuta:
pg_isready -h db -U postgres
# Debe mostrar: "db:5432 - accepting connections"
```

### Paso 3: Ejecutar migraciones de base de datos

```bash
# Aplica las migraciones de Flyway:
mvn flyway:migrate

# Verifica que las tablas se crearon:
psql -h db -U postgres -d financial_db -c "\dt"
# Debe mostrar: raw_transactions, fact_transactions
```

### Paso 4: Ejecutar ingesta de datos (Python)

```bash
# Configura las variables de entorno:
export PGHOST=db
export PGUSER=postgres
export PGPASSWORD=password
export PGDATABASE=financial_db

# Ejecuta el script de ingesta:
python etl/ingest_data.py

# Verifica que los datos se insertaron:
psql -h db -U postgres -d financial_db -c "SELECT COUNT(*) FROM raw_transactions;"
# Debe mostrar el número de filas del CSV (ej: 9)
```

### Paso 5: Ejecutar transformaciones dbt

```bash
# Navega al directorio de dbt:
cd dbt_project

# Ejecuta los modelos:
dbt run

# Ejecuta los tests:
dbt test

# Verifica los datos transformados:
psql -h db -U postgres -d financial_db -c "SELECT COUNT(*) FROM fact_transactions;"
# Debe mostrar las transacciones limpias

# Regresa al directorio raíz:
cd ..
```

### Paso 6: Iniciar el backend (Payara Micro)

```bash
# Compila y arranca el servidor:
mvn clean package payara-micro:start

# El servidor arrancará en http://localhost:8080
# Espera a ver el mensaje: "Payara Micro URLs: http://0.0.0.0:8080"
```

**⚠️ Deja esta terminal abierta** (el servidor se ejecuta en primer plano).

### Paso 7: Iniciar el frontend (React + Vite)

```bash
# Abre una NUEVA terminal en el DevContainer
# Navega al directorio del frontend:
cd frontend

# Instala las dependencias (si no lo has hecho):
npm install

# Inicia el servidor de desarrollo:
npm run dev

# El servidor arrancará en http://localhost:5173
```

**⚠️ Deja esta terminal abierta** también.

### Paso 8: Verificar la aplicación completa

> **📍 IMPORTANTE**: El navegador se abre en tu **máquina HOST (Windows)**, NO dentro del contenedor. Los puertos están mapeados automáticamente gracias a `forwardPorts` en `devcontainer.json`.

1. **Abre tu navegador** en Windows
2. **Accede a**: `http://localhost:5173`
3. **Deberías ver**:
   - Un dashboard con una tabla de transacciones
   - Filas en **rojo** para transacciones sospechosas o > 1000
   - Filas en **verde** para ingresos positivos
   - Los datos provienen del backend en tiempo real

**✅ Si todo funciona correctamente**, tu aplicación está lista para desarrollo local.

---

## 🌐 Parte 2: Despliegue en GitHub Pages (Frontend)

> **⚠️ NOTA**: Esta parte se puede hacer **desde el DevContainer** (pasos 1-3) o **desde tu máquina HOST** (pasos 4-7). Los comandos `git` funcionan en ambos lugares.

GitHub Pages solo soporta **contenido estático** (HTML, CSS, JS), por lo que desplegaremos el frontend React compilado.

### Paso 1: Preparar el frontend para producción

```bash
cd frontend

# Edita el archivo vite.config.ts y añade la base URL:
# Abre: frontend/vite.config.ts
```

**Añade esta configuración**:

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/PAC/', // Reemplaza 'PAC' con el nombre de tu repositorio
})
```

### Paso 2: Actualizar la URL del backend para producción

```bash
# Edita: frontend/src/services/api.ts
```

**Cambia la URL del backend**:

```typescript
// Para desarrollo local:
// const API_URL = 'http://localhost:8080/transactions';

// Para producción (usa tu backend desplegado):
const API_URL = 'https://tu-backend-desplegado.com/transactions';

export async function fetchTransactions(): Promise<Transaction[]> {
  const response = await fetch(API_URL);
  if (!response.ok) {
    throw new Error('Error al cargar transacciones');
  }
  return response.json();
}
```

**⚠️ IMPORTANTE**: GitHub Pages no puede ejecutar el backend Java. Necesitarás desplegarlo en otro servicio (ver Parte 3).

### Paso 3: Compilar el frontend

```bash
cd frontend

# Compila la aplicación para producción:
npm run build

# Esto genera la carpeta 'dist' con los archivos estáticos
```

### Paso 4: Configurar GitHub Pages con GitHub Actions

Crea el archivo `.github/workflows/deploy-frontend.yml`:

```yaml
name: Deploy Frontend to GitHub Pages

on:
  push:
    branches:
      - main

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install dependencies
        working-directory: ./frontend
        run: npm ci

      - name: Build
        working-directory: ./frontend
        run: npm run build

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./frontend/dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### Paso 5: Habilitar GitHub Pages en el repositorio

1. Ve a tu repositorio en GitHub
2. **Settings** → **Pages**
3. En **Source**, selecciona: **GitHub Actions**
4. Guarda los cambios

### Paso 6: Hacer push y desplegar

```bash
# Desde el directorio raíz del proyecto (DevContainer o HOST):
git add .
git commit -m "Configure frontend for GitHub Pages deployment"
git push origin main

# Ve a GitHub → Actions (desde tu navegador en Windows)
# Verás el workflow "Deploy Frontend to GitHub Pages" ejecutándose
# Espera a que termine (tarda ~2-3 minutos)
```

> **💡 TIP**: Si tienes problemas con Git desde el DevContainer, puedes hacer el commit y push desde tu terminal de Windows/PowerShell en el directorio del proyecto.

### Paso 7: Acceder a tu aplicación desplegada

Una vez completado el workflow:

```
https://<tu-usuario>.github.io/PAC/
```

Reemplaza `<tu-usuario>` con tu nombre de usuario de GitHub y `PAC` con el nombre de tu repositorio.

---

## ☁️ Parte 3: Desplegar el Backend (Opciones)

GitHub Pages **NO soporta backend Java**. Necesitas desplegarlo en otro servicio:

### Opción A: Railway (Recomendado - Gratis con límites)

1. **Crea una cuenta en**: https://railway.app
2. **Conecta tu repositorio de GitHub**
3. **Configura las variables de entorno**:
   ```
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=<genera-una-segura>
   POSTGRES_DB=financial_db
   ```
4. **Railway detectará automáticamente** el `pom.xml` y desplegará Payara Micro
5. **Copia la URL pública** que Railway te proporciona (ej: `https://pac-production.up.railway.app`)
6. **Actualiza** `frontend/src/services/api.ts` con esta URL

### Opción B: Render (Gratis con límites)

1. **Crea una cuenta en**: https://render.com
2. **Crea un nuevo Web Service** desde tu repositorio
3. **Configura**:
   - **Build Command**: `mvn clean package`
   - **Start Command**: `java -jar target/payara-micro.jar --deploy target/tu-app.war`
4. **Añade una base de datos PostgreSQL** desde el dashboard de Render
5. **Configura las variables de entorno** con las credenciales de la BD
6. **Copia la URL pública** y actualiza el frontend

### Opción C: Heroku (Requiere tarjeta de crédito)

1. **Instala Heroku CLI**: https://devcenter.heroku.com/articles/heroku-cli
2. **Crea una app**:
   ```bash
   heroku create tu-app-financiera
   heroku addons:create heroku-postgresql:mini
   ```
3. **Configura el Procfile**:
   ```
   web: java -jar target/payara-micro.jar --deploy target/financial-dashboard.war --port $PORT
   ```
4. **Despliega**:
   ```bash
   git push heroku main
   ```

### Opción D: Servidor propio / VPS

Si tienes un servidor con Java 11+ y PostgreSQL:

```bash
# Copia el WAR al servidor:
scp target/financial-dashboard.war usuario@tu-servidor:/opt/apps/

# En el servidor, ejecuta:
java -jar payara-micro.jar --deploy financial-dashboard.war --port 8080

# Configura un reverse proxy con Nginx:
# /etc/nginx/sites-available/financial-api
server {
    listen 80;
    server_name api.tu-dominio.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 🔧 Parte 4: Configuración CORS para Producción

Una vez que tengas el backend desplegado, asegúrate de que el CORS permita peticiones desde tu dominio de GitHub Pages:

**Edita**: `src/main/java/com/pac/resource/TransactionResource.java`

```java
@Path("/transactions")
@Produces(MediaType.APPLICATION_JSON)
public class TransactionResource {

    @GET
    public Response getAllTransactions() {
        // ... tu código ...
        return Response.ok(transactions)
            .header("Access-Control-Allow-Origin", "https://<tu-usuario>.github.io")
            .header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
            .header("Access-Control-Allow-Headers", "Content-Type")
            .build();
    }
}
```

O mejor aún, crea un filtro CORS global:

**Crea**: `src/main/java/com/pac/filter/CorsFilter.java`

```java
package com.pac.filter;

import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.ext.Provider;
import java.io.IOException;

@Provider
public class CorsFilter implements ContainerResponseFilter {

    @Override
    public void filter(ContainerRequestContext requestContext,
                       ContainerResponseContext responseContext) throws IOException {
        responseContext.getHeaders().add("Access-Control-Allow-Origin", "*");
        responseContext.getHeaders().add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        responseContext.getHeaders().add("Access-Control-Allow-Headers", "Content-Type, Authorization");
    }
}
```

---

## ✅ Checklist Final

Antes de dar por terminado el despliegue, verifica:

- [ ] El frontend se desplegó correctamente en GitHub Pages
- [ ] El backend está desplegado y accesible públicamente
- [ ] La base de datos PostgreSQL está configurada y con datos
- [ ] Las migraciones de Flyway se ejecutaron en producción
- [ ] El script de ingesta Python se ejecutó en producción
- [ ] Los modelos dbt se ejecutaron en producción
- [ ] El CORS está configurado correctamente
- [ ] El frontend puede hacer peticiones al backend sin errores
- [ ] Las transacciones se muestran correctamente en el dashboard
- [ ] Los colores condicionales funcionan (rojo/verde)

---

## 🐛 Troubleshooting

### Error: "Failed to fetch" en el frontend

**Causa**: El backend no está accesible o CORS no está configurado.

**Solución**:
```bash
# Verifica que el backend responde:
curl https://tu-backend-desplegado.com/transactions

# Verifica los headers CORS:
curl -I https://tu-backend-desplegado.com/transactions
# Debe incluir: Access-Control-Allow-Origin
```

### Error: "404 Not Found" en GitHub Pages

**Causa**: La ruta base no está configurada correctamente.

**Solución**:
```typescript
// En vite.config.ts:
base: '/nombre-exacto-del-repositorio/'
```

### Error: Base de datos vacía en producción

**Causa**: No se ejecutaron las migraciones o el script de ingesta.

**Solución**:
```bash
# Conéctate al servidor de producción y ejecuta:
mvn flyway:migrate
python etl/ingest_data.py
cd dbt_project && dbt run
```

---

## 📚 Recursos Adicionales

- **GitHub Pages**: https://docs.github.com/pages
- **Railway Docs**: https://docs.railway.app
- **Render Docs**: https://render.com/docs
- **Payara Micro**: https://docs.payara.fish/community/docs/documentation/payara-micro/payara-micro.html
- **Vite Deployment**: https://vitejs.dev/guide/static-deploy.html

---

## 🎉 ¡Felicidades!

Has completado el despliegue de tu aplicación fullstack. Ahora tienes:

- ✅ Un **frontend React** desplegado en GitHub Pages
- ✅ Un **backend Java EE** desplegado en un servicio cloud
- ✅ Una **base de datos PostgreSQL** en producción
- ✅ Un **pipeline de datos** (Python + dbt) funcional
- ✅ **CI/CD** configurado con GitHub Actions

**URL de tu aplicación**: `https://<tu-usuario>.github.io/PAC/`

¡Comparte tu proyecto con el mundo! 🚀
