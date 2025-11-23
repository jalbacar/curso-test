# 🔐 Guía de Configuración de Password en Payara Server

## 📌 ¿Cómo saber si Payara tiene password?

### Método 1: Intentar un comando sin autenticación
```cmd
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin list-domains
```

- **Sin password**: El comando funciona directamente
- **Con password**: Te pide usuario y contraseña

### Método 2: Verificar secure-admin
```cmd
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin get secure-admin.enabled
```

- `secure-admin.enabled=false` → **No requiere password** (por defecto)
- `secure-admin.enabled=true` → **Requiere password**

---

## 🔧 Configurar Password en Payara (si no tiene)

### 1. Cambiar password del admin:

```cmd
docker exec -it pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin change-admin-password
```

Te preguntará:
```
Enter admin user name [default: admin]> admin
Enter the admin password> [ENTER - está vacío]
Enter the new admin password> tu_nueva_password
Enter the new admin password again> tu_nueva_password
```

### 2. Habilitar administración segura (opcional):

```cmd
docker exec -it pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin enable-secure-admin
```

### 3. Reiniciar el dominio:

```cmd
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin restart-domain
```

---

## 📝 Formatos de Password File

### Archivo básico (`/tmp/pwdfile`):
```properties
AS_ADMIN_PASSWORD=mi_password
```

### Archivo completo (para cambio de password):
```properties
AS_ADMIN_PASSWORD=password_actual
AS_ADMIN_NEWPASSWORD=password_nuevo
```

### Archivo para master password:
```properties
AS_ADMIN_MASTERPASSWORD=changeit
```

---

## 🛠️ Usar Password File en Comandos

### Crear el archivo:

**Linux/Mac/Git Bash:**
```bash
echo "AS_ADMIN_PASSWORD=mi_password" > /tmp/pwdfile
chmod 600 /tmp/pwdfile
```

**Windows CMD:**
```cmd
echo AS_ADMIN_PASSWORD=mi_password > C:\temp\pwdfile.txt
docker cp C:\temp\pwdfile.txt pac_devcontainer-appserver-1:/tmp/pwdfile
docker exec pac_devcontainer-appserver-1 chmod 600 /tmp/pwdfile
```

**Windows PowerShell:**
```powershell
"AS_ADMIN_PASSWORD=mi_password" | Out-File -FilePath C:\temp\pwdfile.txt -Encoding ASCII -NoNewline
docker cp C:\temp\pwdfile.txt pac_devcontainer-appserver-1:/tmp/pwdfile
docker exec pac_devcontainer-appserver-1 chmod 600 /tmp/pwdfile
```

### Usar en comandos:

```cmd
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin --user admin --passwordfile=/tmp/pwdfile list-applications
```

### Limpiar después:

```cmd
docker exec pac_devcontainer-appserver-1 rm /tmp/pwdfile
del C:\temp\pwdfile.txt
```

---

## 🔒 Mejores Prácticas de Seguridad

### 1. **Nunca pongas passwords en variables de entorno**
❌ Malo:
```cmd
set ADMIN_PASS=mi_password
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin --passwordfile=<(echo "AS_ADMIN_PASSWORD=$ADMIN_PASS")
```

✅ Bueno:
```cmd
REM Usar archivo temporal con permisos restrictivos
```

### 2. **Siempre usa permisos 600 en el password file**
```cmd
docker exec pac_devcontainer-appserver-1 chmod 600 /tmp/pwdfile
```

### 3. **Elimina el password file después de usarlo**
```cmd
docker exec pac_devcontainer-appserver-1 rm -f /tmp/pwdfile
```

### 4. **No subas password files a Git**
Agrega a `.gitignore`:
```gitignore
*pwdfile*
*.password
*credentials*
```

### 5. **Para producción, usa variables cifradas**
```cmd
REM Usar secretos de Docker o Kubernetes
docker secret create payara_admin_pwd payara_pwd.txt
```

---

## 🚀 Scripts Disponibles

| Script | Descripción | Cuándo usarlo |
|--------|-------------|---------------|
| `setup-datasource.bat` | Sin autenticación | Payara sin password (defecto) |
| `setup-datasource-secure.bat` | Pregunta si hay password | Cuando no estás seguro |
| Comandos manuales | Máximo control | Troubleshooting |

---

## 🐛 Troubleshooting

### Error: "Invalid username or password"

**Causa**: El password file está mal formateado o el password es incorrecto

**Solución**:
1. Verifica que no haya espacios extras:
   ```cmd
   docker exec pac_devcontainer-appserver-1 cat /tmp/pwdfile
   ```
2. Debe ser exactamente: `AS_ADMIN_PASSWORD=valor`
3. Sin espacios antes/después del `=`
4. Sin comillas

### Error: "Cannot read password file"

**Causa**: Archivo no existe o permisos incorrectos

**Solución**:
```cmd
docker exec pac_devcontainer-appserver-1 ls -la /tmp/pwdfile
docker exec pac_devcontainer-appserver-1 chmod 600 /tmp/pwdfile
```

### Error: "Remote command requires secure admin"

**Causa**: Secure admin está habilitado pero usas HTTP

**Solución**:
```cmd
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin disable-secure-admin
docker exec pac_devcontainer-appserver-1 /opt/payara/appserver/bin/asadmin restart-domain
```

---

## 📚 Referencias

- [Payara Admin Console Security](https://docs.payara.fish/community/docs/documentation/payara-server/server-configuration/security/admin-console-security.html)
- [Payara asadmin Password File](https://docs.payara.fish/community/docs/documentation/payara-server/asadmin-commands/asadmin-command-reference/password-file.html)
- [Enable Secure Admin](https://docs.payara.fish/community/docs/documentation/payara-server/server-configuration/security/enable-secure-admin.html)
