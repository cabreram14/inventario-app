# **UNIVERSIDAD POLITÉCNICA SALESIANA**

# Sistemas Distribuidos

## Práctica: Examen Final - Practica (CI/CD)

**Estudiantes:** *Sebastián Cabrera, Diana Avila*
**Asignatura:** *Sistemas Distribuidos*  
**Universidad:** *Universidad Politécnica Salesiana*
**Período:** *68*

---

# Inventario App


Catálogo de inventario con interfaz web y base de datos local. Este proyecto fue extendido para implementar un pipeline completo de CI/CD con Docker, GitHub Actions y Kubernetes, incluyendo diferentes estrategias de despliegue y buenas prácticas de aplicaciones contenerizadas.

---

# Tecnologías utilizadas

- Node.js
- Express
- Docker (Multi-stage Build)
- GitHub Actions
- GitHub Container Registry (GHCR)
- Kubernetes
- Kubernetes Secrets
- Trivy
- Minikube

---

# Ejecutar en local

```bash
npm install
npm start
# abrir http://localhost:3000
```

## Pruebas

```bash
npm test
```

---

# Construcción de la imagen Docker

La aplicación utiliza un **Dockerfile Multi-stage**, donde la primera etapa instala las dependencias y ejecuta las pruebas automatizadas. Si alguna prueba falla, la construcción de la imagen se detiene (principio **Fail-Fast**).

La segunda etapa genera una imagen mínima que contiene únicamente los archivos necesarios para ejecutar la aplicación.

Construcción de la imagen:

```bash
docker build -t inventario-app .
```

Ejecución del contenedor:

```bash
docker run -p 3000:3000 inventario-app
```

---

# Pipeline CI/CD

El proyecto implementa un pipeline mediante **GitHub Actions** compuesto por dos trabajos encadenados.

| Job | Función |
|---|---|
| **build-test** | Instala dependencias (`npm ci`) y ejecuta las pruebas (`npm test`). |
| **build-push** | Se ejecuta únicamente si el primer trabajo finaliza correctamente y publica la imagen en GitHub Container Registry (GHCR) con las etiquetas `latest` y el hash del commit. |

---

# Despliegue en Kubernetes

La aplicación se despliega utilizando recursos nativos de Kubernetes.

Características del Deployment:

- 2 réplicas.
- Estrategia ***RollingUpdate***.
- `maxUnavailable: 1`.
- `maxSurge: 1`.
- Readiness Probe.
- Liveness Probe.

El acceso a la aplicación se realiza mediante un **Service NodePort**.


# Persistencia de datos

La aplicación almacena los productos en un archivo JSON (`data/products.json`) dentro del contenedor.

Al eliminar un Pod mediante:

```bash
kubectl delete pod <nombre-del-pod>
```

Kubernetes crea automáticamente un nuevo Pod. Sin embargo, el producto agregado anteriormente desaparece porque el almacenamiento pertenece al sistema de archivos del contenedor y no existe un volumen persistente.

Este comportamiento es esperado y demuestra la naturaleza efímera del almacenamiento local del contenedor.

---

# Estrategias de despliegue

## Blue-Green Deployment

Consiste en mantener dos Deployments completamente independientes (**Blue** y **Green**). Uno atiende todas las solicitudes mientras el otro permanece preparado para reemplazarlo. El cambio de versión se realiza modificando el selector del Service.

**Recursos utilizados**

- Deployment
- Service
- Labels
- Selectors



## Canary Deployment

Consiste en ejecutar simultáneamente la versión estable y una nueva versión de la aplicación. Ambas son atendidas por el mismo Service y el tráfico se distribuye aproximadamente de forma proporcional al número de réplicas de cada Deployment.

**Recursos utilizados**

- Deployment
- Service
- Labels
- Réplicas


## Comparación

| Blue-Green | Canary |
|---|---|
| Dos entornos completos. | Dos versiones ejecutándose simultáneamente. |
| Todo el tráfico cambia de una versión a otra. | El tráfico se migra gradualmente. |
| Rollback inmediato cambiando el selector del Service. | Rollback reduciendo o eliminando las réplicas de la nueva versión. |
| Mayor consumo de recursos. | Menor consumo de recursos. |

---

# Estrategia seleccionada

Para esta práctica se seleccionó la estrategia **Canary**, ya que permite validar una nueva versión con una pequeña parte del tráfico antes de reemplazar completamente la versión estable. Esta estrategia puede implementarse utilizando únicamente recursos nativos de Kubernetes (Deployments y Service), sin necesidad de herramientas adicionales como Argo Rollouts.


## Objetivo

Implementar una estrategia **Canary Deployment** utilizando únicamente recursos nativos de Kubernetes, sin emplear herramientas adicionales como **Argo Rollouts**.

## Descripción

Inicialmente la aplicación se desplegó mediante un único **Deployment** con dos réplicas y un **Service** encargado de distribuir el tráfico entre los Pods.

```
Deployment
│
├── 2 Pods
│
└── Service
```

Para implementar la estrategia **Canary**, la arquitectura se modificó creando dos Deployments independientes que comparten el mismo Service.

```
                 Service
                     │
         ┌───────────┴───────────┐
         │                       │
Deployment Stable         Deployment Canary
      4 Pods                  1 Pod
      v1                      v2
```

En esta configuración ambos Deployments son seleccionados por el mismo **Service**, por lo que Kubernetes distribuye las solicitudes aproximadamente de forma proporcional al número de réplicas de cada Deployment.

De esta manera, aproximadamente:

- **80 %** del tráfico es atendido por la versión estable (**Stable**).
- **20 %** del tráfico es atendido por la nueva versión (**Canary**).

Esta estrategia permite validar una nueva versión de la aplicación con una pequeña parte del tráfico antes de reemplazar completamente la versión estable, reduciendo el riesgo de una actualización completa.

## Archivos utilizados

Para implementar esta estrategia se utilizarán los siguientes manifiestos de Kubernetes:

```
k8s/
├── deployment-stable.yaml
├── deployment-canary.yaml
└── service.yaml
```

- **deployment-stable.yaml:** despliega la versión estable de la aplicación.
- **deployment-canary.yaml:** despliega la nueva versión (Canary).
- **service.yaml:** distribuye el tráfico entre ambas versiones mediante un único Service.

---

# Glosario

| Concepto | Definición |
|---|---|
| **Deployment** | Recurso de Kubernetes encargado de administrar los Pods y sus actualizaciones. |
| **Service** | Recurso que proporciona un punto de acceso estable hacia uno o varios Pods. |
| **RollingUpdate** | Estrategia de actualización gradual que mantiene la disponibilidad de la aplicación durante el despliegue. |
| **Blue-Green Deployment** | Estrategia basada en dos entornos completos donde el Service cambia completamente el tráfico entre ambos. |
| **Canary Deployment** | Estrategia que introduce una nueva versión gradualmente compartiendo tráfico con la versión estable. |
| **Readiness Probe** | Verifica que un contenedor esté listo para recibir solicitudes. |
| **Liveness Probe** | Verifica que el contenedor continúe funcionando correctamente y pueda reiniciarse en caso de fallo. |
| **Replica** | Instancia de un Pod administrada por un Deployment. |
| **Selector** | Conjunto de etiquetas utilizado por un Service para identificar los Pods que recibirán tráfico. |

---

# Manifiestos de la estrategia Canary

Los manifiestos correspondientes a la segunda estrategia de despliegue se encuentran organizados dentro de la carpeta `k8s/canary/`.

```text
k8s/
├── deployment.yaml
├── service.yaml
└── canary/
    ├── deployment-stable.yaml
    ├── deployment-canary.yaml
    └── service.yaml
```

Los archivos ubicados directamente en `k8s/` corresponden al despliegue base con estrategia `RollingUpdate`. Los archivos almacenados en `k8s/canary/` implementan la segunda estrategia solicitada.

- `deployment-stable.yaml`: configura cuatro réplicas de la versión estable `v1-stable`.
- `deployment-canary.yaml`: configura una réplica de la nueva versión `v2-canary`.
- `service.yaml`: selecciona los Pods de ambas versiones mediante la etiqueta común `app: inventario-app`.

La estrategia puede desplegarse mediante 2 maneras:

```bash
kubectl apply -f k8s/canary/
```

```bash
kubectl apply -f k8s\canary\deployment-stable.yaml
kubectl apply -f k8s\canary\deployment-canary.yaml
kubectl apply -f k8s\canary\service.yaml
```
---

# Validación de la estrategia Canary

Para comprobar la distribución de tráfico, se enviaron múltiples solicitudes al endpoint `/version` mediante el Service compartido.

```powershell
1..50 | ForEach-Object {
    $respuesta = curl.exe -s -H "Connection: close" "$url/version" | ConvertFrom-Json
    $respuesta.version
} | Group-Object | Select-Object Name, Count
```

La mayoría de las respuestas fueron atendidas por la versión estable `v1-stable`, mientras que una proporción menor correspondió a `v2-canary`.

La distribución se obtiene mediante:

- 4 réplicas de la versión Stable.
- 1 réplica de la versión Canary.
- Un único Service que selecciona ambas versiones.

La proporción esperada es aproximadamente:

- 80 % del tráfico hacia Stable.
- 20 % del tráfico hacia Canary.

La distribución observada no tiene que ser exactamente 80/20 en cada ejecución, ya que depende del balanceo de solicitudes realizado por Kubernetes. Sin embargo, debe comprobarse que ambas versiones reciben tráfico y que la versión Canary aparece con menor frecuencia.

---

# Manejo de secretos con Kubernetes

Para evitar almacenar credenciales en texto plano dentro de los manifiestos, se creó un Secret de Kubernetes llamado `inventario-app-secret`.

El Secret fue creado directamente desde la línea de comandos:

```bash
kubectl create secret generic inventario-app-secret \
  --from-literal=API_KEY="valor-ficticio"
```

El valor no fue almacenado dentro de ningún archivo versionado en Git.

Los Deployments Stable y Canary consumen la credencial mediante `secretKeyRef`:

```yaml
- name: API_KEY
  valueFrom:
    secretKeyRef:
      name: inventario-app-secret
      key: API_KEY
```

La variable fue comprobada dentro de un Pod con:

```bash
kubectl exec <nombre-del-pod> -- printenv API_KEY
```

También se verificó que el valor de la credencial no estuviera registrado en el repositorio mediante:

```bash
git grep "valor-de-la-credencial"
```

De esta forma, el nombre de la variable puede permanecer en los manifiestos, pero su valor real se administra de manera independiente dentro del clúster.

---

# Escaneo de seguridad con Trivy

Como parte de las buenas prácticas de DevSecOps, el pipeline incorpora un análisis automático de vulnerabilidades utilizando **Trivy** antes de publicar la imagen Docker en GitHub Container Registry.

## Flujo del pipeline

1. Ejecutar pruebas.
2. Construir la imagen Docker.
3. Analizar la imagen con Trivy.
4. Publicar la imagen únicamente si el análisis es satisfactorio.

La configuración utilizada fue:

```yaml
- name: Escanear imagen con Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: inventario-app:scan
    format: table
    exit-code: "1"
    ignore-unfixed: true
    vuln-type: "os,library"
    severity: "CRITICAL"
```

## Política de seguridad

El pipeline fue configurado para bloquear automáticamente la publicación de imágenes cuando Trivy detecta vulnerabilidades de severidad **CRITICAL**.

```yaml
exit-code: "1"
severity: "CRITICAL"
```

Durante las pruebas, Trivy detectó una vulnerabilidad crítica en la dependencia **tar**, por lo que GitHub Actions finalizó el proceso con **Exit Code 1**, impidiendo la publicación de la imagen.

Posteriormente se actualizó la versión de npm utilizada durante la construcción de la imagen Docker para mantener compatibilidad con Node.js 20 y reducir el riesgo asociado a dependencias vulnerables.

Con esta configuración se garantiza que únicamente las imágenes que superen el análisis de seguridad puedan ser publicadas en el registro de contenedores.

---

# Readiness Probe con Arranque Lento

## Implementación

Se modificó el endpoint `/health` de la aplicación para que utilice una variable de entorno denominada `STARTUP_DELAY_SECONDS`.

```javascript
const STARTUP_DELAY_SECONDS = Number.parseInt(
  process.env.STARTUP_DELAY_SECONDS || '0',
  10
);

const APPLICATION_START_TIME = Date.now();
```

Mientras no se cumpla el tiempo configurado, el endpoint responde con el código **HTTP 503 Service Unavailable** indicando que la aplicación continúa inicializando.

```json
{
  "status": "starting",
  "reason": "la aplicación todavía está inicializando"
}
```

Una vez transcurrido el tiempo de espera, el mismo endpoint responde correctamente con **HTTP 200 OK**.

```json
{
  "status": "ok"
}
```

## Configuración en Kubernetes

Se añadió la variable de entorno en los despliegues **Stable** y **Canary**.

```yaml
env:
  - name: STARTUP_DELAY_SECONDS
    value: "20"
```

Posteriormente se configuró la **Readiness Probe** para consultar periódicamente el endpoint `/health`.

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 3
  periodSeconds: 3
  timeoutSeconds: 2
  failureThreshold: 10
```

La **Liveness Probe** permanece configurada de forma independiente para evitar reinicios innecesarios durante el proceso de inicialización.

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
```

## Verificación

Para comprobar el funcionamiento del arranque lento se inició la aplicación con la variable:

```bash
STARTUP_DELAY_SECONDS=20
```

Durante los primeros segundos el endpoint respondió:

```text
HTTP/1.1 503 Service Unavailable
```

```json
{
  "status": "starting",
  "remainingSeconds": 13
}
```

Después de finalizar el tiempo de inicialización el servicio respondió:

```text
HTTP/1.1 200 OK
```

```json
{
  "status": "ok"
}
```

---

# Endpoints

| Método y ruta | Qué hace |
|---|---|
| `GET /health` | Estado de salud de la aplicación. |
| `GET /version` | Devuelve la versión, color y hostname de la aplicación. |
| `GET /api/products` | Lista todos los productos. |
| `GET /api/products/:id` | Obtiene un producto por su identificador. |
| `POST /api/products` | Crea un nuevo producto. |
| `PATCH /api/products/:id` | Actualiza un producto existente. |
| `DELETE /api/products/:id` | Elimina un producto. |
| `GET /` | Muestra la interfaz web. |

---

# Variables de entorno

| Variable | Por defecto | Descripción |
|---|---|---|
| `PORT` | `3000` | Puerto donde se ejecuta la aplicación. |
| `APP_VERSION` | `v1` | Identifica la versión desplegada de la aplicación. |
| `APP_COLOR` | `blue` | Color utilizado para identificar visualmente la versión desplegada. |
| `SIMULATE_FAILURE` | `false` | Permite simular una falla en el endpoint `/health` para pruebas de tolerancia a fallos. |
| `STARTUP_DELAY_SECONDS` | `0` | Tiempo de espera (en segundos) antes de que la aplicación sea considerada lista para recibir tráfico. Se utiliza para validar el funcionamiento de la Readiness Probe. |
| `DB_PATH` | `./data/products.json` | Ruta del archivo utilizado como base de datos local de la aplicación. |

---

# Conclusiones

Durante el desarrollo de esta práctica se implementó un flujo completo de integración y despliegue continuo (CI/CD) utilizando Docker, GitHub Actions y Kubernetes.

La aplicación fue contenerizada mediante un Dockerfile Multi-stage, permitiendo ejecutar pruebas automáticas antes de generar una imagen optimizada para producción. Posteriormente, el pipeline de GitHub Actions automatizó la construcción de la imagen, el análisis de vulnerabilidades mediante Trivy y su publicación en GitHub Container Registry (GHCR).

En Kubernetes se implementó una estrategia Rolling Update para el despliegue base y una estrategia Canary para distribuir progresivamente el tráfico entre una versión estable y una nueva versión de la aplicación.

Como componentes adicionales se incorporó el uso de Kubernetes Secrets para administrar credenciales de forma segura, Trivy para realizar escaneos automáticos de vulnerabilidades durante el pipeline y una Readiness Probe con arranque lento para garantizar que los Pods únicamente reciban tráfico cuando la aplicación haya finalizado su proceso de inicialización.

Estas implementaciones permiten mejorar la disponibilidad, seguridad y confiabilidad del proceso de despliegue, aplicando buenas prácticas utilizadas actualmente en entornos de integración y entrega continua.

---

# Reproducción completa del proyecto

## 1. Clonar el repositorio

```bash
git clone https://github.com/cabreram14/inventario-app.git
cd inventario-app
```

## 2. Instalar dependencias y ejecutar pruebas

```bash
npm ci
npm test
```

## 3. Construir la imagen Docker

```bash
docker build --no-cache -t inventario-app:segura .
```

## 4. Ejecutar la aplicación localmente

```bash
docker run --rm -p 3000:3000 inventario-app:segura
```

La aplicación estará disponible en:

```text
http://localhost:3000
```

## 5. Iniciar Minikube

```bash
minikube start
```

## 6. Crear el Secret

En PowerShell:

```powershell
kubectl create secret generic inventario-app-secret `
  --from-literal=API_KEY="REEMPLAZAR_CON_UN_VALOR_SEGURO"
```

La credencial real no debe almacenarse en el repositorio.

## 7. Desplegar la versión base

```powershell
kubectl apply -f k8s\deployment.yaml
kubectl apply -f k8s\service.yaml
```

## 8. Verificar el despliegue base

```powershell
kubectl get deployments
kubectl get pods
kubectl get services
kubectl rollout status deployment/inventario-app
```

## 9. Desplegar la estrategia Canary

```powershell
kubectl apply -f k8s\canary\deployment-stable.yaml
kubectl apply -f k8s\canary\deployment-canary.yaml
kubectl apply -f k8s\canary\service.yaml
```

## 10. Verificar Stable y Canary

```powershell
kubectl get deployments
kubectl get pods -L version
kubectl get endpoints inventario-app-service
```

## 11. Obtener la URL de Minikube

```powershell
minikube service inventario-app-service --url
```

Guardar la URL generada:

```powershell
$url = "URL_GENERADA_POR_MINIKUBE"
```

## 12. Verificar la distribución Canary

```powershell
1..50 | ForEach-Object {
    $respuesta = curl.exe -s -H "Connection: close" "$url/version" |
      ConvertFrom-Json
    $respuesta.version
} | Group-Object | Select-Object Name, Count
```

El resultado debe mostrar respuestas de:

```text
v1-stable
v2-canary
```

## 13. Verificar el Secret

```powershell
kubectl describe secret inventario-app-secret
kubectl exec NOMBRE_DEL_POD -- printenv API_KEY
```

## 14. Verificar la Readiness Probe

```powershell
kubectl get pods -w
```

Durante la inicialización el Pod debe aparecer como:

```text
0/1 Running
```

Después del tiempo configurado debe cambiar a:

```text
1/1 Running
```

## 15. Verificar el endpoint de salud

```powershell
curl.exe -i "$url/health"
```

## 16. Eliminar los recursos

```powershell
kubectl delete -f k8s\canary\
kubectl delete -f k8s\deployment.yaml
kubectl delete -f k8s\service.yaml
kubectl delete secret inventario-app-secret
```

## 17. Detener Minikube

```powershell
minikube stop
```