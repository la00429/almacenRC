# 🗄️ AlmacenRC - Sistema de Gestión de Almacén

Sistema completo de gestión de almacén con backend en **Oracle Database 21c** y una interfaz web con **Flask**.

## 🚀 Arquitectura

- **Backend**: Base de datos Oracle XE 21c con tablas, paquetes PL/SQL y lógica de negocio.
- **Interfaz Web**: Aplicación Flask para visualizar y gestionar el inventario.
- **Orquestación**: Docker y Docker Compose para un despliegue sencillo y consistente.

## ✨ Características

- **Dashboard Interactivo**: Métricas clave como total de productos, alertas de stock bajo y valor del inventario.
- **Gestión de Productos**: Visualiza, añade, actualiza y elimina productos.
- **Gestión de Proveedores**: Administra la información de los proveedores.
- **Directorio de Abastecimiento**: Asigna productos a proveedores para optimizar la cadena de suministro.
- **API RESTful**: Endpoints para interactuar con la base de datos de forma programática.

## ⚡ Inicio Rápido

### Prerrequisitos
- Docker y Docker Compose
- 4GB de RAM disponible
- Puertos `1522` (Oracle) y `5000` (Web) libres

### ⚙️ Instalación

1.  **Clonar el repositorio**:
    ```bash
    git clone <repository-url>
    cd almacenRC
    ```

2.  **Levantar los servicios con Docker Compose**:
    ```bash
    docker-compose up --build -d
    ```
    Este comando construirá las imágenes y ejecutará la base de datos Oracle y la aplicación web en segundo plano.

3.  **Inicializar la Base de Datos**:
    Usa el script `init_oracle.sh` para configurar la base de datos por primera vez.
    ```bash
    ./init_oracle.sh full
    ```
    Este proceso puede tardar varios minutos la primera vez mientras se descarga y configura Oracle.

4.  **Acceder a la Aplicación**:
    - **Interfaz Web**: [http://localhost:5000](http://localhost:5000)
    - **Base de Datos**: Conecta tu cliente SQL a `localhost:1522` (Servicio `XEPDB1`).

## 🛠️ Uso del Script `init_oracle.sh`

Este script simplifica la interacción con el contenedor de Oracle.

| Comando | Descripción |
| :--- | :--- |
| **`./init_oracle.sh full`** | **(Recomendado)** Ejecuta la configuración completa: reconstruye, crea usuario, tablas y paquetes. |
| `./init_oracle.sh status` | Verifica si Oracle está funcionando correctamente. |
| `./init_oracle.sh connect`| Inicia una sesión SQL*Plus interactiva con el usuario `LAURA`. |
| `./init_oracle.sh rebuild`| Detiene y reconstruye el contenedor de Oracle, útil si algo sale mal. |
| `./init_oracle.sh logs` | Muestra los logs del contenedor de Oracle para depuración. |

Para el uso diario, los comandos más comunes son `status` y `connect`. Si la base de datos no responde, `rebuild` es la solución más fiable.

## 🔐 Credenciales de Conexión

| Servicio | Usuario | Contraseña | DSN/Conexión |
| :--- | :--- | :--- | :--- |
| **Base de Datos (App)** | `laura` | `Laura2004` | `localhost:1522/XEPDB1` |
| **Base de Datos (Admin)**| `sys` | `oracle` | `localhost:1522/XE` |
| **Interfaz Web** | N/A | N/A | `http://localhost:5000` |

## 🗂️ Estructura del Proyecto

```
almacenRC/
├── docker-compose.yml     # Orquesta los servicios de Oracle y Flask
├── init_oracle.sh         # Script para gestionar la base de datos
├── db_scripts/            # Todos los scripts SQL para Oracle
│   ├── scripts/           # Creación de tablas, inserción de datos, etc.
│   └── packages/          # Lógica de negocio en paquetes PL/SQL
├── flask-web/             # Código fuente de la aplicación web
│   ├── app.py             # Lógica principal de Flask
│   ├── templates/         # Plantillas HTML
│   └── Dockerfile         # Dockerfile para el servicio web
└── README.md              # Este archivo
```

## 🚨 Resolución de Problemas Comunes

- **`./init_oracle.sh` no funciona**: Asegúrate de que tenga permisos de ejecución (`chmod +x init_oracle.sh`).
- **Error de conexión a la base de datos**:
    1.  Verifica el estado con `./init_oracle.sh status`.
    2.  Si no responde, revisa los logs con `./init_oracle.sh logs`.
    3.  Como último recurso, reconstruye la base de datos con `./init_oracle.sh rebuild` y luego ejecuta `./init_oracle.sh setup`.
- **La web (`localhost:5000`) no carga**:
    1.  Asegúrate de que los contenedores estén corriendo con `docker ps`.
    2.  Revisa los logs del servicio web: `docker-compose logs flask-web`.

---
_Este `README` fue actualizado para reflejar la nueva estructura y simplificar las instrucciones._ 