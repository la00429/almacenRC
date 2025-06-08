-- =====================================================
-- SCRIPT DE DATOS INICIALES PARA ALMACENRC
-- Sistema: Gestión de Inventario de Repuestos Automotrices
-- Propósito: Cargar datos de prueba para demostración
-- =====================================================

-- Conectar como usuario de aplicación
CONNECT laura/Laura2004@XE;

-- Habilitar salida de DBMS_OUTPUT
SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO CARGA DE DATOS INICIALES ===');
    DBMS_OUTPUT.PUT_LINE('Usuario conectado: ' || USER);
    DBMS_OUTPUT.PUT_LINE('Fecha: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
END;
/

-- =====================================================
-- VERIFICAR Y CREAR DATOS DE PRUEBA ADICIONALES
-- =====================================================

-- Insertar algunos productos adicionales para pruebas APEX
BEGIN
    -- Verificar si ya existen datos
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM PRODUCTOS WHERE ID_PRODUCTO BETWEEN 700 AND 710;
        
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Insertando productos adicionales para pruebas APEX...');
            
            -- Productos adicionales para demostración
            INSERT INTO PRODUCTOS VALUES (700, 90, 'Filtro de Aire Deportivo', 25, 45000, NULL, 16);
            INSERT INTO PRODUCTOS VALUES (701, 91, 'Amortiguador Delantero', 15, 120000, '31/12/2025', 16);
            INSERT INTO PRODUCTOS VALUES (702, 92, 'Pastillas de Freno Cerámicas', 30, 85000, '30/06/2025', 16);
            INSERT INTO PRODUCTOS VALUES (703, 93, 'Radiador Aluminio', 8, 250000, NULL, 16);
            INSERT INTO PRODUCTOS VALUES (704, 94, 'Kit de Embrague', 5, 180000, '15/08/2025', 16);
            
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Productos adicionales insertados exitosamente.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Productos adicionales ya existen.');
        END IF;
    END;
END;
/

-- Insertar algunos proveedores adicionales
BEGIN
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM PROVEEDORES WHERE CODIGO BETWEEN 100 AND 105;
        
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Insertando proveedores adicionales...');
            
            INSERT INTO PROVEEDORES VALUES (100, 'AutoParts Express', 3201234567);
            INSERT INTO PROVEEDORES VALUES (101, 'Repuestos del Norte', 3109876543);
            INSERT INTO PROVEEDORES VALUES (102, 'Distribuidora Central', 3156789012);
            INSERT INTO PROVEEDORES VALUES (103, 'Suministros Rápidos', 3187654321);
            INSERT INTO PROVEEDORES VALUES (104, 'MegaRepuestos SAS', 3198765432);
            
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Proveedores adicionales insertados exitosamente.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Proveedores adicionales ya existen.');
        END IF;
    END;
END;
/

-- Crear relaciones en directorio
BEGIN
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM DIRECTORIO WHERE ID_PRODUCTO BETWEEN 700 AND 704;
        
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Creando relaciones producto-proveedor...');
            
            -- Relaciones para demostración
            INSERT INTO DIRECTORIO VALUES (700, 100); -- Filtro de Aire -> AutoParts Express
            INSERT INTO DIRECTORIO VALUES (700, 101); -- Filtro de Aire -> Repuestos del Norte
            INSERT INTO DIRECTORIO VALUES (701, 102); -- Amortiguador -> Distribuidora Central
            INSERT INTO DIRECTORIO VALUES (702, 103); -- Pastillas -> Suministros Rápidos
            INSERT INTO DIRECTORIO VALUES (703, 104); -- Radiador -> MegaRepuestos
            INSERT INTO DIRECTORIO VALUES (704, 100); -- Kit Embrague -> AutoParts Express
            
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Relaciones directorio creadas exitosamente.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Relaciones directorio ya existen.');
        END IF;
    END;
END;
/

-- =====================================================
-- PRUEBAS DE LOS PACKAGES CREADOS
-- =====================================================

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== EJECUTANDO PRUEBAS DE PACKAGES ===');
END;
/

-- Probar inserción de producto
BEGIN
    DBMS_OUTPUT.PUT_LINE('Probando inserción de producto...');
    PKG_PRODUCTOS.PR_INSERTAR_PRODUCTO(
        p_id_producto => 999,
        p_id_marca => 90,
        p_nombre => 'Producto de Prueba APEX',
        p_stock => 10,
        p_valor_unitario => 50000,
        p_fecha_venc => NULL,
        p_iva => 16
    );
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20001 THEN
            DBMS_OUTPUT.PUT_LINE('Producto de prueba ya existe (esperado).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Error en prueba: ' || SQLERRM);
        END IF;
END;
/

-- Probar consulta de producto
DECLARE
    v_producto TP_PRODUCTO;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Probando consulta de producto...');
    v_producto := PKG_PRODUCTOS.FN_OBTENER_PRODUCTO(600);
    
    IF v_producto IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Producto encontrado: ' || v_producto.NOMBRE);
        DBMS_OUTPUT.PUT_LINE('Stock: ' || v_producto.STOCK);
        DBMS_OUTPUT.PUT_LINE('JSON: ' || SUBSTR(v_producto.JSON_DATA, 1, 100) || '...');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Producto no encontrado.');
    END IF;
END;
/

-- Probar gestión de estado lógico
BEGIN
    DBMS_OUTPUT.PUT_LINE('Probando gestión de estado lógico...');
    PKG_PRODUCTOS.PR_MARCAR_INACTIVO_LOGICAMENTE(600);
    PKG_PRODUCTOS.PR_MARCAR_ACTIVO_LOGICAMENTE(600);
END;
/

-- =====================================================
-- CONFIGURACIÓN PARA APEX
-- =====================================================

-- Crear sinónimos públicos para facilitar acceso desde APEX
BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando sinónimos para APEX...');
    
    -- Nota: En un entorno real, estos se crearían como SYS o con privilegios DBA
    -- Aquí los documentamos para referencia
    DBMS_OUTPUT.PUT_LINE('-- Ejecutar como DBA:');
    DBMS_OUTPUT.PUT_LINE('-- CREATE PUBLIC SYNONYM PKG_PRODUCTOS FOR LAURA.PKG_PRODUCTOS;');
    DBMS_OUTPUT.PUT_LINE('-- CREATE PUBLIC SYNONYM PKG_PROVEEDORES FOR LAURA.PKG_PROVEEDORES;');
    DBMS_OUTPUT.PUT_LINE('-- CREATE PUBLIC SYNONYM PKG_DIRECTORIO FOR LAURA.PKG_DIRECTORIO;');
    DBMS_OUTPUT.PUT_LINE('-- GRANT EXECUTE ON LAURA.PKG_PRODUCTOS TO APEX_PUBLIC_USER;');
    DBMS_OUTPUT.PUT_LINE('-- GRANT EXECUTE ON LAURA.PKG_PROVEEDORES TO APEX_PUBLIC_USER;');
    DBMS_OUTPUT.PUT_LINE('-- GRANT EXECUTE ON LAURA.PKG_DIRECTORIO TO APEX_PUBLIC_USER;');
END;
/

-- Verificar que las tablas tienen datos
BEGIN
    DECLARE
        v_productos NUMBER;
        v_proveedores NUMBER;
        v_directorio NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_productos FROM PRODUCTOS;
        SELECT COUNT(*) INTO v_proveedores FROM PROVEEDORES;
        SELECT COUNT(*) INTO v_directorio FROM DIRECTORIO;
        
        DBMS_OUTPUT.PUT_LINE('=== RESUMEN DE DATOS ===');
        DBMS_OUTPUT.PUT_LINE('Total Productos: ' || v_productos);
        DBMS_OUTPUT.PUT_LINE('Total Proveedores: ' || v_proveedores);
        DBMS_OUTPUT.PUT_LINE('Total Relaciones Directorio: ' || v_directorio);
    END;
END;
/

-- =====================================================
-- FINALIZACIÓN
-- =====================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== CARGA DE DATOS INICIALES COMPLETADA ===');
    DBMS_OUTPUT.PUT_LINE('El sistema está listo para ser usado con APEX');
    DBMS_OUTPUT.PUT_LINE('Packages disponibles:');
    DBMS_OUTPUT.PUT_LINE('- PKG_PRODUCTOS (Gestión de repuestos)');
    DBMS_OUTPUT.PUT_LINE('- PKG_PROVEEDORES (Gestión de proveedores)');
    DBMS_OUTPUT.PUT_LINE('- PKG_DIRECTORIO (Relaciones producto-proveedor)');
    DBMS_OUTPUT.PUT_LINE('Fecha finalización: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
END;
/

-- Confirmar transacciones
COMMIT; 