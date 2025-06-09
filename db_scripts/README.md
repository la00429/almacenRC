# Estructura de Scripts de Base de Datos - AlmacenRC

## Organización de Carpetas

### 📁 `scripts/`
**Scripts principales del sistema**
- `ccuser.sql` - Creación del usuario de aplicación (usado por Docker)
- `_crebas.sql` - Creación del esquema básico de tablas (usado por Docker)
- Scripts de inserción de datos (`ins*.sql`)
- Scripts de creación de tablas específicas (`ct*.sql`)
- Scripts de creación de constraints (`cc*.sql`)
- **Scripts de prueba:**
  - `test_object_types.sql` - Pruebas de tipos de objetos PL/SQL
  - `test_packages.sql` - Pruebas de paquetes PL/SQL
  - `run_all_tests.sql` - Script maestro que ejecuta todas las pruebas
- Otros scripts auxiliares

### 📁 `packages/`
**Paquetes y objetos PL/SQL (ejecutar manualmente después de Docker)**
- `01_object_types.sql` - Definición de tipos de objetos
- `02_packages.sql` - Paquetes PL/SQL del sistema

## Flujo de Ejecución

1. **Docker Build**: Ejecuta automáticamente `ccuser.sql` y `_crebas.sql` desde `scripts/`
2. **Post-instalación**: Los scripts de `packages/` se ejecutan manualmente según necesidad
3. **Datos**: Scripts de inserción (`ins*.sql`) se ejecutan según requerimiento
4. **Pruebas**: Scripts de prueba para verificar funcionalidad

## Uso

### Construcción inicial
```bash
# Construir el contenedor (ejecuta ccuser.sql y _crebas.sql automáticamente)
docker-compose up --build
```

### Instalación de paquetes PL/SQL
```bash
# Conectar al contenedor
docker exec -it oracledb sqlplus laura/Laura2004@localhost:1521/xepdb1

# Ejecutar paquetes PL/SQL
SQL> @packages/01_object_types.sql
SQL> @packages/02_packages.sql
```

### Ejecutar pruebas
```bash
# Conectar al contenedor
docker exec -it oracledb sqlplus laura/Laura2004@localhost:1521/xepdb1

# Ejecutar todas las pruebas
SQL> @scripts/run_all_tests.sql

# O ejecutar pruebas individuales
SQL> @scripts/test_object_types.sql
SQL> @scripts/test_packages.sql
```

## Scripts de Prueba

### 🧪 `test_object_types.sql`
Verifica que los tipos de objetos funcionen correctamente:
- Creación de objetos `TP_PRODUCTO`, `TP_PROVEEDOR`, `TP_DIRECTORIO`
- Creación de colecciones `TBL_PRODUCTOS`, `TBL_PROVEEDORES`, `TBL_DIRECTORIOS`
- Iteración sobre colecciones

### 🧪 `test_packages.sql`
Verifica que los paquetes PL/SQL funcionen correctamente:
- Existencia de paquetes
- Funciones CRUD de productos
- Funciones pipelined
- Funciones para APEX
- Gestión de stock

### 🧪 `run_all_tests.sql`
Script maestro que:
- Verifica el entorno de base de datos
- Ejecuta todas las pruebas en orden
- Genera un reporte completo del sistema
- Identifica objetos inválidos

## Resultados Esperados

Al ejecutar `run_all_tests.sql` deberías ver:
- ✅ Verificación del entorno exitosa
- ✅ Tipos de objetos funcionando
- ✅ Paquetes PL/SQL funcionando
- ✅ Reporte final sin objetos inválidos 