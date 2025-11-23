# 🔐 GitHub Secrets Configuration

Este archivo contiene la lista de secrets que deben configurarse en GitHub para que el workflow CI funcione correctamente.

## 📍 Dónde Configurar

1. Ve a tu repositorio en GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Click en **New repository secret**
4. Agrega cada secret con su valor correspondiente

## 🔑 Secrets Requeridos

### Para SonarQube Analysis (Opcional)

#### `SONAR_HOST_URL`
**Descripción:** URL del servidor SonarQube  
**Ejemplo:** `http://sonarqube:9000` o `https://sonarcloud.io`  
**Requerido:** ⚠️ Solo si quieres ejecutar análisis de SonarQube

**Cómo obtenerlo:**
- Si usas SonarCloud: `https://sonarcloud.io`
- Si usas SonarQube self-hosted: La URL de tu instancia

#### `SONAR_TOKEN`
**Descripción:** Token de autenticación para SonarQube  
**Requerido:** ⚠️ Solo si quieres ejecutar análisis de SonarQube

**Cómo obtenerlo:**

**Para SonarQube:**
1. Inicia sesión en tu instancia de SonarQube
2. Ve a **My Account** (click en tu avatar)
3. **Security** tab
4. **Generate Tokens**
5. Ingresa un nombre (ej: `github-actions`)
6. Selecciona tipo: **Global Analysis Token**
7. Click **Generate**
8. ⚠️ **Copia el token inmediatamente** (no podrás verlo después)

**Para SonarCloud:**
1. Ve a https://sonarcloud.io/account/security
2. **Generate Tokens**
3. Ingresa un nombre (ej: `github-actions`)
4. Click **Generate**
5. Copia el token

## 🚦 Configuración Mínima (Sin SonarQube)

Si NO quieres usar SonarQube, el workflow funcionará sin configurar secrets. Simplemente:

1. El job `sonarqube-analysis` se saltará automáticamente
2. Los tests de backend y frontend se ejecutarán normalmente

## ✅ Verificar Configuración

### Método 1: Via GitHub Actions
1. Haz un commit a la rama `main`
2. Ve a **Actions** tab
3. Verifica que el workflow se ejecuta

### Método 2: Via GitHub UI
1. **Settings** → **Secrets and variables** → **Actions**
2. Verifica que los secrets aparecen en la lista
3. ⚠️ No podrás ver los valores (solo los nombres)

## 🔒 Seguridad

### ✅ Best Practices

- ✅ **NUNCA** commitees secrets en el código
- ✅ Rota los tokens regularmente (cada 3-6 meses)
- ✅ Usa tokens con permisos mínimos necesarios
- ✅ Revoca tokens que ya no uses
- ✅ Usa diferentes tokens para dev/prod

### ❌ NO HAGAS ESTO

```bash
# ❌ MAL: No hardcodear tokens
SONAR_TOKEN=sqp_1234567890abcdef

# ❌ MAL: No commitear en código
sonar.login=your-token-here

# ❌ MAL: No compartir tokens en Slack/Email
```

## 📋 Checklist de Configuración

Marca cada item cuando lo completes:

- [ ] Acceder a GitHub Settings → Secrets and variables → Actions
- [ ] (Opcional) Crear secret `SONAR_HOST_URL` con la URL de SonarQube
- [ ] (Opcional) Crear secret `SONAR_TOKEN` con el token de autenticación
- [ ] Hacer un commit a `main` para probar el workflow
- [ ] Verificar en Actions tab que el workflow se ejecuta correctamente
- [ ] (Opcional) Verificar que el análisis aparece en SonarQube

## 🆘 Troubleshooting

### Secret no funciona
1. Verifica que el nombre del secret coincide exactamente (case-sensitive)
2. Revoca el token viejo y genera uno nuevo
3. Actualiza el secret en GitHub
4. Re-ejecuta el workflow

### No veo el job de SonarQube
- Es normal si no está configurado `SONAR_TOKEN`
- El job se salta automáticamente con `continue-on-error: true`

### Error de autenticación en SonarQube
1. Verifica que el token no haya expirado
2. Comprueba que tiene permisos de **Execute Analysis**
3. Intenta generar un nuevo token

## 📚 Recursos

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [SonarQube Token Documentation](https://docs.sonarqube.org/latest/user-guide/user-account/generating-and-using-tokens/)
- [SonarCloud Tokens](https://docs.sonarcloud.io/advanced-setup/analysis-parameters/)

## 🔄 Actualización de Tokens

Cuando necesites rotar tokens:

1. **Genera un nuevo token** en SonarQube/SonarCloud
2. **Actualiza el secret** en GitHub:
   - Settings → Secrets → Click en el secret
   - Click **Update secret**
   - Pega el nuevo valor
3. **Revoca el token antiguo** en SonarQube
4. **Prueba** haciendo un commit a main

## 📧 Soporte

Si tienes problemas con la configuración:

1. Revisa los logs del workflow en GitHub Actions
2. Verifica la documentación de SonarQube
3. Consulta el README del workflow en `.github/workflows/README.md`
