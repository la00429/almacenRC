
CREATE OR REPLACE PACKAGE PKG_PRODUCTOS AS
    PROCEDURE PR_INSERTAR_PRODUCTO (...);
    FUNCTION FN_OBTENER_PRODUCTO (p_id_producto IN PRODUCTS.ID_PRODUCTO%TYPE) RETURN TP_PRODUCTO;
    FUNCTION FN_OBTENER_TODOS_PRODUCTOS_CON_ESTADO RETURN TBL_PRODUCTOS PIPELINED;
    PROCEDURE PR_ACTUALIZAR_PRODUCTO (...);
    PROCEDURE PR_ELIMINAR_PRODUCTO (...);

    PROCEDURE PR_MARCAR_INACTIVO_LOGICAMENTE ( p_id_producto IN PRODUCTS.ID_PRODUCTO%TYPE );
    PROCEDURE PR_MARCAR_ACTIVO_LOGICAMENTE ( p_id_producto IN PRODUCTS.ID_PRODUCTO%TYPE );

    FUNCTION FN_GET_ALL_PRODUCTS_FOR_APEX RETURN SYS_REFCURSOR;

END PKG_PRODUCTOS;
/

CREATE OR REPLACE PACKAGE BODY PKG_PRODUCTOS AS

    FUNCTION FN_OBTENER_PRODUCTO (p_id_producto IN PRODUCTS.ID_PRODUCTO%TYPE) RETURN TP_PRODUCTO IS
        v_rec PRODUCTS%ROWTYPE;
        v_activo NUMBER(1) := 1;
        v_json_data CLOB;
    BEGIN
        SELECT ID_PRODUCTO, ID_MARCA, NOMBRE, STOCK, VALOR_UNITARIO, FECHA_VENC, IVA
        INTO v_rec.ID_PRODUCTO, v_rec.ID_MARCA, v_rec.NOMBRE, v_rec.STOCK,
            v_rec.VALOR_UNITARIO, v_rec.FECHA_VENC, v_rec.IVA
        FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;

        IF G_PRODUCTOS_INACTIVOS.EXISTS(p_id_producto) THEN v_activo := 0; END IF;

        SELECT JSON_OBJECT(
                'id_producto' VALUE v_rec.ID_PRODUCTO,
                'id_marca' VALUE v_rec.ID_MARCA,
                'nombre' VALUE v_rec.NOMBRE,
                'stock' VALUE v_rec.STOCK,
                'valor_unitario' VALUE v_rec.VALOR_UNITARIO,
                'fecha_venc' VALUE TO_CHAR(v_rec.FECHA_VENC, 'YYYY-MM-DD'),
                'iva' VALUE v_rec.IVA,
                'activo_logico' VALUE v_activo
            )
        INTO v_json_data FROM DUAL;

        RETURN TP_PRODUCTO(v_rec.ID_PRODUCTO, v_rec.ID_MARCA, v_rec.NOMBRE,
                        v_rec.STOCK, v_rec.VALOR_UNITARIO, v_rec.FECHA_VENC,
                        v_rec.IVA, v_activo, v_json_data);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN NULL;
        WHEN OTHERS THEN RAISE;
    END FN_OBTENER_PRODUCTO;

    FUNCTION FN_OBTENER_TODOS_PRODUCTOS_CON_ESTADO RETURN TBL_PRODUCTOS PIPELINED IS
        v_activo NUMBER(1);
        v_json_data CLOB;
    BEGIN
        FOR r IN (SELECT ID_PRODUCTO, ID_MARCA, NOMBRE, STOCK, VALOR_UNITARIO, FECHA_VENC, IVA FROM PRODUCTOS) LOOP
            v_activo := 1;
            IF G_PRODUCTOS_INACTIVOS.EXISTS(r.ID_PRODUCTO) THEN v_activo := 0; END IF;

            SELECT JSON_OBJECT(
                    'id_producto' VALUE r.ID_PRODUCTO,
                    'id_marca' VALUE r.ID_MARCA,
                    'nombre' VALUE r.NOMBRE,
                    'stock' VALUE r.STOCK,
                    'valor_unitario' VALUE r.VALOR_UNITARIO,
                    'fecha_venc' VALUE TO_CHAR(r.FECHA_VENC, 'YYYY-MM-DD'),
                    'iva' VALUE r.IVA,
                    'activo_logico' VALUE v_activo
                )
            INTO v_json_data FROM DUAL;

            PIPE ROW (TP_PRODUCTO(r.ID_PRODUCTO, r.ID_MARCA, r.NOMBRE, r.STOCK,
                                r.VALOR_UNITARIO, r.FECHA_VENC, r.IVA, v_activo, v_json_data));
        END LOOP;
        RETURN;
    END FN_OBTENER_TODOS_PRODUCTOS_CON_ESTADO;

    FUNCTION FN_GET_ALL_PRODUCTS_FOR_APEX RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT
                P.ID_PRODUCTO, P.ID_MARCA, P.NOMBRE, P.STOCK,
                P.VALOR_UNITARIO, P.FECHA_VENC, P.IVA,
                CASE WHEN G_PRODUCTOS_INACTIVOS.EXISTS(P.ID_PRODUCTO) THEN 0 ELSE 1 END AS ACTIVO_LOGICO,
                JSON_OBJECT(
                    'id_producto' VALUE P.ID_PRODUCTO,
                    'id_marca' VALUE P.ID_MARCA,
                    'nombre' VALUE P.NOMBRE,
                    'stock' VALUE P.STOCK,
                    'valor_unitario' VALUE P.VALOR_UNITARIO,
                    'fecha_venc' VALUE TO_CHAR(P.FECHA_VENC, 'YYYY-MM-DD'),
                    'iva' VALUE P.IVA,
                    'activo_logico' VALUE (CASE WHEN G_PRODUCTOS_INACTIVOS.EXISTS(P.ID_PRODUCTO) THEN 0 ELSE 1 END)
                ) AS JSON_DATA_COL 
            FROM PRODUCTOS P;
        RETURN v_cursor;
    END;
END PKG_PRODUCTOS;
/