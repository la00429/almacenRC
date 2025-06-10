#!/bin/bash

# Variables de configuración
ORACLE_HOST="localhost"
ORACLE_PORT="1521"
ORACLE_PDB="XEPDB1"
ORACLE_SID="XE"
USER_LAURA="laura"
PASS_LAURA="Laura2004"
ORACLE_PWD="oracle"

# Variables de conexión
SYS_CONN="sys/${ORACLE_PWD}@${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_PDB} as sysdba"
LAURA_CONN="${USER_LAURA}/${PASS_LAURA}@${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_PDB}"
SCRIPT_DIR="/opt/oracle/scripts/manual/scripts"
PACKAGE_DIR="/opt/oracle/scripts/manual/packages"

# Esperar a que Oracle esté listo
sleep 30

# Ejecutar script de creación de usuario
sqlplus -s "$SYS_CONN" @"${SCRIPT_DIR}/ccuser.sql"

# Ejecutar script base
sqlplus -s "$LAURA_CONN" @"${SCRIPT_DIR}/_crebas.sql"

# Ejecutar paquetes
for f in "$PACKAGE_DIR"/*.sql; do
    if [ -f "$f" ]; then
        sqlplus -s "$LAURA_CONN" @"$f"
    fi
done
