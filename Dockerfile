# Usar la imagen oficial de Oracle Database XE
FROM container-registry.oracle.com/database/express:21.3.0-xe

# Establecer variables de entorno
ENV ORACLE_PWD=oracle
ENV ORACLE_DATABASE=XEPDB1
ENV ORACLE_CHARACTERSET=AL32UTF8
ENV ORACLE_SID=XE
ENV ORACLE_PDB=XEPDB1

# Crear usuario root para configuración
USER root

# Crear directorios necesarios
RUN mkdir -p /opt/oracle/scripts/setup/scripts \
    && mkdir -p /opt/oracle/scripts/startup \
    && mkdir -p /var/log/oracle_setup \
    && chown -R oracle:oinstall /opt/oracle/scripts \
    && chown -R oracle:oinstall /var/log/oracle_setup

# Copiar script de inicialización
COPY init_oracle.sh /opt/oracle/scripts/startup/01_init_oracle.sh

# Hacer el script ejecutable y asignar permisos
RUN chmod +x /opt/oracle/scripts/startup/01_init_oracle.sh \
    && chown oracle:oinstall /opt/oracle/scripts/startup/01_init_oracle.sh

# Volver al usuario oracle
USER oracle

# Healthcheck personalizado
HEALTHCHECK --interval=30s --timeout=30s --start-period=10m --retries=3 \
    CMD sqlplus -s /nolog <<< "connect sys/oracle@localhost:1521/XE as sysdba; SELECT 1 FROM DUAL; exit;" | grep -q "1" || exit 1

# Exponer puertos
EXPOSE 1521 8080 
