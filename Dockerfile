FROM container-registry.oracle.com/database/express:21.3.0-xe

# Variables de entorno para Oracle XE
ENV ORACLE_PWD=oracle
ENV ORACLE_DATABASE=XEPDB1
ENV ORACLE_CHARACTERSET=AL32UTF8

# Solo copiamos los scripts, sin ejecutar nada automáticamente
USER root
RUN mkdir -p /opt/oracle/scripts/manual
COPY db_scripts/ /opt/oracle/scripts/manual/

# Establecer permisos
RUN chmod -R 755 /opt/oracle/scripts/
RUN chown -R oracle:dba /opt/oracle/scripts/

# Volver al usuario oracle
USER oracle