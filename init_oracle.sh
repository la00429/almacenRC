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
        if docker exec oracledb bash -c "echo 'SELECT 1 FROM DUAL;' | sqlplus -s sys/oracle@localhost:1521/xepdb1 as sysdba 2>/dev/null" | grep -q "1" 2>/dev/null; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    return 1
}

# Función para mostrar el estado de Oracle
check_oracle_status() {
    echo "🔍 Verificando estado completo de Oracle..."
    
    # Verificar si el contenedor está corriendo
    if ! docker ps | grep -q "oracledb"; then
        echo "❌ Contenedor Oracle no está corriendo"
        echo "💡 Ejecuta: docker-compose up -d"
        return 1
    fi
    
    echo "✅ Contenedor Oracle está corriendo"
    
    # Verificar conectividad básica con timeout
    echo "🔗 Verificando conectividad con SYS..."
    if check_oracle_ready; then
        echo "✅ Conectividad SYS OK"
        
        # Verificar usuario laura
        echo "👤 Verificando usuario LAURA..."
        local user_check_output
        user_check_output=$(docker exec oracledb bash -c "echo 'SELECT USER FROM DUAL;' | sqlplus -s laura/Laura2004@localhost:1521/xepdb1 2>&1")
        
        if [[ "$user_check_output" =~ "LAURA" && ! "$user_check_output" =~ (ORA-|ERROR|TNS:|SP2-) ]]; then
            echo "✅ Usuario LAURA OK"
            
            # Verificar tablas básicas
            echo "🗄️ Verificando tablas..."
            local table_count_output
            table_count_output=$(docker exec oracledb bash -c "echo 'SELECT COUNT(*) FROM user_tables;' | sqlplus -s laura/Laura2004@localhost:1521/xepdb1 2>&1")
            
            if [[ ! "$table_count_output" =~ (ORA-|ERROR|TNS:|SP2-) ]]; then
                local table_count
                table_count=$(echo "$table_count_output" | grep -E "^[[:space:]]*[0-9]+[[:space:]]*$" | tr -d '[:space:]' || echo "0")
                echo "📊 Tablas encontradas: $table_count"
                
                if [ "$table_count" -gt "0" ]; then
                    echo "✅ Base de datos completamente configurada"
                    
                    # Verificar paquetes PL/SQL
                    echo "📦 Verificando paquetes PL/SQL..."
                    local package_count_output
                    package_count_output=$(docker exec oracledb bash -c "echo \"SELECT COUNT(*) FROM user_objects WHERE object_type IN ('PACKAGE', 'PACKAGE BODY', 'TYPE');\" | sqlplus -s laura/Laura2004@localhost:1521/xepdb1 2>&1")
                    
                    if [[ ! "$package_count_output" =~ (ORA-|ERROR|TNS:|SP2-) ]]; then
                        local package_count
                        package_count=$(echo "$package_count_output" | grep -E "^[[:space:]]*[0-9]+[[:space:]]*$" | tr -d '[:space:]' || echo "0")
                        echo "📚 Objetos PL/SQL: $package_count"
                        
                        if [ "$package_count" -gt "0" ]; then
                            echo "✅ Paquetes PL/SQL instalados"
                        else
                            echo "⚠️ No hay paquetes PL/SQL instalados"
                            echo "💡 Ejecuta: $0 packages"
                        fi
                    fi
                    
                    return 0
                else
                    echo "⚠️ Usuario OK pero no hay tablas creadas"
                    echo "💡 Ejecuta: $0 setup"
                    return 2
                fi
            else
                echo "❌ Error verificando tablas:"
                echo "$table_count_output"
                return 4
            fi
        else
            echo "❌ Usuario LAURA no disponible"
            echo "Salida de diagnóstico:"
            echo "$user_check_output"
            echo "💡 Ejecuta: $0 setup"
            return 3
        fi
    else
        echo "❌ Error de conectividad con Oracle"
        echo "💡 Oracle puede estar iniciándose. Espera unos minutos o ejecuta: $0 rebuild"
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
    
    # Crear usuario LAURA con verificación robusta
    echo "👤 Creando usuario LAURA..."
    
    # Ejecutar comando y capturar salida
    local create_user_output
    create_user_output=$(docker exec oracledb bash -c "cd /opt/oracle/scripts/manual/scripts && sqlplus -s sys/oracle@localhost:1521/xepdb1 as sysdba @ccuser.sql" 2>&1)
    local create_user_exit_code=$?
    
    # Verificar si hay errores SQL
    if [[ $create_user_exit_code -ne 0 || "$create_user_output" =~ (ORA-|ERROR|TNS:|SP2-|PLS-) ]]; then
        echo "❌ Error creando usuario LAURA:"
        echo "$create_user_output"
        return 1
    fi
    
    # Verificar que el usuario fue creado exitosamente
    echo "🔍 Verificando creación del usuario LAURA..."
    local user_check_output
    user_check_output=$(docker exec oracledb bash -c "echo 'SELECT USER FROM DUAL;' | sqlplus -s laura/Laura2004@localhost:1521/xepdb1 2>&1")
    
    if [[ "$user_check_output" =~ "LAURA" && ! "$user_check_output" =~ (ORA-|ERROR|TNS:|SP2-) ]]; then
        echo "✅ Usuario LAURA creado y verificado"
    else
        echo "❌ Usuario LAURA no fue creado correctamente"
        echo "Salida de verificación:"
        echo "$user_check_output"
        echo "Salida de creación:"
        echo "$create_user_output"
        return 1
    fi
    
    # Crear tablas básicas con verificación robusta
    echo "🏗️ Creando tablas básicas..."
    
    local create_tables_output
    create_tables_output=$(docker exec oracledb bash -c "cd /opt/oracle/scripts/manual/scripts && sqlplus -s laura/Laura2004@localhost:1521/xepdb1 @_crebas.sql" 2>&1)
    local create_tables_exit_code=$?
    
    # Verificar si hay errores SQL
    if [[ $create_tables_exit_code -ne 0 || "$create_tables_output" =~ (ORA-|ERROR|TNS:|SP2-|PLS-) ]]; then
        echo "❌ Error creando tablas:"
        echo "$create_tables_output"
        return 1
    fi
    
    # Verificar que las tablas fueron creadas
    echo "🔍 Verificando creación de tablas..."
    local table_count_output
    table_count_output=$(docker exec oracledb bash -c "echo 'SELECT COUNT(*) FROM user_tables;' | sqlplus -s laura/Laura2004@localhost:1521/xepdb1 2>&1")
    
    if [[ "$table_count_output" =~ (ORA-|ERROR|TNS:|SP2-) ]]; then
        echo "❌ Error verificando tablas:"
        echo "$table_count_output"
        return 1
    fi
    
    local table_count
    table_count=$(echo "$table_count_output" | grep -E "^[[:space:]]*[0-9]+[[:space:]]*$" | tr -d '[:space:]' || echo "0")
    
    if [ "$table_count" -gt "0" ]; then
        echo "✅ Tablas creadas correctamente ($table_count tablas)"
        
        # Mostrar lista de tablas creadas
        echo "📋 Tablas creadas:"
        docker exec oracledb bash -c "echo 'SELECT table_name FROM user_tables ORDER BY table_name;' | sqlplus -s laura/Laura2004@localhost:1521/xepdb1" 2>/dev/null | grep -v "^$" | head -10
    else
        echo "❌ No se crearon tablas correctamente"
        echo "Salida del comando de creación:"
        echo "$create_tables_output"
        echo "Salida de verificación:"
        echo "$table_count_output"
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
    
    # Verificar que el usuario LAURA existe
    echo "🔍 Verificando usuario LAURA..."
    local user_check_output
    user_check_output=$(docker exec oracledb bash -c "echo 'SELECT USER FROM DUAL;' | sqlplus -s laura/Laura2004@localhost:1521/xepdb1 2>&1")
    
    if [[ ! "$user_check_output" =~ "LAURA" || "$user_check_output" =~ (ORA-|ERROR|TNS:|SP2-) ]]; then
        echo "❌ Usuario LAURA no está disponible:"
        echo "$user_check_output"
        echo "💡 Ejecuta primero: $0 setup"
        return 1
    fi
    
    # Ejecutar tipos de objetos con verificación robusta
    echo "🔧 Instalando tipos de objetos..."
    local types_output
    types_output=$(docker exec oracledb bash -c "cd /opt/oracle/scripts/manual && sqlplus -s laura/Laura2004@localhost:1521/xepdb1 @packages/01_object_types.sql" 2>&1)
    local types_exit_code=$?
    
    if [[ $types_exit_code -ne 0 || "$types_output" =~ (ORA-|ERROR|TNS:|SP2-|PLS-) ]]; then
        echo "❌ Error instalando tipos de objetos:"
        echo "$types_output"
        return 1
    fi
    echo "✅ Tipos de objetos instalados"
    
    # Ejecutar paquetes con verificación robusta
    echo "📚 Instalando paquetes..."
    local packages_output
    packages_output=$(docker exec oracledb bash -c "cd /opt/oracle/scripts/manual && sqlplus -s laura/Laura2004@localhost:1521/xepdb1 @packages/02_packages.sql" 2>&1)
    local packages_exit_code=$?
    
    if [[ $packages_exit_code -ne 0 || "$packages_output" =~ (ORA-|ERROR|TNS:|SP2-|PLS-) ]]; then
        echo "❌ Error instalando paquetes:"
        echo "$packages_output"
        return 1
    fi
    echo "✅ Paquetes instalados"
    
    # Verificar instalación de paquetes
    echo "🔍 Verificando paquetes instalados..."
    local package_check_output
    package_check_output=$(docker exec oracledb bash -c "echo \"SELECT COUNT(*) FROM user_objects WHERE object_type IN ('PACKAGE', 'PACKAGE BODY', 'TYPE');\" | sqlplus -s laura/Laura2004@localhost:1521/xepdb1 2>&1")
    
    if [[ ! "$package_check_output" =~ (ORA-|ERROR|TNS:|SP2-) ]]; then
        local object_count
        object_count=$(echo "$package_check_output" | grep -E "^[[:space:]]*[0-9]+[[:space:]]*$" | tr -d '[:space:]' || echo "0")
        if [ "$object_count" -gt "0" ]; then
            echo "✅ Verificación exitosa: $object_count objetos instalados"
        fi
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
    
    # Crear script temporal para APEX con mejor manejo de errores
    cat > /tmp/apex_config.sql << 'EOF'
WHENEVER SQLERROR EXIT SQL.SQLCODE;
WHENEVER OSERROR EXIT FAILURE;

ALTER SESSION SET CONTAINER = XEPDB1;

-- Configurar puerto HTTP 8080
BEGIN
    DBMS_XDB_CONFIG.setHTTPPort(8080);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Puerto HTTP 8080 configurado exitosamente');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR configurando puerto: ' || SQLERRM);
        RAISE;
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
        DBMS_OUTPUT.PUT_LINE('Usuario APEX_PUBLIC_USER configurado exitosamente');
    ELSE
        DBMS_OUTPUT.PUT_LINE('INFO: APEX no está instalado en esta versión de Oracle XE');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR con APEX: ' || SQLERRM);
        RAISE;
END;
/

-- Verificar configuración HTTP
DECLARE
    http_port NUMBER;
BEGIN
    SELECT EXTRACTVALUE(VALUE(d), '/httpconfig/http-port/text()') AS http_port
    INTO http_port
    FROM TABLE(XMLSequence(XMLType(
        HTTPURITYPE('http://localhost:8080').getClob()
    ).extract('//httpconfig'))) d
    WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Puerto HTTP actual: ' || NVL(TO_CHAR(http_port), '8080'));
EXCEPTION
    WHEN OTHERS THEN
        -- No es crítico si no podemos verificar el puerto
        DBMS_OUTPUT.PUT_LINE('INFO: No se pudo verificar puerto HTTP - probablemente normal');
END;
/

SELECT 'APEX - Configuración completada' as RESULTADO FROM DUAL;

EXIT;
EOF

    # Copiar y ejecutar script con captura de errores
    docker cp /tmp/apex_config.sql oracledb:/tmp/
    
    echo "🔧 Ejecutando configuración de APEX..."
    local apex_output
    apex_output=$(docker exec oracledb sqlplus -s sys/oracle@localhost:1521/xepdb1 as sysdba @/tmp/apex_config.sql 2>&1)
    local apex_exit_code=$?
    
    # Verificar si hay errores
    if [[ $apex_exit_code -ne 0 || "$apex_output" =~ (ORA-|ERROR|TNS:|SP2-|PLS-) ]]; then
        echo "❌ Error configurando APEX:"
        echo "$apex_output"
        rm -f /tmp/apex_config.sql
        return 1
    fi
    
    # Mostrar resultado de la configuración
    echo "📋 Resultado de configuración APEX:"
    echo "$apex_output"
    
    # Verificar puerto HTTP
    echo "🔍 Verificando puerto HTTP 8080..."
    local port_check_output
    port_check_output=$(docker exec oracledb bash -c "echo 'SELECT DBMS_XDB.getHttpPort() FROM DUAL;' | sqlplus -s sys/oracle@localhost:1521/xepdb1 as sysdba 2>&1")
    
    if [[ ! "$port_check_output" =~ (ORA-|ERROR|TNS:|SP2-) ]]; then
        echo "✅ Verificación de puerto completada"
        echo "$port_check_output"
    fi
    
    # Limpiar archivo temporal
    rm -f /tmp/apex_config.sql
    
    echo "✅ Configuración APEX completada"
    echo "🌐 APEX debería estar disponible en: http://localhost:8080/apex"
    echo "💡 Si APEX no está instalado en Oracle XE, este paso es informativo"
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
        if docker exec oracledb sqlplus laura/Laura2004@localhost:1521/xepdb1 @/tmp/run_all_tests.sql; then
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
        docker exec -it oracledb sqlplus laura/Laura2004@localhost:1521/xepdb1
    else
        echo "❌ Oracle no está listo para conexiones"
        return 1
    fi
}

# Función de diagnóstico completo
diagnose() {
    echo "🔍 Ejecutando diagnóstico completo del sistema..."
    echo ""
    
    # Estado de contenedores
    echo "🐳 Estado de contenedores Docker:"
    docker ps -a | grep -E "(CONTAINER|oracle)" || echo "No hay contenedores Oracle"
    echo ""
    
    # Logs recientes
    echo "📋 Logs recientes de Oracle (últimas 10 líneas):"
    if docker ps | grep -q "oracledb"; then
        docker logs --tail 10 oracledb 2>/dev/null || echo "No se pueden obtener logs"
    else
        echo "Contenedor Oracle no está corriendo"
    fi
    echo ""
    
    # Estado detallado
    check_oracle_status
    echo ""
    
    # Información de conectividad
    echo "🌐 Información de conectividad:"
    echo "  • Host: localhost"
    echo "  • Puerto: 1522"
    echo "  • SID: xepdb1"
    echo "  • Usuario SYS: sys/oracle"
    echo "  • Usuario LAURA: laura/Laura2004"
    echo ""
    
    # Verificar puertos
    echo "🔌 Verificando puertos:"
    if command -v netstat >/dev/null 2>&1; then
        netstat -ln | grep ":1522" && echo "✅ Puerto 1522 está abierto" || echo "❌ Puerto 1522 no está disponible"
        netstat -ln | grep ":8080" && echo "✅ Puerto 8080 está abierto" || echo "⚠️ Puerto 8080 no está disponible"
    else
        echo "⚠️ netstat no disponible, no se pueden verificar puertos"
    fi
    echo ""
    
    # Espacio en disco
    echo "💾 Espacio en disco:"
    df -h / | tail -1
    echo ""
    
    # Recomendaciones
    echo "💡 Recomendaciones:"
    echo "  • Si Oracle no responde: $0 rebuild"
    echo "  • Si no hay usuario LAURA: $0 setup"
    echo "  • Para configuración completa: $0 full"
    echo "  • Para ver logs detallados: $0 logs"
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
    echo "🔗 Oracle: localhost:1522/xepdb1 (externo), localhost:1521/xepdb1 (interno)"
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
    "diagnose"|"diag")
        diagnose
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
        echo "  diagnose  - Ejecutar diagnóstico completo del sistema"
        echo ""
        echo "Comandos de diagnóstico:"
        echo "  diag      - Alias para diagnose"
        echo ""
        echo "Ejemplos:"
        echo "  $0 status      # Verificar estado rápido"
        echo "  $0 diagnose    # Diagnóstico completo detallado"
        echo "  $0 full        # Configuración completa optimizada"
        echo "  $0 connect     # Conectar como LAURA"
        echo ""
        echo "🚀 Versión mejorada con detección robusta de errores"
        echo "⏱️ Timeout optimizado: 2 minutos máximo"
        ;;
esac 