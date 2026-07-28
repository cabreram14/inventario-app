# ==========================================
# ETAPA 1: INSTALACIÓN Y PRUEBAS
# ==========================================
FROM node:20-alpine AS test

WORKDIR /app

# Copiar primero los archivos de dependencias
COPY package*.json ./

# Instalar las dependencias de manera reproducible
RUN npm ci

# Copiar el código necesario para ejecutar las pruebas
COPY server.js ./
COPY db.js ./
COPY server.test.js ./
COPY public ./public
COPY data ./data

# Ejecutar las pruebas.
# Si alguna prueba falla, el build se detiene.
RUN npm test && touch /tmp/tests-passed


# ==========================================
# ETAPA 2: IMAGEN FINAL
# ==========================================
FROM node:20-alpine AS production

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV APP_VERSION=v1
ENV APP_COLOR=blue

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar únicamente dependencias de producción
# RUN npm ci --omit=dev && npm cache clean --force

# Actualizar npm para corregir dependencias internas vulnerables
RUN npm install -g npm@11 \
    && npm ci --omit=dev \
    && npm cache clean --force

# Copiar únicamente los archivos requeridos para ejecutar la app
COPY --chown=node:node server.js ./
COPY --chown=node:node db.js ./
COPY --chown=node:node public ./public

# Crear la carpeta donde se almacenará la base de datos local
RUN mkdir -p /app/data && chown -R node:node /app

# Si las pruebas fallan, este archivo no se crea y el build se detiene,
# garantizando el principio fail-fast del pipeline.
COPY --from=test /tmp/tests-passed /tmp/tests-passed

# Utilizar un usuario sin privilegios
USER node

EXPOSE 3000

CMD ["node", "server.js"]