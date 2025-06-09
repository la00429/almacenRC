FROM container-registry.oracle.com/database/express:21.3.0-xe

# Establecer variables de entorno
ENV APP_USER=laura
ENV APP_USER_PWD=Laura2004
ENV ORACLE_PWD=oracle

# SOLO copiar el script de usuario corregido
COPY db_scripts/scripts/ccuser.sql /opt/oracle/scripts/startup/01_create_user.sql

# Copiar TODOS los scripts directamente al directorio startup (mismo nivel)
COPY db_scripts/scripts/ /opt/oracle/scripts/startup/

# Asegurar que el wrapper se ejecute como segundo paso
COPY db_scripts/scripts/wrapper_crebas.sql /opt/oracle/scripts/startup/02_create_schema.sql

# El wrapper ahora puede encontrar _crebas.sql en el mismo directorio