# 🗄️ AlmacenRC - Sistema de Gestión de Almacén con Oracle Database

Sistema completo de gestión de almacén construido con Oracle Database XE 21c y PL/SQL.

## 🚀 Inicio Rápido

### Prerrequisitos
- Docker y Docker Compose instalados
- Al menos 4GB de RAM disponible para Oracle
- Puertos 1522 y 8080 disponibles

### ⚡ Instalación en 3 Pasos

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd almacenRC
```

2. **Ejecutar el script de configuración**
```bash
# Opción 1: Proceso completo automático (recomendado)
./init_oracle.sh full

# Opción 2: Paso a paso
./init_oracle.sh rebuild   # Solo contenedor Oracle
./init_oracle.sh setup     # Usuario y tablas
./init_oracle.sh packages  # Paquetes PL/SQL
./init_oracle.sh tests     # Verificar todo
```

3. **¡Listo! Conectar a la base de datos**
```bash
./init_oracle.sh connect
```

## 🛠️ Script de Utilidad (`init_oracle.sh`)

**Este es tu comando principal para todo:**

```bash
# Comandos principales
./init_oracle.sh status    # Ver estado actual
./init_oracle.sh full      # Instalación completa
./init_oracle.sh connect   # Conectar a Oracle

# Comandos específicos
./init_oracle.sh rebuild   # Solo reconstruir contenedor
./init_oracle.sh setup     # Solo configurar usuario/tablas  
./init_oracle.sh packages  # Solo instalar paquetes PL/SQL
./init_oracle.sh tests     # Solo ejecutar pruebas

# Utilidades
./init_oracle.sh logs      # Ver logs de Oracle
```

### 🎯 **Casos de Uso Comunes:**

```bash
# Primer uso o si algo falla
./init_oracle.sh full

# Uso diario - verificar estado
./init_oracle.sh status

# Trabajar con la base de datos
./init_oracle.sh connect

# Si hay problemas, ver logs
./init_oracle.sh logs
```

## 🔐 Credenciales y Conectividad

| Conexión | Usuario | Contraseña | Puerto | Base de Datos |
|----------|---------|------------|--------|---------------|
| **Aplicación** | `laura` | `Laura2004` | `1522` | `XEPDB1` |
| **Administrador** | `sys` | `oracle` | `1522` | `XE` |

### 📋 Ejemplos de Conexión

```bash
# Desde el script (recomendado)
./init_oracle.sh connect

# Manualmente desde el host
sqlplus laura/Laura2004@localhost:1522/XEPDB1

# Como administrador
sqlplus sys/oracle@localhost:1522/XE as sysdba

# Desde dentro del contenedor
docker exec -it oracledb sqlplus laura/Laura2004@localhost:1521/XEPDB1
```

## 🗂️ Estructura del Sistema

### Base de Datos
- **17 tablas** principales del sistema de almacén
- **6 tipos de objetos** PL/SQL personalizados
- **4 paquetes** PL/SQL con funcionalidades del negocio
- **Datos de prueba** para desarrollo

### Archivos del Proyecto
```
almacenRC/
├── init_oracle.sh         # 🎯 SCRIPT PRINCIPAL
├── docker-compose.yml     # Configuración de servicios
├── Dockerfile            # Imagen Oracle personalizada
├── db_scripts/           # Scripts de base de datos
│   ├── scripts/          # Tablas, datos, pruebas
│   └── packages/         # Paquetes PL/SQL
└── README.md            # Este archivo
```

## 🚨 Resolución de Problemas

### ❌ Oracle no se inicia
```bash
./init_oracle.sh logs     # Ver qué está pasando
./init_oracle.sh rebuild  # Reconstruir desde cero
```

### ❌ Error de conexión
```bash
./init_oracle.sh status   # Verificar estado
./init_oracle.sh setup    # Reconfigurar usuario
```

### ❌ Faltan tablas o paquetes
```bash
./init_oracle.sh setup     # Crear tablas
./init_oracle.sh packages  # Instalar paquetes
```

### ❌ En caso de problemas graves
```bash
# Limpieza completa y reinstalación
docker-compose down -v
docker system prune -f
./init_oracle.sh full
```

## ⏱️ Tiempos Esperados

- **Primer uso**: 5-10 minutos (descarga imagen Oracle)
- **Rebuild**: 2-3 minutos (imagen ya descargada)
- **Setup/Packages**: 30-60 segundos cada uno
- **Tests**: 15-30 segundos

## 🧪 Verificación del Sistema

```bash
# Estado completo
./init_oracle.sh status

# Ejecutar todas las pruebas
./init_oracle.sh tests

# Verificar manualmente
./init_oracle.sh connect
SQL> SELECT COUNT(*) FROM user_tables;  -- Debe ser 17
SQL> SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE';
```

## 📊 Enterprise Manager (Opcional)

- **URL**: http://localhost:8080/em
- **Usuario**: `sys`
- **Contraseña**: `oracle`
- **Como**: `SYSDBA`

## 🔄 Mantenimiento

### Backup
```bash
# Crear backup
docker run --rm -v almacenrc_oracle_data:/data -v $(pwd):/backup ubuntu \
  tar czf /backup/oracle_backup.tar.gz /data
```

### Restaurar
```bash
# Restaurar backup
docker run --rm -v almacenrc_oracle_data:/data -v $(pwd):/backup ubuntu \
  tar xzf /backup/oracle_backup.tar.gz -C /
```

## 📚 Documentación Adicional

- [Scripts de Base de Datos](./db_scripts/README.md)
- [Oracle Database XE 21c](https://docs.oracle.com/en/database/oracle/oracle-database/21/)

---

## 💡 Resumen para Uso Diario

1. **Primera vez**: `./init_oracle.sh full`
2. **Verificar estado**: `./init_oracle.sh status` 
3. **Trabajar con DB**: `./init_oracle.sh connect`
4. **Si hay problemas**: `./init_oracle.sh logs` y después `./init_oracle.sh rebuild`

**🎯 Comando más importante**: `./init_oracle.sh full` - hace todo automáticamente. 