# 🗄️ AlmacenRC - Sistema de Gestión de Almacén con Oracle Database

Sistema completo de gestión de almacén construido con Oracle Database XE 21c y PL/SQL.

## 🚀 Inicio Rápido

### Prerrequisitos
- Docker y Docker Compose instalados
- Al menos 4GB de RAM disponible para Oracle
- Puertos 1522 y 8080 disponibles

### 🔧 Configuración e Instalación

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd almacenRC
```

2. **Reconstruir el sistema completo**
```bash
# Usar el script de utilidad para una instalación completa
./init_oracle.sh rebuild
```

3. **Verificar el estado**
```bash
./init_oracle.sh status
```

4. **Instalar paquetes PL/SQL (opcional)**
```bash
./init_oracle.sh packages
```

5. **Ejecutar pruebas del sistema**
```bash
./init_oracle.sh tests
```

## 🛠️ Script de Utilidad (`init_oracle.sh`)

Hemos incluido un script de utilidad que facilita la gestión del sistema:

```bash
# Verificar estado actual
./init_oracle.sh status

# Reconstruir desde cero (recomendado si hay problemas)
./init_oracle.sh rebuild

# Instalar paquetes PL/SQL
./init_oracle.sh packages

# Ejecutar todas las pruebas
./init_oracle.sh tests

# Ver logs de Oracle
./init_oracle.sh logs

# Conectar a Oracle como usuario LAURA
./init_oracle.sh connect

# Proceso completo: rebuild + packages + tests
./init_oracle.sh full
```

## 🔐 Credenciales por Defecto

- **Usuario SYS**: `sys` / `oracle`
- **Usuario de aplicación**: `laura` / `Laura2004`
- **Base de datos**: `XEPDB1`
- **Puerto**: `1522` (mapeado desde 1521 interno)

## 📋 Conectividad

### Desde el host
```bash
# Conectar como usuario de aplicación
sqlplus laura/Laura2004@localhost:1522/XEPDB1

# Conectar como SYS
sqlplus sys/oracle@localhost:1522/XE as sysdba
```

### Desde dentro del contenedor
```bash
# Ejecutar shell en el contenedor
docker exec -it oracledb bash

# Conectar como laura
sqlplus laura/Laura2004@localhost:1521/XEPDB1
```

## 🏗️ Estructura del Proyecto

```
almacenRC/
├── docker-compose.yml      # Configuración de servicios
├── Dockerfile             # Imagen personalizada de Oracle
├── init_oracle.sh         # Script de utilidad (¡USAR ESTE!)
├── db_scripts/            # Scripts de base de datos
│   ├── scripts/           # Scripts de tablas y datos
│   │   ├── ccuser.sql     # Creación del usuario
│   │   ├── _crebas.sql    # Creación de tablas básicas
│   │   ├── ct*.sql        # Creación de tablas específicas
│   │   ├── cc*.sql        # Constraints
│   │   ├── ins*.sql       # Inserción de datos
│   │   └── test*.sql      # Scripts de prueba
│   └── packages/          # Paquetes PL/SQL
│       ├── 01_object_types.sql  # Tipos de objetos
│       └── 02_packages.sql      # Paquetes principales
└── README.md              # Este archivo
```

## 🚨 Resolución de Problemas

### Error "ORA-01017: invalid username/password"

**Causa**: Problemas con credenciales o inicialización incompleta.

**Solución**:
```bash
# Rebuild completo del sistema
./init_oracle.sh rebuild

# Si persiste, verificar logs
./init_oracle.sh logs
```

### Error "DATABASE SETUP WAS NOT SUCCESSFUL"

**Causa**: Fallo en la inicialización de Oracle.

**Soluciones**:
1. **Verificar recursos disponibles** (mínimo 4GB RAM)
2. **Limpiar volúmenes de Docker**:
   ```bash
   docker-compose down -v
   docker system prune -f
   ./init_oracle.sh rebuild
   ```

### Contenedor se detiene inesperadamente

**Verificar**:
```bash
# Ver logs detallados
docker logs oracledb

# Verificar recursos del sistema
docker stats oracledb
```

### Healthcheck fallando

**Causa**: Oracle aún no está completamente iniciado.

**Solución**: Oracle XE puede tardar 5-10 minutos en inicializarse completamente. Ser paciente.

## 🧪 Pruebas del Sistema

El proyecto incluye un sistema completo de pruebas:

```bash
# Ejecutar todas las pruebas
./init_oracle.sh tests

# O manualmente dentro del contenedor
docker exec oracledb sqlplus laura/Laura2004@localhost:1521/XEPDB1 @/opt/oracle/scripts/manual/scripts/run_all_tests.sql
```

Las pruebas verifican:
- ✅ Conectividad de base de datos
- ✅ Existencia de tablas
- ✅ Funcionalidad de tipos de objetos PL/SQL
- ✅ Funcionalidad de paquetes PL/SQL
- ✅ Integridad de datos

## 📊 Monitoreo

### Verificar estado de la base de datos
```bash
# Conectar y verificar
./init_oracle.sh connect

# Dentro de SQL*Plus
SQL> SELECT tablespace_name, status FROM dba_tablespaces;
SQL> SELECT username, account_status FROM dba_users WHERE username = 'LAURA';
```

### Enterprise Manager (opcional)
- URL: http://localhost:8080/em
- Usuario: sys
- Contraseña: oracle

## 🔄 Mantenimiento

### Backup de datos
```bash
# Crear backup del volumen
docker run --rm -v almacenrc_oracle_data:/data -v $(pwd):/backup ubuntu tar czf /backup/oracle_backup.tar.gz /data
```

### Restaurar backup
```bash
# Restaurar desde backup
docker run --rm -v almacenrc_oracle_data:/data -v $(pwd):/backup ubuntu tar xzf /backup/oracle_backup.tar.gz -C /
```

## 📚 Documentación Adicional

- [Scripts de Base de Datos](./db_scripts/README.md)
- [Oracle Database XE 21c Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/)

## 🤝 Contribución

1. Fork el proyecto
2. Crear una rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

---

**⚠️ Nota importante**: Si experimentas problemas, usa primero `./init_oracle.sh rebuild` que resuelve la mayoría de los issues de configuración. 