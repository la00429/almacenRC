-- =====================================================
-- SCRIPT MAESTRO DE PRUEBAS
-- Sistema: AlmacenRC - Gestión de Repuestos Automotrices
-- Propósito: Ejecutar todas las pruebas del sistema
-- =====================================================

SET SERVEROUTPUT ON SIZE 1000000;
SET PAGESIZE 0;
SET LINESIZE 1000;

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('██████████████████████████████████████████████████████████████');
    DBMS_OUTPUT.PUT_LINE('█                                                            █');
    DBMS_OUTPUT.PUT_LINE('█              ALMACENRC - SUITE DE PRUEBAS                 █');
    DBMS_OUTPUT.PUT_LINE('█          Sistema de Gestión de Repuestos Automotrices     █');
    DBMS_OUTPUT.PUT_LINE('█                                                            █');
    DBMS_OUTPUT.PUT_LINE('██████████████████████████████████████████████████████████████');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Fecha de ejecución: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Usuario: ' || USER);
    DBMS_OUTPUT.PUT_LINE('Base de datos: ' || SYS_CONTEXT('USERENV', 'DB_NAME'));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('══════════════════════════════════════════════════════════════');
END;
/

-- =====================================================
-- VERIFICACIÓN PREVIA DEL ENTORNO
-- =====================================================
PROMPT
PROMPT ══════════════════════════════════════════════════════════════
PROMPT                    VERIFICACIÓN DEL ENTORNO
PROMPT ══════════════════════════════════════════════════════════════

DECLARE
    v_count NUMBER;
    v_total_errors NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('🔍 VERIFICANDO ENTORNO DE BASE DE DATOS...');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Verificar tablas principales
    SELECT COUNT(*) INTO v_count FROM USER_TABLES WHERE TABLE_NAME IN ('PRODUCTOS', 'PROVEEDORES', 'MARCAS');
    DBMS_OUTPUT.PUT_LINE('📋 Tablas principales encontradas: ' || v_count || '/3');
    IF v_count < 3 THEN v_total_errors := v_total_errors + 1; END IF;
    
    -- Verificar tipos de objetos
    SELECT COUNT(*) INTO v_count FROM USER_TYPES WHERE TYPE_NAME IN ('TP_PRODUCTO', 'TP_PROVEEDOR', 'TP_DIRECTORIO');
    DBMS_OUTPUT.PUT_LINE('🏗️  Tipos de objetos encontrados: ' || v_count || '/3');
    IF v_count < 3 THEN v_total_errors := v_total_errors + 1; END IF;
    
    -- Verificar paquetes
    SELECT COUNT(*) INTO v_count FROM USER_OBJECTS WHERE OBJECT_TYPE = 'PACKAGE' AND OBJECT_NAME LIKE 'PKG_%';
    DBMS_OUTPUT.PUT_LINE('📦 Paquetes PL/SQL encontrados: ' || v_count);
    
    -- Verificar datos de prueba
    SELECT COUNT(*) INTO v_count FROM PRODUCTOS WHERE ROWNUM <= 5;
    DBMS_OUTPUT.PUT_LINE('📊 Productos de muestra: ' || v_count);
    
    DBMS_OUTPUT.PUT_LINE('');
    IF v_total_errors = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ ENTORNO VERIFICADO - LISTO PARA PRUEBAS');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠️  ADVERTENCIAS EN EL ENTORNO - ALGUNAS PRUEBAS PUEDEN FALLAR');
    END IF;
    
END;
/

-- =====================================================
-- EJECUTAR PRUEBAS DE TIPOS DE OBJETOS
-- =====================================================
PROMPT
PROMPT ══════════════════════════════════════════════════════════════
PROMPT                   PRUEBAS DE TIPOS DE OBJETOS
PROMPT ══════════════════════════════════════════════════════════════

@@test_object_types.sql

-- =====================================================
-- EJECUTAR PRUEBAS DE PAQUETES PL/SQL
-- =====================================================
PROMPT
PROMPT ══════════════════════════════════════════════════════════════
PROMPT                   PRUEBAS DE PAQUETES PL/SQL
PROMPT ══════════════════════════════════════════════════════════════

@@test_packages.sql

-- =====================================================
-- REPORTE FINAL
-- =====================================================
PROMPT
PROMPT ══════════════════════════════════════════════════════════════
PROMPT                        REPORTE FINAL
PROMPT ══════════════════════════════════════════════════════════════

DECLARE
    v_objects_count NUMBER;
    v_packages_count NUMBER;
    v_types_count NUMBER;
    v_tables_count NUMBER;
    v_invalid_objects NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('📊 RESUMEN DEL SISTEMA:');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Contar objetos por tipo
    SELECT COUNT(*) INTO v_tables_count FROM USER_TABLES;
    SELECT COUNT(*) INTO v_types_count FROM USER_TYPES;
    SELECT COUNT(*) INTO v_packages_count FROM USER_OBJECTS WHERE OBJECT_TYPE = 'PACKAGE';
    SELECT COUNT(*) INTO v_objects_count FROM USER_OBJECTS;
    SELECT COUNT(*) INTO v_invalid_objects FROM USER_OBJECTS WHERE STATUS = 'INVALID';
    
    DBMS_OUTPUT.PUT_LINE('   📋 Total de tablas: ' || v_tables_count);
    DBMS_OUTPUT.PUT_LINE('   🏗️  Total de tipos: ' || v_types_count);
    DBMS_OUTPUT.PUT_LINE('   📦 Total de paquetes: ' || v_packages_count);
    DBMS_OUTPUT.PUT_LINE('   🔧 Total de objetos: ' || v_objects_count);
    DBMS_OUTPUT.PUT_LINE('   ❌ Objetos inválidos: ' || v_invalid_objects);
    
    DBMS_OUTPUT.PUT_LINE('');
    
    IF v_invalid_objects = 0 THEN
        DBMS_OUTPUT.PUT_LINE('🎉 ¡TODAS LAS PRUEBAS COMPLETADAS!');
        DBMS_OUTPUT.PUT_LINE('✅ Sistema funcionando correctamente');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠️  ATENCIÓN: Hay objetos inválidos en el sistema');
        DBMS_OUTPUT.PUT_LINE('   Ejecuta: SELECT OBJECT_NAME, OBJECT_TYPE FROM USER_OBJECTS WHERE STATUS = ''INVALID'';');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('══════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Pruebas completadas: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('══════════════════════════════════════════════════════════════');
    
END;
/

-- Mostrar objetos inválidos si los hay
PROMPT
PROMPT 🔍 VERIFICANDO OBJETOS INVÁLIDOS...
SELECT 
    OBJECT_TYPE || ': ' || OBJECT_NAME AS "OBJETOS INVÁLIDOS"
FROM USER_OBJECTS 
WHERE STATUS = 'INVALID'
ORDER BY OBJECT_TYPE, OBJECT_NAME;

PROMPT
PROMPT ✅ SUITE DE PRUEBAS COMPLETADA 