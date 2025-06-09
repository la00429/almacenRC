-- Wrapper script para ejecutar todo el esquema en el orden correcto
-- Cambiar a la PDB y usuario correcto
ALTER SESSION SET CONTAINER = XEPDB1;

-- Cambiar al usuario laura 
ALTER SESSION SET CURRENT_SCHEMA = LAURA;

-- Mostrar información de conexión
SELECT 'Ejecutando como: ' || SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') || ' en ' || SYS_CONTEXT('USERENV', 'CON_NAME') FROM DUAL;

-- Establecer el directorio de trabajo
DEFINE script_dir = '/opt/oracle/scripts/user_scripts'

-- Primero ejecutar los tipos de objetos
@@&script_dir/01_object_types.sql

-- Luego ejecutar los paquetes
@@&script_dir/02_packages.sql

-- Finalmente ejecutar el schema principal desde el directorio correcto
-- Usar @@ para que SQL*Plus cambie al directorio del archivo
@@/opt/oracle/scripts/user_scripts/_crebas.sql

-- Confirmar que todo se ejecutó correctamente
SELECT 'Schema creado exitosamente' FROM DUAL;
