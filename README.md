# AlmacénRC - Sistema de Gestión de Almacén

Sistema integral de gestión de almacén desarrollado con Flask y Oracle Database, diseñado para la administración eficiente de productos, proveedores y procesos de abastecimiento.

## Características Principales

- **Gestión de Productos**: Creación, actualización y administración completa de inventario
- **Gestión de Proveedores**: Manejo de información de proveedores y relaciones comerciales
- **Eliminación Lógica**: Sistema de habilitación/inhabilitación sin pérdida de datos
- **Proceso de Abastecimiento**: Identificación automática de productos con stock bajo
- **Dashboard Ejecutivo**: Métricas y KPIs del estado del almacén
- **API REST**: Endpoints completos para integración con sistemas externos
- **Arquitectura PL/SQL**: Todas las operaciones de base de datos mediante packages PL/SQL

## Arquitectura Técnica

### Backend
- **Framework**: Flask (Python 3.11)
- **Base de Datos**: Oracle Database 21c Express Edition
- **ORM**: Conexión directa con oracledb
- **Arquitectura**: Microservicios con Docker

### Frontend
- **Templates**: Jinja2 con Bootstrap
- **JavaScript**: Vanilla JS para interactividad
- **Estilo**: CSS responsivo y moderno

### Base de Datos
- **Packages PL/SQL**: PKG_PRODUCTOS, PKG_PROVEEDORES, PKG_DIRECTORIO
- **Secuencias**: Generación automática de IDs
- **Eliminación Lógica**: Sistema de estado en memoria Flask

## Requisitos del Sistema

- Docker y Docker Compose
- Python 3.11+ (para desarrollo local)
- Oracle Database 21c XE
- 4GB RAM mínimo
- 10GB espacio en disco

## Instalación y Despliegue

### Usando Docker (Recomendado)

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd almacenRC
```

2. **Configurar variables de entorno**
```bash
cp .env.example .env
# Editar .env con los valores apropiados
```

3. **Construir y ejecutar**
```bash
docker-compose up --build
```

4. **Acceder a la aplicación**
- **Aplicación Web**: http://localhost:5000
- **Oracle Enterprise Manager**: http://localhost:8080

### Desarrollo Local

1. **Configurar entorno Python**
```bash
cd flask-web
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows
pip install -r requirements.txt
```

2. **Configurar base de datos Oracle**
```bash
# Asegurar que Oracle esté ejecutándose
# Ejecutar scripts de base de datos manualmente
```

3. **Ejecutar aplicación Flask**
```bash
python app.py
```

## Estructura del Proyecto

```
almacenRC/
├── flask-web/                 # Aplicación Flask
│   ├── app.py                # Aplicación principal
│   ├── templates/            # Templates HTML
│   ├── requirements.txt      # Dependencias Python
│   └── Dockerfile           # Imagen Docker Flask
├── db_scripts/              # Scripts de base de datos
│   ├── packages/            # Packages PL/SQL
│   ├── sequences/           # Secuencias Oracle
│   └── scripts/             # Scripts de inicialización
├── docker-compose.yml       # Configuración Docker
├── Dockerfile              # Imagen Docker Oracle
├── init_oracle.sh          # Script de inicialización Oracle
└── README.md               # Documentación
```

## API REST

### Productos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/productos` | Obtener todos los productos |
| POST | `/api/productos` | Crear nuevo producto |
| GET | `/api/productos/{id}` | Obtener producto específico |
| PUT | `/api/productos/{id}` | Actualizar producto |
| DELETE | `/api/productos/{id}` | Inhabilitar producto |
| POST | `/api/productos/{id}/reactivar` | Reactivar producto |

### Proveedores

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/proveedores` | Obtener todos los proveedores |
| POST | `/api/proveedores` | Crear nuevo proveedor |
| PUT | `/api/proveedores/{codigo}` | Actualizar proveedor |
| DELETE | `/api/proveedores/{codigo}` | Inhabilitar proveedor |
| POST | `/api/proveedores/{codigo}/reactivar` | Reactivar proveedor |
| GET | `/api/proveedores/{codigo}/productos` | Productos del proveedor |

### Directorio

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/directorio` | Obtener relaciones producto-proveedor |
| POST | `/api/directorio` | Crear nueva relación |
| DELETE | `/api/directorio/{producto}/{proveedor}` | Eliminar relación |

## Funcionalidades del Sistema

### Dashboard
- Métricas generales del almacén
- Productos con stock crítico
- Valor total del inventario
- Estado de proveedores

### Gestión de Productos
- CRUD completo de productos
- Control de stock y fechas de vencimiento
- Estados: CRÍTICO (< 10), BAJO (< 30), NORMAL
- Eliminación lógica (habilitar/inhabilitar)

### Gestión de Proveedores
- CRUD completo de proveedores
- Relación con productos
- Eliminación lógica
- Conteo automático de productos asociados

### Proceso de Abastecimiento
- Identificación automática de productos con stock bajo
- Sugerencias de cantidad a comprar
- Información de contacto de proveedores
- Alertas de productos sin proveedor asignado

## Despliegue en VPS

### Especificaciones del Servidor
- **Servidor**: Ubuntu Server 
- **Recursos**: 2 vCPUs, 8GB RAM mínimo
- **Ubicación del proyecto**: ~/almacenRC

### Preparación del VPS

1. **Instalar dependencias**
```bash
apt update && apt upgrade -y
apt install -y docker.io docker-compose git
```

2. **Configurar firewall**
```bash
ufw allow ssh
ufw allow 5000/tcp    # Aplicación Flask
ufw allow 1522/tcp    # Oracle Database
ufw enable
```

### Despliegue

1. **Clonar y configurar**
```bash
cd ~
git clone <repository-url> almacenRC
cd almacenRC
```

2. **Variables de entorno**
```bash
# Crear .env para producción
cp docker-compose.yml docker-compose.prod.yml
# Editar variables de producción según necesidades
```

3. **Ejecutar aplicación**
```bash
docker-compose up -d
docker-compose logs -f
```

### Comandos Útiles

```bash
# Ver estado
docker-compose ps

# Ver logs
docker-compose logs flask-web
docker-compose logs oracledb

# Reiniciar
docker-compose restart

# Actualizar aplicación
git pull
docker-compose down
docker-compose up -d --build

# Limpiar sistema
docker system prune -f
```

### Backup Básico

```bash
# Backup de base de datos
docker exec oracledb expdp laura/Laura2004@XEPDB1 directory=DATA_PUMP_DIR dumpfile=backup.dmp

# Backup de código
tar -czf backup_code.tar.gz ~/almacenRC
```

## Configuración de Producción

### Variables de Entorno
```bash
# Oracle Database
ORACLE_PWD=<password>
APP_USER=laura
APP_USER_PWD=<password>
ORACLE_DATABASE=XEPDB1

# Flask
FLASK_DEBUG=False
FLASK_ENV=production

# Puertos
ORACLE_PORT=1522
ORACLE_EM_PORT=8080
```

## Licencia

Este proyecto es de uso interno para fines educativos y de desarrollo.


---