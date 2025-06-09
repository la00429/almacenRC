#!/bin/bash

# Script de utilidad para inicializar Oracle Database - AlmacenRC
# Optimizado para máximo rendimiento y detección inteligente

set -e

echo "🚀 Iniciando configuración de Oracle Database para AlmacenRC..."

# Función para verificar si Oracle está listo usando conexión directa
check_oracle_ready() {
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec oracledb bash -c "echo 'SELECT 1 FROM DUAL;' | sqlplus -s sys/oracle@localhost:1522/xepdb1 as sysdba 2>/dev/null" | grep -q "1" 2>/dev/null; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    return 1
}

# Función para mostrar el estado de Oracle
check_oracle_status() {
    echo "📊 Verificando estado de Oracle..."
    
    # Verificar si el contenedor está corriendo
    if ! docker ps | grep -q "oracledb"; then
        echo "❌ Contenedor Oracle no está corriendo"
        return 1
    fi
    
    echo "✅ Contenedor Oracle está corriendo"
    
    # Verificar conectividad básica con timeout
    echo "🔗 Verificando conectividad con SYS..."
    if check_oracle_ready; then
        echo "✅ Conectividad SYS OK"
        
        # Verificar usuario laura
        echo "👤 Verificando usuario LAURA..."
        if docker exec oracledb bash -c "echo 'SELECT USER FROM DUAL;' | sqlplus -s laura/Laura2004@localhost:1522/xepdb1 2>/dev/null" | grep -q "LAURA" 2>/dev/null; then
            echo "✅ Usuario LAURA OK"
            
            # Verificar tablas básicas
            echo "🗄️ Verificando tablas..."
            table_count=$(docker exec oracledb bash -c "echo 'SELECT COUNT(*) FROM user_tables;' | sqlplus -s laura/Laura2004@localhost:1522/xepdb1 2>/dev/null" | grep -E "^[[:space:]]*[0-9]+[[:space:]]*$" | tr -d '[:space:]' || echo "0")
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
}

# Función optimizada para esperar Oracle
wait_for_oracle() {
    echo "⏳ Esperando que Oracle se inicialice..."
    echo "💡 Máximo 2 minutos de espera optimizada..."
    
    local attempts=0
    local max_attempts=12  # 2 minutos máximo (12 * 10 segundos)
    local check_interval=10
    
    while [ $attempts -lt $max_attempts ]; do
        attempts=$((attempts + 1))
        
        # Verificar si Oracle está listo
        if check_oracle_ready; then
            echo "✅ Oracle está listo y respondiendo!"
            return 0
        fi
        
        # Mostrar progreso cada minuto
        local elapsed_minutes=$((attempts * check_interval / 60))
        if [ $((attempts % 6)) -eq 0 ]; then
            echo "⏳ Esperando... (${elapsed_minutes} minutos transcurridos)"
            # Mostrar último log relevante
            docker logs --tail 1 oracledb 2>/dev/null | grep -E "(XEPDB1|Ready|Started|Complete)" || true
        fi
        
        sleep $check_interval
    done
    
    # Timeout alcanzado - mostrar logs y intentar continuar
    echo "⚠️ Timeout de 2 minutos alcanzado"
    echo "📋 Mostrando logs recientes para diagnóstico:"
    docker logs --tail 15 oracledb | grep -E "(ERROR|XEPDB1|Ready|Started|Complete|FATAL)" || docker logs --tail 15 oracledb
    echo ""
    echo "💡 Intentando continuar con la configuración..."
    
    # Último intento de verificación
    if check_oracle_ready; then
        echo "✅ Oracle respondió en verificación final!"
        return 0
    else
        echo "❌ Oracle no responde. Revisa los logs arriba."
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
    
    # Esperar optimizado
    if wait_for_oracle; then
        echo "✅ Oracle inicializado correctamente"
        # Verificar estado final
        check_oracle_status
        return 0
    else
        echo "❌ Error en la inicialización de Oracle"
        return 1
    fi
}

# Función para configurar la base de datos inicialmente
setup_database() {
    echo "🔧 Configurando base de datos inicial..."
    
    # Verificar que Oracle esté listo primero
    if ! check_oracle_ready; then
        echo "❌ Oracle no está listo. Ejecuta primero: $0 status"
        return 1
    fi
    
    # Crear usuario LAURA
    echo "👤 Creando usuario LAURA..."
    if docker exec oracledb sqlplus sys/oracle@localhost:1522/xepdb1 as sysdba @/opt/oracle/scripts/manual/scripts/ccuser.sql; then
        echo "✅ Usuario LAURA creado"
    else
        echo "❌ Error creando usuario LAURA"
        return 1
    fi
    
    # Crear tablas básicas
    echo "🏗️ Creando tablas básicas..."
    if docker exec oracledb bash -c "cd /opt/oracle/scripts/manual/scripts && sqlplus laura/Laura2004@localhost:1522/xepdb1 @_crebas.sql"; then
        echo "✅ Tablas creadas correctamente"
    else
        echo "❌ Error creando tablas"
        return 1
    fi
    
    echo "✅ Base de datos configurada correctamente"
}

# Función para instalar paquetes PL/SQL
install_packages() {
    echo "📦 Instalando paquetes PL/SQL..."
    
    # Verificar que Oracle esté listo
    if ! check_oracle_ready; then
        echo "❌ Oracle no está listo"
        return 1
    fi
    
    # Ejecutar tipos de objetos
    echo "🔧 Instalando tipos de objetos..."
    if docker exec oracledb bash -c "cd /opt/oracle/scripts/manual && sqlplus laura/Laura2004@localhost:1522/xepdb1 @packages/01_object_types.sql"; then
        echo "✅ Tipos de objetos instalados"
    else
        echo "❌ Error instalando tipos de objetos"
        return 1
    fi
    
    # Ejecutar paquetes
    echo "📚 Instalando paquetes..."
    if docker exec oracledb bash -c "cd /opt/oracle/scripts/manual && sqlplus laura/Laura2004@localhost:1522/xepdb1 @packages/02_packages.sql"; then
        echo "✅ Paquetes instalados"
    else
        echo "❌ Error instalando paquetes"
        return 1
    fi
    
    echo "✅ Paquetes PL/SQL instalados correctamente"
}

# Función para configurar APEX
setup_apex() {
    echo "🌐 Configurando APEX en puerto 8080..."
    
    # Verificar que Oracle esté listo
    if ! check_oracle_ready; then
        echo "❌ Oracle no está listo"
        return 1
    fi
    
    # Crear script temporal para APEX
    cat > /tmp/apex_config.sql << 'EOF'
ALTER SESSION SET CONTAINER = XEPDB1;

-- Configurar puerto HTTP 8080
BEGIN
    DBMS_XDB_CONFIG.setHTTPPort(8080);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Puerto HTTP 8080 configurado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error configurando puerto: ' || SQLERRM);
END;
/

-- Verificar si APEX está instalado
DECLARE
    apex_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO apex_count FROM dba_users WHERE username = 'APEX_PUBLIC_USER';
    
    IF apex_count > 0 THEN
        EXECUTE IMMEDIATE 'ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK';
        EXECUTE IMMEDIATE 'ALTER USER APEX_PUBLIC_USER IDENTIFIED BY ApexPublic123';
        DBMS_OUTPUT.PUT_LINE('Usuario APEX_PUBLIC_USER configurado');
    ELSE
        DBMS_OUTPUT.PUT_LINE('APEX no está instalado en esta versión de Oracle XE');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error con APEX: ' || SQLERRM);
END;
/

SELECT 'APEX configurado - verificar en: http://localhost:8080/apex' as RESULTADO FROM DUAL;

EXIT;
EOF

    # Copiar y ejecutar script
    docker cp /tmp/apex_config.sql oracledb:/tmp/
    if docker exec oracledb sqlplus sys/oracle@localhost:1522/xepdb1 as sysdba @/tmp/apex_config.sql; then
        echo "✅ APEX configurado correctamente"
    else
        echo "❌ Error configurando APEX"
        rm -f /tmp/apex_config.sql
        return 1
    fi
    
    # Limpiar archivo temporal
    rm -f /tmp/apex_config.sql
    
    echo "✅ Configuración APEX completada"
    echo "🌐 APEX disponible en: http://localhost:8080/apex"
}

# Función para ejecutar pruebas
run_tests() {
    echo "🧪 Ejecutando pruebas del sistema..."
    
    # Verificar que Oracle esté listo
    if ! check_oracle_ready; then
        echo "❌ Oracle no está listo"
        return 1
    fi
    
    # Verificar que el archivo de pruebas existe
    if [ -f "db_scripts/scripts/run_all_tests.sql" ]; then
        # Copiar script de pruebas
        docker cp db_scripts/scripts/run_all_tests.sql oracledb:/tmp/
        
        # Ejecutar pruebas
        if docker exec oracledb sqlplus laura/Laura2004@localhost:1522/xepdb1 @/tmp/run_all_tests.sql; then
            echo "✅ Pruebas ejecutadas correctamente"
        else
            echo "❌ Error ejecutando pruebas"
            return 1
        fi
    else
        echo "⚠️ Archivo de pruebas no encontrado, saltando..."
    fi
}

# Función para mostrar logs útiles
show_logs() {
    echo "📋 Mostrando logs de Oracle..."
    if docker ps | grep -q "oracledb"; then
        docker logs --tail 50 oracledb
    else
        echo "❌ Contenedor Oracle no está corriendo"
    fi
}

# Función para conectarse a Oracle
connect_oracle() {
    echo "🔌 Conectando a Oracle como usuario LAURA..."
    if check_oracle_ready; then
        docker exec -it oracledb sqlplus laura/Laura2004@localhost:1522/xepdb1
    else
        echo "❌ Oracle no está listo para conexiones"
        return 1
    fi
}

# Función de configuración completa optimizada
full_setup() {
    echo "🎯 Ejecución completa optimizada: rebuild + setup + packages + apex"
    
    # Rebuild con espera optimizada
    if ! rebuild_oracle; then
        echo "❌ Error en rebuild, abortando"
        return 1
    fi
    
    # Pequeña pausa para estabilización
    echo "⏳ Pausa de estabilización (10 segundos)..."
    sleep 10
    
    # Configuración paso a paso con verificaciones
    if setup_database; then
        echo "✅ Setup completado"
    else
        echo "❌ Error en setup"
        return 1
    fi
    
    if install_packages; then
        echo "✅ Paquetes instalados"
    else
        echo "❌ Error instalando paquetes"
        return 1
    fi
    
    if setup_apex; then
        echo "✅ APEX configurado"
    else
        echo "⚠️ Error en APEX, pero continuando..."
    fi
    
    # Pruebas opcionales
    run_tests || echo "⚠️ Pruebas fallaron, pero configuración básica completa"
    
    echo ""
    echo "🎉 ¡Configuración completa de AlmacenRC finalizada!"
    echo "🌐 APEX: http://localhost:8080/apex"
    echo "🔗 Oracle: localhost:1522/xepdb1"
    echo "👤 Usuario: laura/Laura2004"
}

# Menú principal mejorado
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
    "apex")
        setup_apex
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
        full_setup
        ;;
    *)
        echo "🔧 Script optimizado de Oracle Database - AlmacenRC"
        echo ""
        echo "Uso: $0 [comando]"
        echo ""
        echo "Comandos disponibles:"
        echo "  status    - Verificar estado actual de Oracle"
        echo "  rebuild   - Reconstruir Oracle desde cero (optimizado 2 min)"
        echo "  setup     - Configurar usuario y tablas básicas"
        echo "  packages  - Instalar paquetes PL/SQL"
        echo "  apex      - Configurar APEX en puerto 8080"
        echo "  tests     - Ejecutar pruebas del sistema"
        echo "  logs      - Mostrar logs de Oracle"
        echo "  connect   - Conectar a Oracle como usuario LAURA"
        echo "  full      - Ejecutar proceso completo optimizado"
        echo ""
        echo "Ejemplos:"
        echo "  $0 status      # Verificar estado"
        echo "  $0 full        # Configuración completa optimizada"
        echo "  $0 connect     # Conectar como LAURA"
        echo ""
        echo "🚀 Optimizado para máximo rendimiento - timeout 2 minutos"
        ;;
esac 