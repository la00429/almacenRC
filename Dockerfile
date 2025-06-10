FROM container-registry.oracle.com/database/express:21.3.0-xe

ENV ORACLE_PWD=oracle
ENV ORACLE_DATABASE=XEPDB1
ENV ORACLE_CHARACTERSET=AL32UTF8
ENV ORACLE_SID=XE
ENV ORACLE_PDB=XEPDB1

USER root

RUN mkdir -p /opt/oracle/scripts/startup \
    && mkdir -p /opt/oracle/scripts/manual/scripts \
    && mkdir -p /opt/oracle/scripts/manual/packages \
    && mkdir -p /var/log/oracle_setup \
    && chown -R oracle:oinstall /opt/oracle/scripts \
    && chown -R oracle:oinstall /var/log/oracle_setup

COPY db_scripts/scripts/ /opt/oracle/scripts/manual/scripts/
COPY db_scripts/packages/ /opt/oracle/scripts/manual/packages/
COPY init_oracle.sh /opt/oracle/scripts/startup/init_oracle.sh

RUN chmod -R 755 /opt/oracle/scripts \
    && chown -R oracle:oinstall /opt/oracle/scripts

USER oracle

HEALTHCHECK --interval=30s --timeout=30s --start-period=10m --retries=3 \
  CMD echo "connect laura/Laura2004@localhost:1521/XEPDB1; SELECT 1 FROM DUAL; exit;" | sqlplus -s /nolog | grep -q "1" || exit 1

EXPOSE 1521 8080

CMD ["/bin/bash", "/opt/oracle/scripts/startup/init_oracle.sh", "full"]
