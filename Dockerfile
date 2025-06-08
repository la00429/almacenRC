FROM container-registry.oracle.com/database/express:21.3.0-XE

ARG APP_USER=laura
ARG APP_USER_PWD=Laura2004
ARG ORACLE_PWD=oracle # Contraseña para SYS, SYSTEM, PDBADMIN

COPY db_scripts/scripts/ /tmp/scripts/

RUN echo "Creando usuario $APP_USER..." && \
    sqlplus -S system/$ORACLE_PWD AS SYSDBA @/tmp/ccuser.sql && \
    echo "Usuario $APP_USER creado y permisos otorgados."

RUN echo "Ejecutando scripts de creación de esquema para $APP_USER..." && \
    sqlplus -S $APP_USER/$APP_USER_PWD @/tmp/_crebas.sql && \
    echo "Esquema creado para $APP_USER."

COPY db_scripts/03_initial_data.sql /opt/oracle/scripts/startup/