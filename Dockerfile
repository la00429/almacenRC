FROM container-registry.oracle.com/database/express:21.3.0-xe

ENV ORACLE_PWD=oracle
ENV ORACLE_DATABASE=XEPDB1
ENV ORACLE_CHARACTERSET=AL32UTF8
ENV ORACLE_SID=XE
ENV ORACLE_PDB=XEPDB1
ENV ORACLE_EDITION=express
ENV ORACLE_BASE=/opt/oracle
ENV ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE

USER root

# Crear directorios necesarios
RUN mkdir -p /opt/oracle/scripts/startup \
    && mkdir -p /opt/oracle/scripts/manual/scripts \
    && mkdir -p /opt/oracle/scripts/manual/packages \
    && mkdir -p /var/log/oracle_setup

# Copiar scripts
COPY db_scripts/scripts/ /opt/oracle/scripts/manual/scripts/
COPY db_scripts/packages/ /opt/oracle/scripts/manual/packages/
COPY init_oracle.sh /opt/oracle/scripts/startup/

# Configurar permisos
RUN chown -R oracle:oinstall /opt/oracle/scripts \
    && chown -R oracle:oinstall /var/log/oracle_setup \
    && chmod -R 755 /opt/oracle/scripts \
    && chmod +x /opt/oracle/scripts/startup/init_oracle.sh

USER oracle

HEALTHCHECK --interval=30s --timeout=30s --start-period=10m --retries=3 \
  CMD $ORACLE_HOME/bin/lsnrctl status | grep -q "READY" || exit 1

EXPOSE 1521 8080

# Usar el script de inicio estándar de Oracle
CMD ["/opt/oracle/scripts/startup/init_oracle.sh"]
