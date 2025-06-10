#!/bin/bash

echo "Ì∑± Apagando contenedores anteriores..."
docker-compose down -v

echo "Ì¥® Construyendo e iniciando en segundo plano..."
docker-compose up --build -d

echo "‚è≥ Esperando a que Oracle est√© listo..."

# Esperar hasta que Oracle est√© disponible (por healthcheck)
until docker exec oracledb bash -c "echo 'SELECT 1 FROM DUAL;' | sqlplus -s sys/oracle@localhost:1521/XEPDB1 as sysdba | grep -q 1"; do
  echo "‚è≥ Oracle a√∫n no est√° listo. Esperando 5 segundos..."
  sleep 5
done

echo "‚úÖ Oracle est√° listo. Ejecutando init_oracle.sh..."
docker exec -i oracledb bash /opt/oracle/scripts/startup/init_oracle.sh full
