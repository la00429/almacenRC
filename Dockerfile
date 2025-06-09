FROM container-registry.oracle.com/database/express:21.3.0-XE

ARG APP_USER=laura
ARG APP_USER_PWD=Laura2004
ARG ORACLE_PWD=oracle # Contraseña para SYS, SYSTEM, PDBADMIN

COPY db_scripts/scripts/ /tmp/scripts/

RUN echo "Creando usuario $APP_USER..." && \
    sqlplus -S system/$ORACLE_PWD@localhost:1521/xepdb1 @/tmp/scripts/ccuser.sql && \
    echo "Usuario $APP_USER creado y permisos otorgados."

RUN echo "Ejecutando scripts de creación de esquema para $APP_USER..." && \
    sqlplus -S $APP_USER/$APP_USER_PWD@localhost:1521/xepdb1 @/tmp/scripts/_crebas.sql && \
    echo "Esquema creado para $APP_USER."