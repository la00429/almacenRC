-- Wrapper script para ejecutar _crebas.sql con la conexión correcta
-- Conectar al usuario laura en la PDB XEPDB1
CONNECT laura/Laura2004@localhost:1521/XEPDB1;

-- Cambiar al directorio donde están los scripts
-- Ejecutar el script original de creación de esquema (mismo directorio)
@@_crebas.sql

EXIT;
