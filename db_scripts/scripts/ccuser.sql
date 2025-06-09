-- Conectar como SYSTEM a la PDB
ALTER SESSION SET CONTAINER = XEPDB1;

-- Verificar si el usuario ya existe antes de crearlo
DECLARE
    user_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM dba_users WHERE username = 'LAURA';
    
    IF user_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER laura IDENTIFIED BY Laura2004 CONTAINER=CURRENT';
        DBMS_OUTPUT.PUT_LINE('Usuario LAURA creado exitosamente');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Usuario LAURA ya existe, omitiendo creación');
    END IF;
END;
/

-- Otorgar permisos (siempre, en caso de que falten)
GRANT CONNECT TO laura;
GRANT RESOURCE TO laura;
GRANT CREATE SESSION TO laura;
GRANT UNLIMITED TABLESPACE TO laura;
GRANT CREATE TABLE TO laura;
GRANT CREATE SEQUENCE TO laura;
GRANT CREATE VIEW TO laura;
GRANT CREATE PROCEDURE TO laura;
GRANT CREATE TYPE TO laura;
GRANT CREATE TRIGGER TO laura;

-- Confirmar cambios
COMMIT;
EXIT;