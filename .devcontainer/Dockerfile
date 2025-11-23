# 1. Empezamos desde una imagen base de Microsoft que ya tiene Git y herramientas básicas
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Additional OS packages if needed
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends postgresql-client

# 2. Cambiamos a usuario 'root' para instalar software
USER root

# 3. Instalamos Java (JDK 11, compatible con Java EE 8) y Maven 
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk maven

# 4. Instalamos Python 3.10+, pip y librerías para dbt-postgres [cite: 20]
RUN apt-get install -y python3.10 python3-pip python3.10-venv \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 \
    && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev # Necesario para el adaptador de postgres

# 5. Instalamos Node.js (vía NVM) y las CLIs de Front-End [cite: 61, 54]
# Se ejecuta como usuario 'vscode' (el usuario no-root por defecto)
RUN su vscode -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"

# Instalamos Node LTS, Angular CLI y Vite (para React)
RUN su vscode -c "source /home/vscode/.nvm/nvm.sh && \
    nvm install --lts && \
    npm install -g @angular/cli@18 && \
    npm install -g create-vite"

# 6. Instalamos dbt y el adaptador de Postgres [cite: 19]
RUN pip install dbt-core dbt-postgres

# 7. Instalamos Flyway (para migraciones de BBDD) [cite: 79]
RUN wget -qO- https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/9.22.3/flyway-commandline-9.22.3-linux-x64.tar.gz | tar xvz && \
    ln -s $(pwd)/flyway-9.22.3/flyway /usr/local/bin/flyway

# 8. Limpiamos el caché de apt
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# 9. Volvemos al usuario 'vscode' por defecto
USER vscode