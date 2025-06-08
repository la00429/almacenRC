-- =====================================================
-- SCRIPT DE INICIALIZACIÓN PARA ALMACENRC
-- Sistema: Gestión de Inventario de Repuestos Automotrices
-- =====================================================

-- Conectar como SYSTEM
CONNECT SYSTEM/oracle@localhost:1521/XE;

-- Crear usuario de aplicación
CREATE USER laura IDENTIFIED BY Laura2004;

-- Otorgar permisos
GRANT CONNECT, RESOURCE TO laura;
GRANT CREATE SESSION TO laura;
GRANT UNLIMITED TABLESPACE TO laura;
GRANT CREATE VIEW TO laura;
GRANT CREATE PROCEDURE TO laura;
GRANT CREATE SEQUENCE TO laura;
GRANT CREATE TRIGGER TO laura;

-- Conectar como usuario de aplicación
CONNECT laura/Laura2004@localhost:1521/XE;

-- Habilitar salida
SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO CONFIGURACIÓN ALMACENRC ===');
    DBMS_OUTPUT.PUT_LINE('Usuario: ' || USER);
    DBMS_OUTPUT.PUT_LINE('Fecha: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
END;
/

-- Ejecutar scripts en orden
@@pl_sql/01_object_types.sql
@@scripts/_crebas.sql
@@pl_sql/02_packages.sql
@@03_initial_data.sql

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== CONFIGURACIÓN COMPLETADA ===');
    DBMS_OUTPUT.PUT_LINE('Sistema listo para APEX');
END;
/ 