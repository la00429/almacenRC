-- =====================================================
-- SCRIPT DE PRUEBA PARA PAQUETES PL/SQL
-- Sistema: AlmacenRC - Gestión de Repuestos Automotrices
-- Propósito: Verificar que los paquetes PL/SQL funcionen correctamente
-- =====================================================

SET SERVEROUTPUT ON;

DECLARE
    v_producto TP_PRODUCTO;
    v_cursor SYS_REFCURSOR;
    v_count NUMBER;
    v_id_producto NUMBER := 9999; -- ID de prueba que no debería existir
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO PRUEBAS DE PAQUETES PL/SQL ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 1: Verificar que el paquete PKG_PRODUCTOS existe
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 1: Verificando existencia del paquete PKG_PRODUCTOS...');
    BEGIN
        SELECT COUNT(*) INTO v_count 
        FROM USER_OBJECTS 
        WHERE OBJECT_NAME = 'PKG_PRODUCTOS' AND OBJECT_TYPE = 'PACKAGE';
        
        IF v_count > 0 THEN
            DBMS_OUTPUT.PUT_LINE('✅ Paquete PKG_PRODUCTOS encontrado');
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ Paquete PKG_PRODUCTOS NO encontrado');
        END IF;
        
        -- Verificar también el PACKAGE BODY
        SELECT COUNT(*) INTO v_count 
        FROM USER_OBJECTS 
        WHERE OBJECT_NAME = 'PKG_PRODUCTOS' AND OBJECT_TYPE = 'PACKAGE BODY';
        
        IF v_count > 0 THEN
            DBMS_OUTPUT.PUT_LINE('✅ Package Body PKG_PRODUCTOS encontrado');
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ Package Body PKG_PRODUCTOS NO encontrado');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error verificando paquete: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 2: Insertar un producto de prueba
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 2: Insertando producto de prueba...');
    BEGIN
        -- Primero verificar si ya existe y eliminarlo
        BEGIN
            SELECT COUNT(*) INTO v_count FROM PRODUCTOS WHERE ID_PRODUCTO = v_id_producto;
            IF v_count > 0 THEN
                DELETE FROM PRODUCTOS WHERE ID_PRODUCTO = v_id_producto;
                COMMIT;
                DBMS_OUTPUT.PUT_LINE('   Producto de prueba anterior eliminado');
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- Ignorar errores de limpieza
        END;
        
        -- Insertar producto de prueba
        PKG_PRODUCTOS.PR_INSERTAR_PRODUCTO(
            p_id_producto => v_id_producto,
            p_id_marca => 1,
            p_nombre => 'PRODUCTO_PRUEBA',
            p_stock => 100,
            p_valor_unitario => 50000,
            p_fecha_venc => SYSDATE + 365,
            p_iva => 19
        );
        
        DBMS_OUTPUT.PUT_LINE('✅ Producto insertado exitosamente via PKG_PRODUCTOS');
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error insertando producto: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 3: Obtener el producto insertado
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 3: Obteniendo producto insertado...');
    BEGIN
        v_producto := PKG_PRODUCTOS.FN_OBTENER_PRODUCTO(v_id_producto);
        
        IF v_producto IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('✅ Producto obtenido exitosamente:');
            DBMS_OUTPUT.PUT_LINE('   - ID: ' || v_producto.ID_PRODUCTO);
            DBMS_OUTPUT.PUT_LINE('   - Nombre: ' || v_producto.NOMBRE);
            DBMS_OUTPUT.PUT_LINE('   - Stock: ' || v_producto.STOCK);
            DBMS_OUTPUT.PUT_LINE('   - Valor: ' || v_producto.VALOR_UNITARIO);
            DBMS_OUTPUT.PUT_LINE('   - Activo: ' || v_producto.ACTIVO);
            DBMS_OUTPUT.PUT_LINE('   - JSON: ' || SUBSTR(v_producto.JSON_DATA, 1, 100));
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ No se pudo obtener el producto');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error obteniendo producto: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 4: Actualizar el producto
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 4: Actualizando producto...');
    BEGIN
        PKG_PRODUCTOS.PR_ACTUALIZAR_PRODUCTO(
            p_id_producto => v_id_producto,
            p_nombre => 'PRODUCTO_ACTUALIZADO',
            p_stock => 75,
            p_valor_unitario => 60000
        );
        
        DBMS_OUTPUT.PUT_LINE('✅ Producto actualizado exitosamente');
        
        -- Verificar la actualización
        v_producto := PKG_PRODUCTOS.FN_OBTENER_PRODUCTO(v_id_producto);
        IF v_producto IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   - Nuevo nombre: ' || v_producto.NOMBRE);
            DBMS_OUTPUT.PUT_LINE('   - Nuevo stock: ' || v_producto.STOCK);
            DBMS_OUTPUT.PUT_LINE('   - Nuevo valor: ' || v_producto.VALOR_UNITARIO);
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error actualizando producto: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 5: Probar función pipelined
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 5: Probando función pipelined...');
    BEGIN
        SELECT COUNT(*) INTO v_count 
        FROM TABLE(PKG_PRODUCTOS.FN_OBTENER_TODOS_PRODUCTOS_CON_ESTADO);
        
        DBMS_OUTPUT.PUT_LINE('✅ Función pipelined ejecutada exitosamente');
        DBMS_OUTPUT.PUT_LINE('   - Total productos encontrados: ' || v_count);
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error en función pipelined: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 6: Probar función para APEX
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 6: Probando función para APEX...');
    BEGIN
        v_cursor := PKG_PRODUCTOS.FN_GET_ALL_PRODUCTS_FOR_APEX;
        
        IF v_cursor%ISOPEN THEN
            DBMS_OUTPUT.PUT_LINE('✅ Cursor para APEX abierto exitosamente');
            CLOSE v_cursor;
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ Error: Cursor no se abrió correctamente');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error en función APEX: ' || SQLERRM);
            IF v_cursor%ISOPEN THEN
                CLOSE v_cursor;
            END IF;
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 7: Probar actualización de stock
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 7: Probando actualización de stock...');
    BEGIN
        -- Obtener stock actual
        v_producto := PKG_PRODUCTOS.FN_OBTENER_PRODUCTO(v_id_producto);
        DBMS_OUTPUT.PUT_LINE('   Stock inicial: ' || v_producto.STOCK);
        
        -- Sumar stock
        PKG_PRODUCTOS.PR_ACTUALIZAR_STOCK(v_id_producto, 25, 'SUMAR');
        
        -- Verificar cambio
        v_producto := PKG_PRODUCTOS.FN_OBTENER_PRODUCTO(v_id_producto);
        DBMS_OUTPUT.PUT_LINE('   Stock después de sumar 25: ' || v_producto.STOCK);
        
        -- Restar stock
        PKG_PRODUCTOS.PR_ACTUALIZAR_STOCK(v_id_producto, 10, 'RESTAR');
        
        -- Verificar cambio
        v_producto := PKG_PRODUCTOS.FN_OBTENER_PRODUCTO(v_id_producto);
        DBMS_OUTPUT.PUT_LINE('   Stock después de restar 10: ' || v_producto.STOCK);
        
        DBMS_OUTPUT.PUT_LINE('✅ Actualización de stock funcionando correctamente');
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error actualizando stock: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- LIMPIEZA: Eliminar producto de prueba
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('LIMPIEZA: Eliminando producto de prueba...');
    BEGIN
        PKG_PRODUCTOS.PR_ELIMINAR_PRODUCTO(v_id_producto);
        DBMS_OUTPUT.PUT_LINE('✅ Producto de prueba eliminado');
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error eliminando producto de prueba: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== PRUEBAS DE PAQUETES PL/SQL COMPLETADAS ===');
    
END;
/ 