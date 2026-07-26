# **UNIVERSIDAD POLITÉCNICA SALESIANA**

# Sistemas Distribuidos

## Práctica: Examen Final - Practica (CI/CD)

**Estudiantes:** *Sebastián Cabrera, Diana Avila*
**Asignatura:** *Sistemas Distribuidos*  
**Universidad:** *Universidad Politécnica Salesiana*
**Período:** *68*

---

## Inventario App


Catálogo de inventario con interfaz web y base de datos local. Este proyecto fue extendido para implementar un pipeline completo de CI/CD con Docker, GitHub Actions y Kubernetes, incluyendo diferentes estrategias de despliegue y buenas prácticas de aplicaciones contenerizadas.

---

## Tecnologías utilizadas

- Node.js
- Express
- Docker (Multi-stage Build)
- GitHub Actions
- GitHub Container Registry (GHCR)
- Kubernetes
- Minikube

---

## Ejecutar en local

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

## Construcción de la imagen Docker

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

## Pipeline CI/CD

El proyecto implementa un pipeline mediante **GitHub Actions** compuesto por dos trabajos encadenados.

| Job | Función |
|---|---|
| **build-test** | Instala dependencias (`npm ci`) y ejecuta las pruebas (`npm test`). |
| **build-push** | Se ejecuta únicamente si el primer trabajo finaliza correctamente y publica la imagen en GitHub Container Registry (GHCR) con las etiquetas `latest` y el hash del commit. |

---

## Despliegue en Kubernetes

La aplicación se despliega utilizando recursos nativos de Kubernetes.

Características del Deployment:

- 2 réplicas.
- Estrategia ***RollingUpdate***.
- `maxUnavailable: 1`.
- `maxSurge: 1`.
- Readiness Probe.
- Liveness Probe.

El acceso a la aplicación se realiza mediante un **Service NodePort**.

---

## Persistencia de datos

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

---

## Canary Deployment

Consiste en ejecutar simultáneamente la versión estable y una nueva versión de la aplicación. Ambas son atendidas por el mismo Service y el tráfico se distribuye aproximadamente de forma proporcional al número de réplicas de cada Deployment.

**Recursos utilizados**

- Deployment
- Service
- Labels
- Réplicas

---

## Comparación

| Blue-Green | Canary |
|---|---|
| Dos entornos completos. | Dos versiones ejecutándose simultáneamente. |
| Todo el tráfico cambia de una versión a otra. | El tráfico se migra gradualmente. |
| Rollback inmediato cambiando el selector del Service. | Rollback reduciendo o eliminando las réplicas de la nueva versión. |
| Mayor consumo de recursos. | Menor consumo de recursos. |

---

## Estrategia seleccionada

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

## Manifiestos de la estrategia Canary

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

## Endpoints

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

## Variables de entorno

| Variable | Por defecto | Descripción |
|---|---|---|
| `PORT` | `3000` | Puerto del servidor. |
| `APP_VERSION` | `v1` | Versión de la aplicación. |
| `APP_COLOR` | `blue` | Color mostrado en la interfaz. |
| `SIMULATE_FAILURE` | `false` | Simula una falla en el endpoint `/health`. |
| `DB_PATH` | `./data/products.json` | Ruta del archivo de base de datos local. |