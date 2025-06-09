#!/bin/bash

# Script de utilidad para inicializar Oracle Database
# Autor: Asistente AI
# Fecha: $(date)

set -e

echo "🚀 Iniciando configuración de Oracle Database para AlmacenRC..."

# Función para mostrar el estado de Oracle
check_oracle_status() {
    echo "📊 Verificando estado de Oracle..."
    
    # Verificar si el contenedor está corriendo
    if docker ps | grep -q "oracledb"; then
        echo "✅ Contenedor Oracle está corriendo"
        
        # Verificar conectividad básica
        echo "🔗 Verificando conectividad con SYS..."
        if docker exec oracledb bash -c "echo 'SELECT 1 FROM DUAL;' | sqlplus -s sys/oracle@localhost:1521/XE as sysdba" | grep -q "1"; then
            echo "✅ Conectividad SYS OK"
            
            # Verificar usuario laura
            echo "👤 Verificando usuario LAURA..."
            if docker exec oracledb bash -c "echo 'SELECT USER FROM DUAL;' | sqlplus -s laura/Laura2004@localhost:1521/XEPDB1" | grep -q "LAURA"; then
                echo "✅ Usuario LAURA OK"
                
                # Verificar tablas básicas
                echo "🗄️ Verificando tablas..."
                table_count=$(docker exec oracledb bash -c "echo 'SELECT COUNT(*) FROM user_tables;' | sqlplus -s laura/Laura2004@localhost:1521/XEPDB1" | grep -E "^[[:space:]]*[0-9]+[[:space:]]*$" | tr -d '[:space:]' || echo "0")
                echo "📊 Tablas encontradas: $table_count"
                
                if [ "$table_count" -gt "0" ]; then
                    echo "✅ Base de datos completamente configurada"
                    return 0
                else
                    echo "⚠️ Usuario OK pero no hay tablas creadas"
                    return 2
                fi
            else
                echo "❌ Usuario LAURA no disponible"
                return 3
            fi
        else
            echo "❌ Error de conectividad con Oracle"
            return 4
        fi
    else
        echo "❌ Contenedor Oracle no está corriendo"
        return 1
    fi
}

# Función para limpiar y reconstruir
rebuild_oracle() {
    echo "🔄 Reconstruyendo Oracle Database..."
    
    # Detener y limpiar contenedores existentes
    echo "🧹 Limpiando contenedores y volúmenes existentes..."
    docker-compose down -v
    docker system prune -f
    
    # Reconstruir desde cero
    echo "🏗️ Construyendo nueva imagen..."
    docker-compose up --build -d
    
    echo "⏳ Esperando que Oracle se inicialice completamente..."
    echo "💡 Esto puede tardar 5-10 minutos la primera vez..."
    
    # Esperar con indicador de progreso
    local attempts=0
    local max_attempts=60  # 10 minutos máximo
    
    while ! docker ps | grep -q "oracledb.*healthy\|Up.*healthy"; do
        attempts=$((attempts + 1))
        if [ $attempts -ge $max_attempts ]; then
            echo "❌ Timeout: Oracle no se ha inicializado en 10 minutos"
            echo "📋 Mostrando logs para diagnóstico:"
            docker logs --tail 20 oracledb
            return 1
        fi
        
        # Mostrar progreso
        if [ $((attempts % 6)) -eq 0 ]; then
            echo "⏳ Esperando... ($((attempts / 6)) minutos transcurridos)"
            # Mostrar las últimas 3 líneas de log para dar feedback
            docker logs --tail 3 oracledb 2>/dev/null | tail -1 || true
        fi
        
        sleep 10
    done
    
    echo "✅ Oracle inicializado, verificando configuración..."
    sleep 30  # Dar tiempo extra para que terminen los scripts
    
    # Verificar estado final
    check_oracle_status
}

# Función para configurar la base de datos inicialmente
setup_database() {
    echo "🔧 Configurando base de datos inicial..."
    
    # Crear usuario LAURA
    echo "👤 Creando usuario LAURA..."
    docker exec oracledb sqlplus sys/oracle@localhost:1521/XE as sysdba @/opt/oracle/scripts/manual/scripts/ccuser.sql
    
    # Crear tablas básicas
    echo "🏗️ Creando tablas básicas..."
    docker exec oracledb bash -c "cd /opt/oracle/scripts/manual/scripts && sqlplus laura/Laura2004@localhost:1521/XEPDB1 @_crebas.sql"
    
    echo "✅ Base de datos configurada"
}

# Función para instalar paquetes PL/SQL
install_packages() {
    echo "📦 Instalando paquetes PL/SQL..."
    
    # Ejecutar tipos de objetos
    echo "🔧 Instalando tipos de objetos..."
    docker exec oracledb bash -c "cd /opt/oracle/scripts/manual && sqlplus laura/Laura2004@localhost:1521/XEPDB1 @packages/01_object_types.sql"
    
    # Ejecutar paquetes
    echo "📚 Instalando paquetes..."
    docker exec oracledb bash -c "cd /opt/oracle/scripts/manual && sqlplus laura/Laura2004@localhost:1521/XEPDB1 @packages/02_packages.sql"
    
    echo "✅ Paquetes PL/SQL instalados"
}

# Función para ejecutar pruebas
run_tests() {
    echo "🧪 Ejecutando pruebas del sistema..."
    
    # Copiar script de pruebas
    docker cp db_scripts/scripts/run_all_tests.sql oracledb:/tmp/
    
    # Ejecutar pruebas
    docker exec oracledb sqlplus laura/Laura2004@localhost:1521/XEPDB1 @/tmp/run_all_tests.sql
}

# Función para mostrar logs útiles
show_logs() {
    echo "📋 Mostrando logs de Oracle..."
    docker logs --tail 50 oracledb
}

# Función para conectarse a Oracle
connect_oracle() {
    echo "🔌 Conectando a Oracle como usuario LAURA..."
    docker exec -it oracledb sqlplus laura/Laura2004@localhost:1521/XEPDB1
}

# Menú principal
case "${1:-}" in
    "status")
        check_oracle_status
        ;;
    "rebuild")
        rebuild_oracle
        ;;
    "setup")
        setup_database
        ;;
    "packages")
        install_packages
        ;;
    "tests")
        run_tests
        ;;
    "logs")
        show_logs
        ;;
    "connect")
        connect_oracle
        ;;
    "full")
        echo "🎯 Ejecución completa: rebuild + setup + packages + tests"
        rebuild_oracle
        sleep 30
        setup_database
        install_packages
        run_tests
        ;;
    *)
        echo "🔧 Script de utilidad para Oracle Database - AlmacenRC"
        echo ""
        echo "Uso: $0 [comando]"
        echo ""
        echo "Comandos disponibles:"
        echo "  status    - Verificar estado actual de Oracle"
        echo "  rebuild   - Reconstruir Oracle desde cero (solo contenedor)"
        echo "  setup     - Configurar usuario y tablas básicas"
        echo "  packages  - Instalar paquetes PL/SQL"
        echo "  tests     - Ejecutar pruebas del sistema"
        echo "  logs      - Mostrar logs de Oracle"
        echo "  connect   - Conectar a Oracle como usuario LAURA"
        echo "  full      - Ejecutar proceso completo (rebuild + setup + packages + tests)"
        echo ""
        echo "Ejemplos:"
        echo "  $0 status      # Verificar estado"
        echo "  $0 rebuild     # Reconstruir desde cero"
        echo "  $0 full        # Proceso completo"
        ;;
esac 