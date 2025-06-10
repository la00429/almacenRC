#!/bin/bash

echo "� Apagando contenedores anteriores..."
docker-compose down -v

echo "� Construyendo e iniciando en segundo plano..."
docker-compose up --build -d

echo "⏳ Esperando a que Oracle esté listo..."

# Esperar hasta que Oracle esté disponible (por healthcheck)
until docker exec oracledb bash -c "echo 'SELECT 1 FROM DUAL;' | sqlplus -s sys/oracle@localhost:1521/XEPDB1 as sysdba | grep -q 1"; do
  echo "⏳ Oracle aún no está listo. Esperando 5 segundos..."
  sleep 5
done

echo "✅ Oracle está listo. Ejecutando init_oracle.sh..."
docker exec -i oracledb bash /opt/oracle/scripts/startup/init_oracle.sh full
