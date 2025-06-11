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
SEQUENCE_DIR="/opt/oracle/scripts/manual/sequences"
PACKAGE_DIR="/opt/oracle/scripts/manual/packages"

# Función para esperar a que Oracle esté listo
wait_for_oracle() {
    echo "Esperando a que Oracle esté listo..."
    while true; do
        if sqlplus -s "$SYS_CONN" <<< "exit" > /dev/null 2>&1; then
            echo "Oracle está listo"
            break
        fi
        echo "Oracle no está listo aún, esperando..."
        sleep 10
    done
}

# Esperar a que Oracle esté listo
wait_for_oracle

# Ejecutar script de creación de usuario
echo "Ejecutando script de creación de usuario..."
sqlplus -s "$SYS_CONN" @"${SCRIPT_DIR}/ccuser.sql"

# Ejecutar script de dominios
echo "Ejecutando script de dominios..."
sqlplus -s "$LAURA_CONN" @"${SCRIPT_DIR}/_dominios.sql"

# Ejecutar script base
echo "Ejecutando script base..."
sqlplus -s "$LAURA_CONN" @"${SCRIPT_DIR}/_crebas.sql"

# Ejecutar scripts de creación de tablas (ct*.sql)
echo "Ejecutando scripts de creación de tablas..."
for f in "${SCRIPT_DIR}"/ct*.sql; do
    if [ -f "$f" ]; then
        echo "Ejecutando $(basename "$f")..."
        sqlplus -s "$LAURA_CONN" @"$f"
    fi
done

# Ejecutar scripts de secuencias
echo "Ejecutando scripts de secuencias..."
for f in "$SEQUENCE_DIR"/*.sql; do
    if [ -f "$f" ]; then
        echo "Ejecutando $(basename "$f")..."
        sqlplus -s "$LAURA_CONN" @"$f"
    fi
done

# Ejecutar scripts de inserción de datos (ins*.sql)
echo "Ejecutando scripts de inserción de datos..."
for f in "${SCRIPT_DIR}"/ins*.sql; do
    if [ -f "$f" ]; then
        echo "Ejecutando $(basename "$f")..."
        sqlplus -s "$LAURA_CONN" @"$f"
    fi
done

# Ejecutar paquetes
echo "Ejecutando paquetes..."
for f in "$PACKAGE_DIR"/*.sql; do
    if [ -f "$f" ]; then
        echo "Ejecutando $(basename "$f")..."
        sqlplus -s "$LAURA_CONN" @"$f"
    fi
done

echo "Inicialización completada"
