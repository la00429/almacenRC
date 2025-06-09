-- =====================================================
-- SCRIPT DE PRUEBA PARA TIPOS DE OBJETOS
-- Sistema: AlmacenRC - Gestión de Repuestos Automotrices
-- Propósito: Verificar que los tipos de objetos funcionen correctamente
-- =====================================================

SET SERVEROUTPUT ON;

DECLARE
    -- Variables para pruebas
    v_producto TP_PRODUCTO;
    v_proveedor TP_PROVEEDOR;
    v_directorio TP_DIRECTORIO;
    v_productos TBL_PRODUCTOS;
    v_proveedores TBL_PROVEEDORES;
    v_directorios TBL_DIRECTORIOS;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO PRUEBAS DE TIPOS DE OBJETOS ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 1: Crear objeto TP_PRODUCTO
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 1: Creando objeto TP_PRODUCTO...');
    BEGIN
        v_producto := TP_PRODUCTO(
            1001,                    -- ID_PRODUCTO
            1,                       -- ID_MARCA
            'Filtro de Aceite',      -- NOMBRE
            50,                      -- STOCK
            25000,                   -- VALOR_UNITARIO
            SYSDATE + 365,           -- FECHA_VENC
            19,                      -- IVA
            1,                       -- ACTIVO
            '{"test": "producto_creado"}' -- JSON_DATA
        );
        
        DBMS_OUTPUT.PUT_LINE('✅ TP_PRODUCTO creado exitosamente');
        DBMS_OUTPUT.PUT_LINE('   - ID: ' || v_producto.ID_PRODUCTO);
        DBMS_OUTPUT.PUT_LINE('   - Nombre: ' || v_producto.NOMBRE);
        DBMS_OUTPUT.PUT_LINE('   - Stock: ' || v_producto.STOCK);
        DBMS_OUTPUT.PUT_LINE('   - Valor: ' || v_producto.VALOR_UNITARIO);
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error creando TP_PRODUCTO: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 2: Crear objeto TP_PROVEEDOR
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 2: Creando objeto TP_PROVEEDOR...');
    BEGIN
        v_proveedor := TP_PROVEEDOR(
            2001,                    -- CODIGO
            'AutoPartes SA',         -- NOMBRE
            3001234,                 -- TELEFONO
            1,                       -- ACTIVO
            '{"test": "proveedor_creado"}' -- JSON_DATA
        );
        
        DBMS_OUTPUT.PUT_LINE('✅ TP_PROVEEDOR creado exitosamente');
        DBMS_OUTPUT.PUT_LINE('   - Código: ' || v_proveedor.CODIGO);
        DBMS_OUTPUT.PUT_LINE('   - Nombre: ' || v_proveedor.NOMBRE);
        DBMS_OUTPUT.PUT_LINE('   - Teléfono: ' || v_proveedor.TELEFONO);
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error creando TP_PROVEEDOR: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 3: Crear objeto TP_DIRECTORIO
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 3: Creando objeto TP_DIRECTORIO...');
    BEGIN
        v_directorio := TP_DIRECTORIO(
            1001,                    -- ID_PRODUCTO
            2001,                    -- CODIGO (proveedor)
            1,                       -- ACTIVO
            '{"test": "directorio_creado"}' -- JSON_DATA
        );
        
        DBMS_OUTPUT.PUT_LINE('✅ TP_DIRECTORIO creado exitosamente');
        DBMS_OUTPUT.PUT_LINE('   - ID Producto: ' || v_directorio.ID_PRODUCTO);
        DBMS_OUTPUT.PUT_LINE('   - Código Proveedor: ' || v_directorio.CODIGO);
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error creando TP_DIRECTORIO: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 4: Crear colecciones (tablas de objetos)
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 4: Creando colecciones de objetos...');
    BEGIN
        -- Crear tabla de productos
        v_productos := TBL_PRODUCTOS();
        v_productos.EXTEND(2);
        
        v_productos(1) := TP_PRODUCTO(1001, 1, 'Filtro Aceite', 50, 25000, SYSDATE+365, 19, 1, '{"id":1}');
        v_productos(2) := TP_PRODUCTO(1002, 2, 'Pastillas Freno', 30, 45000, SYSDATE+180, 19, 1, '{"id":2}');
        
        DBMS_OUTPUT.PUT_LINE('✅ TBL_PRODUCTOS creada con ' || v_productos.COUNT || ' elementos');
        
        -- Crear tabla de proveedores
        v_proveedores := TBL_PROVEEDORES();
        v_proveedores.EXTEND(2);
        
        v_proveedores(1) := TP_PROVEEDOR(2001, 'AutoPartes SA', 3001234, 1, '{"prov":1}');
        v_proveedores(2) := TP_PROVEEDOR(2002, 'Repuestos XYZ', 3005678, 1, '{"prov":2}');
        
        DBMS_OUTPUT.PUT_LINE('✅ TBL_PROVEEDORES creada con ' || v_proveedores.COUNT || ' elementos');
        
        -- Crear tabla de directorios
        v_directorios := TBL_DIRECTORIOS();
        v_directorios.EXTEND(2);
        
        v_directorios(1) := TP_DIRECTORIO(1001, 2001, 1, '{"dir":1}');
        v_directorios(2) := TP_DIRECTORIO(1002, 2002, 1, '{"dir":2}');
        
        DBMS_OUTPUT.PUT_LINE('✅ TBL_DIRECTORIOS creada con ' || v_directorios.COUNT || ' elementos');
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error creando colecciones: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =====================================================
    -- PRUEBA 5: Iterar sobre colecciones
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE('PRUEBA 5: Iterando sobre colecciones...');
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- Productos en la colección ---');
        FOR i IN 1..v_productos.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('Producto ' || i || ': ' || v_productos(i).NOMBRE || 
                               ' (Stock: ' || v_productos(i).STOCK || ')');
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('--- Proveedores en la colección ---');
        FOR i IN 1..v_proveedores.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('Proveedor ' || i || ': ' || v_proveedores(i).NOMBRE || 
                               ' (Tel: ' || v_proveedores(i).TELEFONO || ')');
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('✅ Iteración completada exitosamente');
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error iterando colecciones: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== PRUEBAS DE TIPOS DE OBJETOS COMPLETADAS ===');
    
END;
/ 