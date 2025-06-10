CREATE OR REPLACE PACKAGE PKG_DIRECTORIO AS
    -- Función de utilidad para generar clave compuesta
    FUNCTION FN_GENERAR_CLAVE_COMPUESTA (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    ) RETURN VARCHAR2;
    
    -- Procedimientos CRUD
    PROCEDURE PR_INSERTAR_DIRECTORIO (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    );
    
    FUNCTION FN_OBTENER_DIRECTORIO (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    ) RETURN TP_DIRECTORIO;
    
    FUNCTION FN_OBTENER_TODOS_DIRECTORIOS_CON_ESTADO RETURN TBL_DIRECTORIOS PIPELINED;
    
    PROCEDURE PR_ELIMINAR_DIRECTORIO (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    );
    
    -- Gestión de estado lógico
    PROCEDURE PR_MARCAR_INACTIVO_LOGICAMENTE (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    );
    PROCEDURE PR_MARCAR_ACTIVO_LOGICAMENTE (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    );
    
    -- Funciones de consulta específicas
    FUNCTION FN_OBTENER_PROVEEDORES_DE_PRODUCTO (p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE) RETURN SYS_REFCURSOR;

    FUNCTION FN_OBTENER_PRODUCTOS_DE_PROVEEDOR (p_codigo IN DIRECTORIO.CODIGO%TYPE) RETURN SYS_REFCURSOR;
    


    FUNCTION OBTENER_TODOS RETURN SYS_REFCURSOR;

END PKG_DIRECTORIO;
/

CREATE OR REPLACE PACKAGE BODY PKG_DIRECTORIO AS

    FUNCTION FN_GENERAR_CLAVE_COMPUESTA (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    ) RETURN VARCHAR2 IS
        v_clave VARCHAR2(50);
    BEGIN
        v_clave := p_id_producto || '-' || p_codigo;
        RETURN v_clave;
    END FN_GENERAR_CLAVE_COMPUESTA;

    PROCEDURE PR_INSERTAR_DIRECTORIO (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    ) IS
        v_count NUMBER;
    BEGIN
        -- Verificar que el producto existe
        SELECT COUNT(*) INTO v_count FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20019, 'Error: No existe producto con ID ' || p_id_producto);
        END IF;
        
        -- Verificar que el proveedor existe
        SELECT COUNT(*) INTO v_count FROM PROVEEDORES WHERE CODIGO = p_codigo;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20020, 'Error: No existe proveedor con código ' || p_codigo);
        END IF;

        INSERT INTO DIRECTORIO (ID_PRODUCTO, CODIGO)
        VALUES (p_id_producto, p_codigo);
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Relación directorio insertada exitosamente: Producto ' || p_id_producto || ' - Proveedor ' || p_codigo);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20021, 'Error: Ya existe la relación Producto ' || p_id_producto || ' - Proveedor ' || p_codigo);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20022, 'Error al insertar relación directorio: ' || SQLERRM);
    END PR_INSERTAR_DIRECTORIO;

    FUNCTION FN_OBTENER_DIRECTORIO (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    ) RETURN TP_DIRECTORIO IS
        v_rec DIRECTORIO%ROWTYPE;
        v_activo NUMBER(1) := 1;
        v_json_data CLOB;
        v_clave VARCHAR2(50);
    BEGIN
        SELECT ID_PRODUCTO, CODIGO
        INTO v_rec.ID_PRODUCTO, v_rec.CODIGO
        FROM DIRECTORIO WHERE ID_PRODUCTO = p_id_producto AND CODIGO = p_codigo;

        -- Verificar estado lógico usando clave compuesta
        v_clave := FN_GENERAR_CLAVE_COMPUESTA(p_id_producto, p_codigo);
        IF PKG_GLOBAL_STATE.G_DIRECTORIOS_INACTIVOS.EXISTS(v_clave) THEN 
            v_activo := 0; 
        END IF;

        -- Generar JSON
        SELECT JSON_OBJECT(
                'id_producto' VALUE v_rec.ID_PRODUCTO,
                'codigo' VALUE v_rec.CODIGO,
                'activo_logico' VALUE v_activo
            )
        INTO v_json_data FROM DUAL;

        RETURN TP_DIRECTORIO(v_rec.ID_PRODUCTO, v_rec.CODIGO, v_activo, v_json_data);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            RETURN NULL;
        WHEN OTHERS THEN 
            RAISE;
    END FN_OBTENER_DIRECTORIO;

    FUNCTION FN_OBTENER_TODOS_DIRECTORIOS_CON_ESTADO RETURN TBL_DIRECTORIOS PIPELINED IS
        v_activo NUMBER(1);
        v_json_data CLOB;
        v_clave VARCHAR2(50);
    BEGIN
        FOR r IN (SELECT ID_PRODUCTO, CODIGO FROM DIRECTORIO) LOOP
            v_activo := 1;
            v_clave := FN_GENERAR_CLAVE_COMPUESTA(r.ID_PRODUCTO, r.CODIGO);
            IF PKG_GLOBAL_STATE.G_DIRECTORIOS_INACTIVOS.EXISTS(v_clave) THEN 
                v_activo := 0; 
            END IF;

            SELECT JSON_OBJECT(
                    'id_producto' VALUE r.ID_PRODUCTO,
                    'codigo' VALUE r.CODIGO,
                    'activo_logico' VALUE v_activo
                )
            INTO v_json_data FROM DUAL;

            PIPE ROW (TP_DIRECTORIO(r.ID_PRODUCTO, r.CODIGO, v_activo, v_json_data));
        END LOOP;
        RETURN;
    END FN_OBTENER_TODOS_DIRECTORIOS_CON_ESTADO;

    PROCEDURE PR_ELIMINAR_DIRECTORIO (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    ) IS
        v_count NUMBER;
        v_clave VARCHAR2(50);
    BEGIN
        -- Verificar que la relación existe
        SELECT COUNT(*) INTO v_count FROM DIRECTORIO WHERE ID_PRODUCTO = p_id_producto AND CODIGO = p_codigo;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20023, 'Error: No existe la relación Producto ' || p_id_producto || ' - Proveedor ' || p_codigo);
        END IF;

        -- Eliminar físicamente
        DELETE FROM DIRECTORIO WHERE ID_PRODUCTO = p_id_producto AND CODIGO = p_codigo;
        
        -- También remover del estado lógico si existía
        v_clave := FN_GENERAR_CLAVE_COMPUESTA(p_id_producto, p_codigo);
        IF PKG_GLOBAL_STATE.G_DIRECTORIOS_INACTIVOS.EXISTS(v_clave) THEN
            PKG_GLOBAL_STATE.G_DIRECTORIOS_INACTIVOS.DELETE(v_clave);
        END IF;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Relación directorio eliminada exitosamente: Producto ' || p_id_producto || ' - Proveedor ' || p_codigo);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20024, 'Error al eliminar relación directorio: ' || SQLERRM);
    END PR_ELIMINAR_DIRECTORIO;

    PROCEDURE PR_MARCAR_INACTIVO_LOGICAMENTE (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    ) IS
        v_count NUMBER;
        v_clave VARCHAR2(50);
    BEGIN
        -- Verificar que la relación existe
        SELECT COUNT(*) INTO v_count FROM DIRECTORIO WHERE ID_PRODUCTO = p_id_producto AND CODIGO = p_codigo;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20025, 'Error: No existe la relación Producto ' || p_id_producto || ' - Proveedor ' || p_codigo);
        END IF;

        v_clave := FN_GENERAR_CLAVE_COMPUESTA(p_id_producto, p_codigo);
        PKG_GLOBAL_STATE.G_DIRECTORIOS_INACTIVOS(v_clave) := 1;
        DBMS_OUTPUT.PUT_LINE('Relación directorio marcada como inactiva lógicamente: Producto ' || p_id_producto || ' - Proveedor ' || p_codigo);
    END PR_MARCAR_INACTIVO_LOGICAMENTE;

    PROCEDURE PR_MARCAR_ACTIVO_LOGICAMENTE (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    ) IS
        v_clave VARCHAR2(50);
    BEGIN
        v_clave := FN_GENERAR_CLAVE_COMPUESTA(p_id_producto, p_codigo);
        IF PKG_GLOBAL_STATE.G_DIRECTORIOS_INACTIVOS.EXISTS(v_clave) THEN
            PKG_GLOBAL_STATE.G_DIRECTORIOS_INACTIVOS.DELETE(v_clave);
        END IF;
        DBMS_OUTPUT.PUT_LINE('Relación directorio marcada como activa lógicamente: Producto ' || p_id_producto || ' - Proveedor ' || p_codigo);
    END PR_MARCAR_ACTIVO_LOGICAMENTE;

    FUNCTION FN_OBTENER_PROVEEDORES_DE_PRODUCTO (
    p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE
) RETURN SYS_REFCURSOR IS
    v_cursor SYS_REFCURSOR;
    v_sql VARCHAR2(1000);
BEGIN
    v_sql := '
        SELECT 
            D.CODIGO, P.NOMBRE, P.DIRECCION, P.TELEFONO, P.EMAIL,
            CASE 
                WHEN PKG_GLOBAL_STATE.G_DIRECTORIOS_INACTIVOS.EXISTS(PKG_DIRECTORIO.FN_GENERAR_CLAVE_COMPUESTA(:1, D.CODIGO)) 
                THEN 0 ELSE 1 
            END AS RELACION_ACTIVA
        FROM DIRECTORIO D
        INNER JOIN PROVEEDORES P ON D.CODIGO = P.CODIGO
        WHERE D.ID_PRODUCTO = :1';

    OPEN v_cursor FOR v_sql USING p_id_producto;
    RETURN v_cursor;
END FN_OBTENER_PROVEEDORES_DE_PRODUCTO;


FUNCTION FN_OBTENER_PRODUCTOS_DE_PROVEEDOR (
    p_codigo IN DIRECTORIO.CODIGO%TYPE
) RETURN SYS_REFCURSOR IS
    v_cursor SYS_REFCURSOR;
    v_sql VARCHAR2(1000);
BEGIN
    v_sql := '
        SELECT 
            D.ID_PRODUCTO, P.NOMBRE, P.STOCK, P.VALOR_UNITARIO, P.FECHA_VENC, P.IVA,
            CASE 
                WHEN PKG_GLOBAL_STATE.G_DIRECTORIOS_INACTIVOS.EXISTS(PKG_DIRECTORIO.FN_GENERAR_CLAVE_COMPUESTA(D.ID_PRODUCTO, :1)) 
                THEN 0 ELSE 1 
            END AS RELACION_ACTIVA
        FROM DIRECTORIO D
        INNER JOIN PRODUCTOS P ON D.ID_PRODUCTO = P.ID_PRODUCTO
        WHERE D.CODIGO = :1';

    OPEN v_cursor FOR v_sql USING p_codigo;
    RETURN v_cursor;
END FN_OBTENER_PRODUCTOS_DE_PROVEEDOR;



    FUNCTION OBTENER_TODOS RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT 
                ID_PRODUCTO, CODIGO
            FROM DIRECTORIO
            ORDER BY ID_PRODUCTO, CODIGO;
        RETURN v_cursor;
    END OBTENER_TODOS;

END PKG_DIRECTORIO;
/