-- Script de creación de usuario LAURA para AlmacenRC
-- Versión mejorada con manejo de errores

-- Habilitar salida de DBMS_OUTPUT
SET SERVEROUTPUT ON;

-- Conectar como SYSTEM a la PDB
ALTER SESSION SET CONTAINER = XEPDB1;

-- Verificar conexión exitosa
SELECT 'Conectado a: ' || SYS_CONTEXT('USERENV', 'CON_NAME') AS CONEXION FROM DUAL;

-- Verificar si el usuario ya existe antes de crearlo
DECLARE
    user_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM dba_users WHERE username = 'LAURA';
    
    IF user_count = 0 THEN
        -- Crear usuario con todas las especificaciones necesarias
        EXECUTE IMMEDIATE 'CREATE USER laura IDENTIFIED BY Laura2004 
                          DEFAULT TABLESPACE USERS 
                          TEMPORARY TABLESPACE TEMP
                          CONTAINER=CURRENT';
        DBMS_OUTPUT.PUT_LINE('✅ Usuario LAURA creado exitosamente');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠️ Usuario LAURA ya existe, actualizando permisos...');
        -- Cambiar password por si acaso
        EXECUTE IMMEDIATE 'ALTER USER laura IDENTIFIED BY Laura2004';
        DBMS_OUTPUT.PUT_LINE('✅ Password del usuario LAURA actualizado');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error creando usuario: ' || SQLERRM);
        RAISE;
END;
/

-- Otorgar permisos básicos (siempre, en caso de que falten)
BEGIN
    EXECUTE IMMEDIATE 'GRANT CONNECT TO laura';
    EXECUTE IMMEDIATE 'GRANT RESOURCE TO laura';
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO laura';
    EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO laura';
    EXECUTE IMMEDIATE 'GRANT CREATE TABLE TO laura';
    EXECUTE IMMEDIATE 'GRANT CREATE SEQUENCE TO laura';
    EXECUTE IMMEDIATE 'GRANT CREATE VIEW TO laura';
    EXECUTE IMMEDIATE 'GRANT CREATE PROCEDURE TO laura';
    EXECUTE IMMEDIATE 'GRANT CREATE TYPE TO laura';
    EXECUTE IMMEDIATE 'GRANT CREATE TRIGGER TO laura';
    EXECUTE IMMEDIATE 'GRANT CREATE ANY DIRECTORY TO laura';
    EXECUTE IMMEDIATE 'GRANT DROP ANY DIRECTORY TO laura';
    
    DBMS_OUTPUT.PUT_LINE('✅ Permisos otorgados correctamente');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error otorgando permisos: ' || SQLERRM);
        RAISE;
END;
/

-- Verificar creación del usuario
BEGIN
    FOR user_rec IN (SELECT username, account_status, default_tablespace 
                     FROM dba_users 
                     WHERE username = 'LAURA') LOOP
        DBMS_OUTPUT.PUT_LINE('✅ Usuario: ' || user_rec.username);
        DBMS_OUTPUT.PUT_LINE('✅ Estado: ' || user_rec.account_status);
        DBMS_OUTPUT.PUT_LINE('✅ Tablespace: ' || user_rec.default_tablespace);
    END LOOP;
END;
/

-- Confirmar cambios
COMMIT;

-- Mostrar confirmación final
SELECT '🎉 Usuario LAURA configurado correctamente en ' || SYS_CONTEXT('USERENV', 'CON_NAME') AS RESULTADO FROM DUAL;