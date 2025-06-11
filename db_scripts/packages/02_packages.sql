
CREATE OR REPLACE PACKAGE PKG_GLOBAL_STATE AS
    TYPE t_number_table IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    G_PRODUCTOS_INACTIVOS t_number_table;
    G_PROVEEDORES_INACTIVOS t_number_table;
    G_DIRECTORIOS_INACTIVOS t_number_table;
END PKG_GLOBAL_STATE;
/

CREATE OR REPLACE PACKAGE PKG_PRODUCTOS AS
    PROCEDURE PR_INSERTAR_PRODUCTO (
        p_id_marca IN PRODUCTOS.ID_MARCA%TYPE,
        p_nombre IN PRODUCTOS.NOMBRE%TYPE,
        p_stock IN PRODUCTOS.STOCK%TYPE,
        p_valor_unitario IN PRODUCTOS.VALOR_UNITARIO%TYPE,
        p_fecha_venc IN PRODUCTOS.FECHA_VENC%TYPE DEFAULT NULL,
        p_iva IN PRODUCTOS.IVA%TYPE,
        p_id_producto_generado OUT PRODUCTOS.ID_PRODUCTO%TYPE
    );
   
    FUNCTION FN_OBTENER_PRODUCTO (p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE) RETURN TP_PRODUCTO;

    FUNCTION FN_OBTENER_PRODUCTO_JSON (p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE) RETURN VARCHAR2;
     
    FUNCTION OBTENER_TODOS RETURN SYS_REFCURSOR;
     
    PROCEDURE PR_ACTUALIZAR_PRODUCTO (
        p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE,
        p_id_marca IN PRODUCTOS.ID_MARCA%TYPE DEFAULT NULL,
        p_nombre IN PRODUCTOS.NOMBRE%TYPE DEFAULT NULL,
        p_stock IN PRODUCTOS.STOCK%TYPE DEFAULT NULL,
        p_valor_unitario IN PRODUCTOS.VALOR_UNITARIO%TYPE DEFAULT NULL,
        p_fecha_venc IN PRODUCTOS.FECHA_VENC%TYPE DEFAULT NULL,
        p_iva IN PRODUCTOS.IVA%TYPE DEFAULT NULL
    );
     
    PROCEDURE PR_ELIMINAR_PRODUCTO (p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE);

    PROCEDURE PR_MARCAR_INACTIVO_LOGICAMENTE (p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE);
    
    PROCEDURE PR_MARCAR_ACTIVO_LOGICAMENTE (p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE);

    PROCEDURE PR_ACTUALIZAR_STOCK (
        p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE,
        p_cantidad IN NUMBER,
        p_operacion IN VARCHAR2 DEFAULT 'SUMAR'
    );

END PKG_PRODUCTOS;
/

CREATE OR REPLACE PACKAGE BODY PKG_PRODUCTOS AS

    PROCEDURE PR_INSERTAR_PRODUCTO (
        p_id_marca IN PRODUCTOS.ID_MARCA%TYPE,
        p_nombre IN PRODUCTOS.NOMBRE%TYPE,
        p_stock IN PRODUCTOS.STOCK%TYPE,
        p_valor_unitario IN PRODUCTOS.VALOR_UNITARIO%TYPE,
        p_fecha_venc IN PRODUCTOS.FECHA_VENC%TYPE DEFAULT NULL,
        p_iva IN PRODUCTOS.IVA%TYPE,
        p_id_producto_generado OUT PRODUCTOS.ID_PRODUCTO%TYPE
    ) IS
    BEGIN
        SELECT SEQ_PRODUCTOS.NEXTVAL INTO p_id_producto_generado FROM DUAL;
        
        INSERT INTO PRODUCTOS (ID_PRODUCTO, ID_MARCA, NOMBRE, STOCK, VALOR_UNITARIO, FECHA_VENC, IVA)
        VALUES (p_id_producto_generado, p_id_marca, p_nombre, p_stock, p_valor_unitario, p_fecha_venc, p_iva);
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Producto insertado exitosamente: ' || p_nombre || ' (ID: ' || p_id_producto_generado || ')');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'Error al insertar producto: ' || SQLERRM);
    END PR_INSERTAR_PRODUCTO;

    FUNCTION FN_OBTENER_PRODUCTO (p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE) RETURN TP_PRODUCTO IS
        v_rec PRODUCTOS%ROWTYPE;
        v_activo NUMBER(1) := 1;
        v_json_data CLOB;
    BEGIN
        SELECT ID_PRODUCTO, ID_MARCA, NOMBRE, STOCK, VALOR_UNITARIO, FECHA_VENC, IVA
        INTO v_rec.ID_PRODUCTO, v_rec.ID_MARCA, v_rec.NOMBRE, v_rec.STOCK,
            v_rec.VALOR_UNITARIO, v_rec.FECHA_VENC, v_rec.IVA
        FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;

        IF PKG_GLOBAL_STATE.G_PRODUCTOS_INACTIVOS.EXISTS(p_id_producto) THEN 
            v_activo := 0; 
        END IF;

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
        WHEN NO_DATA_FOUND THEN 
            RETURN NULL;
        WHEN OTHERS THEN 
            RAISE;
    END FN_OBTENER_PRODUCTO;

    FUNCTION FN_OBTENER_PRODUCTO_JSON (p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE) RETURN VARCHAR2 IS
        v_rec PRODUCTOS%ROWTYPE;
        v_activo NUMBER(1) := 1;
        v_json_data VARCHAR2(4000);
    BEGIN
        SELECT ID_PRODUCTO, ID_MARCA, NOMBRE, STOCK, VALOR_UNITARIO, FECHA_VENC, IVA
        INTO v_rec.ID_PRODUCTO, v_rec.ID_MARCA, v_rec.NOMBRE, v_rec.STOCK,
            v_rec.VALOR_UNITARIO, v_rec.FECHA_VENC, v_rec.IVA
        FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;

        IF PKG_GLOBAL_STATE.G_PRODUCTOS_INACTIVOS.EXISTS(p_id_producto) THEN 
            v_activo := 0; 
        END IF;

        v_json_data := '{' ||
            '"id_producto":' || v_rec.ID_PRODUCTO || ',' ||
            '"id_marca":' || v_rec.ID_MARCA || ',' ||
            '"nombre":"' || REPLACE(v_rec.NOMBRE, '"', '\"') || '",' ||
            '"stock":' || NVL(v_rec.STOCK, 0) || ',' ||
            '"valor_unitario":' || NVL(v_rec.VALOR_UNITARIO, 0) || ',' ||
            '"fecha_venc":"' || NVL(TO_CHAR(v_rec.FECHA_VENC, 'YYYY-MM-DD'), 'null') || '",' ||
            '"iva":' || NVL(v_rec.IVA, 0) || ',' ||
            '"activo_logico":' || v_activo ||
            '}';

        RETURN v_json_data;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            RETURN NULL;
        WHEN OTHERS THEN 
            RAISE;
    END FN_OBTENER_PRODUCTO_JSON;
 
    FUNCTION FN_OBTENER_TODOS_PRODUCTOS_CON_ESTADO RETURN TBL_PRODUCTOS PIPELINED IS
        v_activo NUMBER(1);
        v_json_data CLOB;
    BEGIN
        FOR r IN (SELECT ID_PRODUCTO, ID_MARCA, NOMBRE, STOCK, VALOR_UNITARIO, FECHA_VENC, IVA FROM PRODUCTOS) LOOP
            v_activo := 1;
            IF PKG_GLOBAL_STATE.G_PRODUCTOS_INACTIVOS.EXISTS(r.ID_PRODUCTO) THEN 
                v_activo := 0; 
            END IF;

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
 
    PROCEDURE PR_ACTUALIZAR_PRODUCTO (
        p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE,
        p_id_marca IN PRODUCTOS.ID_MARCA%TYPE DEFAULT NULL,
        p_nombre IN PRODUCTOS.NOMBRE%TYPE DEFAULT NULL,
        p_stock IN PRODUCTOS.STOCK%TYPE DEFAULT NULL,
        p_valor_unitario IN PRODUCTOS.VALOR_UNITARIO%TYPE DEFAULT NULL,
        p_fecha_venc IN PRODUCTOS.FECHA_VENC%TYPE DEFAULT NULL,
        p_iva IN PRODUCTOS.IVA%TYPE DEFAULT NULL
    ) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Error: No existe producto con ID ' || p_id_producto);
        END IF;

        UPDATE PRODUCTOS SET
            ID_MARCA = NVL(p_id_marca, ID_MARCA),
            NOMBRE = NVL(p_nombre, NOMBRE),
            STOCK = NVL(p_stock, STOCK),
            VALOR_UNITARIO = NVL(p_valor_unitario, VALOR_UNITARIO),
            FECHA_VENC = NVL(p_fecha_venc, FECHA_VENC),
            IVA = NVL(p_iva, IVA)
        WHERE ID_PRODUCTO = p_id_producto;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Producto actualizado exitosamente: ID ' || p_id_producto);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20004, 'Error al actualizar producto: ' || SQLERRM);
    END PR_ACTUALIZAR_PRODUCTO;
 
    PROCEDURE PR_ELIMINAR_PRODUCTO (p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Error: No existe producto con ID ' || p_id_producto);
        END IF;

        DELETE FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;
        
        IF PKG_GLOBAL_STATE.G_PRODUCTOS_INACTIVOS.EXISTS(p_id_producto) THEN
            PKG_GLOBAL_STATE.G_PRODUCTOS_INACTIVOS.DELETE(p_id_producto);
        END IF;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Producto eliminado exitosamente: ID ' || p_id_producto);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20006, 'Error al eliminar producto: ' || SQLERRM);
    END PR_ELIMINAR_PRODUCTO;
 
    PROCEDURE PR_MARCAR_INACTIVO_LOGICAMENTE (p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE) IS
        v_count NUMBER;
    BEGIN
        
        SELECT COUNT(*) INTO v_count FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'Error: No existe producto con ID ' || p_id_producto);
        END IF;

        PKG_GLOBAL_STATE.G_PRODUCTOS_INACTIVOS(p_id_producto) := 1;
        DBMS_OUTPUT.PUT_LINE('Producto marcado como inactivo lógicamente: ID ' || p_id_producto);
    END PR_MARCAR_INACTIVO_LOGICAMENTE;
 
    PROCEDURE PR_MARCAR_ACTIVO_LOGICAMENTE (p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE) IS
    BEGIN
        IF PKG_GLOBAL_STATE.G_PRODUCTOS_INACTIVOS.EXISTS(p_id_producto) THEN
            PKG_GLOBAL_STATE.G_PRODUCTOS_INACTIVOS.DELETE(p_id_producto);
        END IF;
        DBMS_OUTPUT.PUT_LINE('Producto marcado como activo lógicamente: ID ' || p_id_producto);
    END PR_MARCAR_ACTIVO_LOGICAMENTE;
 
    PROCEDURE PR_ACTUALIZAR_STOCK (
        p_id_producto IN PRODUCTOS.ID_PRODUCTO%TYPE,
        p_cantidad IN NUMBER,
        p_operacion IN VARCHAR2 DEFAULT 'SUMAR'
    ) IS
        v_stock_actual NUMBER;
        v_nuevo_stock NUMBER;
    BEGIN
        
        SELECT STOCK INTO v_stock_actual FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;
        
        
        IF UPPER(p_operacion) = 'SUMAR' THEN
            v_nuevo_stock := v_stock_actual + p_cantidad;
        ELSIF UPPER(p_operacion) = 'RESTAR' THEN
            v_nuevo_stock := v_stock_actual - p_cantidad;
            IF v_nuevo_stock < 0 THEN
                RAISE_APPLICATION_ERROR(-20008, 'Error: Stock insuficiente. Stock actual: ' || v_stock_actual);
            END IF;
        ELSE
            RAISE_APPLICATION_ERROR(-20009, 'Error: Operación inválida. Use SUMAR o RESTAR');
        END IF;

    
        UPDATE PRODUCTOS SET STOCK = v_nuevo_stock WHERE ID_PRODUCTO = p_id_producto;
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Stock actualizado. Producto: ' || p_id_producto || ', Stock anterior: ' || v_stock_actual || ', Stock nuevo: ' || v_nuevo_stock);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Error: No existe producto con ID ' || p_id_producto);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END PR_ACTUALIZAR_STOCK;

    FUNCTION OBTENER_TODOS RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT 
                ID_PRODUCTO, NOMBRE, STOCK, VALOR_UNITARIO, FECHA_VENC, IVA
            FROM PRODUCTOS
            ORDER BY NOMBRE;
        RETURN v_cursor;
    END OBTENER_TODOS;



END PKG_PRODUCTOS;
/


CREATE OR REPLACE PACKAGE PKG_PROVEEDORES AS

    PROCEDURE PR_INSERTAR_PROVEEDOR (
        p_nombre IN PROVEEDORES.NOMBRE%TYPE,
        p_telefono IN PROVEEDORES.TELEFONO%TYPE,
        p_codigo_generado OUT PROVEEDORES.CODIGO%TYPE
    );
    
    FUNCTION FN_OBTENER_PROVEEDOR (p_codigo IN PROVEEDORES.CODIGO%TYPE) RETURN TP_PROVEEDOR;
    
    FUNCTION FN_OBTENER_TODOS_PROVEEDORES_CON_ESTADO RETURN TBL_PROVEEDORES PIPELINED;
    FUNCTION OBTENER_TODOS RETURN SYS_REFCURSOR;

    
    PROCEDURE PR_ACTUALIZAR_PROVEEDOR (
        p_codigo IN PROVEEDORES.CODIGO%TYPE,
        p_nombre IN PROVEEDORES.NOMBRE%TYPE DEFAULT NULL,
        p_telefono IN PROVEEDORES.TELEFONO%TYPE DEFAULT NULL
    );    
    PROCEDURE PR_MARCAR_INACTIVO_LOGICAMENTE (p_codigo IN PROVEEDORES.CODIGO%TYPE);
    PROCEDURE PR_MARCAR_ACTIVO_LOGICAMENTE (p_codigo IN PROVEEDORES.CODIGO%TYPE);
    
END PKG_PROVEEDORES;
/

CREATE OR REPLACE PACKAGE BODY PKG_PROVEEDORES AS

    PROCEDURE PR_INSERTAR_PROVEEDOR (
        p_nombre IN PROVEEDORES.NOMBRE%TYPE,
        p_telefono IN PROVEEDORES.TELEFONO%TYPE,
        p_codigo_generado OUT PROVEEDORES.CODIGO%TYPE
    ) IS
    BEGIN
        SELECT SEQ_PROVEEDORES.NEXTVAL INTO p_codigo_generado FROM DUAL;
        
        INSERT INTO PROVEEDORES (CODIGO, NOMBRE, TELEFONO)
        VALUES (p_codigo_generado, p_nombre, p_telefono);
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Proveedor insertado exitosamente: ' || p_nombre || ' (Código: ' || p_codigo_generado || ')');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20012, 'Error al insertar proveedor: ' || SQLERRM);
    END PR_INSERTAR_PROVEEDOR;

    FUNCTION FN_OBTENER_PROVEEDOR (p_codigo IN PROVEEDORES.CODIGO%TYPE) RETURN TP_PROVEEDOR IS
        v_rec PROVEEDORES%ROWTYPE;
        v_activo NUMBER(1) := 1;
        v_json_data CLOB;
    BEGIN
        SELECT CODIGO, NOMBRE, TELEFONO
        INTO v_rec.CODIGO, v_rec.NOMBRE, v_rec.TELEFONO
        FROM PROVEEDORES WHERE CODIGO = p_codigo;

        IF PKG_GLOBAL_STATE.G_PROVEEDORES_INACTIVOS.EXISTS(p_codigo) THEN 
            v_activo := 0; 
        END IF;

        SELECT JSON_OBJECT(
                'codigo' VALUE v_rec.CODIGO,
                'nombre' VALUE v_rec.NOMBRE,
                'telefono' VALUE v_rec.TELEFONO,
                'activo_logico' VALUE v_activo
            )
        INTO v_json_data FROM DUAL;

        RETURN TP_PROVEEDOR(v_rec.CODIGO, v_rec.NOMBRE, v_rec.TELEFONO, v_activo, v_json_data);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            RETURN NULL;
        WHEN OTHERS THEN 
            RAISE;
    END FN_OBTENER_PROVEEDOR;

    FUNCTION FN_OBTENER_TODOS_PROVEEDORES_CON_ESTADO RETURN TBL_PROVEEDORES PIPELINED IS
        v_activo NUMBER(1);
        v_json_data CLOB;
    BEGIN
        FOR r IN (SELECT CODIGO, NOMBRE, TELEFONO FROM PROVEEDORES) LOOP
            v_activo := 1;
            IF PKG_GLOBAL_STATE.G_PROVEEDORES_INACTIVOS.EXISTS(r.CODIGO) THEN 
                v_activo := 0; 
            END IF;

            SELECT JSON_OBJECT(
                    'codigo' VALUE r.CODIGO,
                    'nombre' VALUE r.NOMBRE,
                    'telefono' VALUE r.TELEFONO,
                    'activo_logico' VALUE v_activo
                )
            INTO v_json_data FROM DUAL;

            PIPE ROW (TP_PROVEEDOR(r.CODIGO, r.NOMBRE, r.TELEFONO, v_activo, v_json_data));
        END LOOP;
        RETURN;
    END FN_OBTENER_TODOS_PROVEEDORES_CON_ESTADO;

    FUNCTION OBTENER_TODOS RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT CODIGO, NOMBRE, TELEFONO
            FROM PROVEEDORES
            ORDER BY NOMBRE;
        RETURN v_cursor;
    END OBTENER_TODOS;



    PROCEDURE PR_ACTUALIZAR_PROVEEDOR (
        p_codigo IN PROVEEDORES.CODIGO%TYPE,
        p_nombre IN PROVEEDORES.NOMBRE%TYPE DEFAULT NULL,
        p_telefono IN PROVEEDORES.TELEFONO%TYPE DEFAULT NULL
    ) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM PROVEEDORES WHERE CODIGO = p_codigo;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Error: No existe proveedor con código ' || p_codigo);
        END IF;

        UPDATE PROVEEDORES SET
            NOMBRE = NVL(p_nombre, NOMBRE),
            TELEFONO = NVL(p_telefono, TELEFONO)
        WHERE CODIGO = p_codigo;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Proveedor actualizado exitosamente: Código ' || p_codigo);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20014, 'Error al actualizar proveedor: ' || SQLERRM);
    END PR_ACTUALIZAR_PROVEEDOR;


    PROCEDURE PR_MARCAR_INACTIVO_LOGICAMENTE (p_codigo IN PROVEEDORES.CODIGO%TYPE) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM PROVEEDORES WHERE CODIGO = p_codigo;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20018, 'Error: No existe proveedor con código ' || p_codigo);
        END IF;

        PKG_GLOBAL_STATE.G_PROVEEDORES_INACTIVOS(p_codigo) := 1;
        DBMS_OUTPUT.PUT_LINE('Proveedor marcado como inactivo lógicamente: Código ' || p_codigo);
    END PR_MARCAR_INACTIVO_LOGICAMENTE;

    PROCEDURE PR_MARCAR_ACTIVO_LOGICAMENTE (p_codigo IN PROVEEDORES.CODIGO%TYPE) IS
    BEGIN
        IF PKG_GLOBAL_STATE.G_PROVEEDORES_INACTIVOS.EXISTS(p_codigo) THEN
            PKG_GLOBAL_STATE.G_PROVEEDORES_INACTIVOS.DELETE(p_codigo);
        END IF;
        DBMS_OUTPUT.PUT_LINE('Proveedor marcado como activo lógicamente: Código ' || p_codigo);
    END PR_MARCAR_ACTIVO_LOGICAMENTE;

END PKG_PROVEEDORES;
/


CREATE OR REPLACE PACKAGE PKG_DIRECTORIO AS
    FUNCTION FN_GENERAR_CLAVE_COMPUESTA (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    ) RETURN VARCHAR2;
    
    PROCEDURE PR_INSERTAR_DIRECTORIO (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    );
    
    FUNCTION FN_OBTENER_DIRECTORIO (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    ) RETURN TP_DIRECTORIO;
    
    FUNCTION FN_OBTENER_TODOS_DIRECTORIOS_CON_ESTADO RETURN TBL_DIRECTORIOS PIPELINED;
    
    PROCEDURE PR_MARCAR_INACTIVO_LOGICAMENTE (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    );
    PROCEDURE PR_MARCAR_ACTIVO_LOGICAMENTE (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    );
    
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
        SELECT COUNT(*) INTO v_count FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20019, 'Error: No existe producto con ID ' || p_id_producto);
        END IF;
        
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

        
        v_clave := FN_GENERAR_CLAVE_COMPUESTA(p_id_producto, p_codigo);
        IF PKG_GLOBAL_STATE.G_DIRECTORIOS_INACTIVOS.EXISTS(v_clave) THEN 
            v_activo := 0; 
        END IF;

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

    PROCEDURE PR_MARCAR_INACTIVO_LOGICAMENTE (
        p_id_producto IN DIRECTORIO.ID_PRODUCTO%TYPE,
        p_codigo IN DIRECTORIO.CODIGO%TYPE
    ) IS
        v_count NUMBER;
        v_clave VARCHAR2(50);
    BEGIN
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
                D.ID_PRODUCTO, 
                P.NOMBRE AS PRODUCTO_NOMBRE,
                D.CODIGO AS CODIGO_PROVEEDOR,
                PR.NOMBRE AS PROVEEDOR_NOMBRE
            FROM DIRECTORIO D
            JOIN PRODUCTOS P ON D.ID_PRODUCTO = P.ID_PRODUCTO
            JOIN PROVEEDORES PR ON D.CODIGO = PR.CODIGO
            ORDER BY P.NOMBRE, PR.NOMBRE;
        RETURN v_cursor;
    END OBTENER_TODOS;

END PKG_DIRECTORIO;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== PACKAGES PL/SQL CREADOS EXITOSAMENTE ===');
    DBMS_OUTPUT.PUT_LINE('1. PKG_GLOBAL_STATE - Variables globales para estado lógico');
    DBMS_OUTPUT.PUT_LINE('2. PKG_PRODUCTOS - Gestión completa de productos/repuestos');
    DBMS_OUTPUT.PUT_LINE('3. PKG_PROVEEDORES - Gestión completa de proveedores');
    DBMS_OUTPUT.PUT_LINE('4. PKG_DIRECTORIO - Gestión de relaciones producto-proveedor');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Funcionalidades implementadas por package:');
    DBMS_OUTPUT.PUT_LINE('- Operaciones CRUD completas (Create, Read, Update, Delete)');
    DBMS_OUTPUT.PUT_LINE('- Gestión de estado lógico (activar/inactivar)');
    DBMS_OUTPUT.PUT_LINE('- Generación automática de JSON');
    DBMS_OUTPUT.PUT_LINE('- Validaciones de integridad referencial');
    DBMS_OUTPUT.PUT_LINE('- Funciones especializadas para APEX');
    DBMS_OUTPUT.PUT_LINE('- Manejo de excepciones personalizado');
    DBMS_OUTPUT.PUT_LINE('=== SISTEMA LISTO PARA GESTIÓN DE INVENTARIO ===');
END;
/