# Usar imagen oficial de Oracle XE
FROM container-registry.oracle.com/database/express:21.3.0-xe

# Variables de entorno necesarias
ENV ORACLE_PWD=oracle
ENV ORACLE_DATABASE=XEPDB1
ENV ORACLE_CHARACTERSET=AL32UTF8
ENV ORACLE_SID=XE
ENV ORACLE_PDB=XEPDB1

# Cambiar a root para preparar estructura
USER root

# Crear carpetas necesarias para scripts y logs
RUN mkdir -p /opt/oracle/scripts/startup \
    && mkdir -p /opt/oracle/scripts/manual/scripts \
    && mkdir -p /opt/oracle/scripts/manual/packages \
    && mkdir -p /var/log/oracle_setup \
    && chown -R oracle:oinstall /opt/oracle/scripts \
    && chown -R oracle:oinstall /var/log/oracle_setup



# Copiar tus scripts desde la estructura actual
COPY db_scripts/scripts/ /opt/oracle/scripts/manual/scripts/
COPY db_scripts/packages/ /opt/oracle/scripts/manual/packages/
# Copiar script de inicialización
COPY init_oracle.sh /opt/oracle/scripts/startup/init_oracle.sh
# Asignar permisos
RUN chmod -R 755 /opt/oracle/scripts \
    && chown -R oracle:oinstall /opt/oracle/scripts

# Cambiar al usuario oracle
USER oracle

# Healthcheck opcional (puedes eliminarlo si da problemas)
HEALTHCHECK --interval=30s --timeout=30s --start-period=10m --retries=3 \
  CMD sqlplus -s /nolog <<< "connect laura/Laura2004@localhost:1521/XEPDB1; SELECT 1 FROM DUAL; exit;" | grep -q "1" || exit 1

# Exponer puertos típicos
EXPOSE 1521 8080

