-- =====================================================
-- SECUENCIAS PARA GENERACIÓN AUTOMÁTICA DE IDs
-- AlmacénRC - Electiva Ingeniería de Software
-- =====================================================

-- Secuencia para productos
CREATE SEQUENCE SEQ_PRODUCTOS
    START WITH 621
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    CACHE 20;

-- Secuencia para proveedores  
CREATE SEQUENCE SEQ_PROVEEDORES
    START WITH 756
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    CACHE 10;

-- Secuencia para marcas
CREATE SEQUENCE SEQ_MARCAS
    START WITH 100
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    CACHE 10;

-- Secuencia para facturas
CREATE SEQUENCE SEQ_FACTURAS
    START WITH 300
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    CACHE 10;

-- Secuencia para contratos
CREATE SEQUENCE SEQ_CONTRATOS
    START WITH 200
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    CACHE 10;

-- Secuencia para libranzas
CREATE SEQUENCE SEQ_LIBRANZAS
    START WITH 80
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    CACHE 10;

-- Verificar que las secuencias se crearon correctamente
SELECT sequence_name, min_value, max_value, increment_by, last_number
FROM user_sequences
WHERE sequence_name LIKE 'SEQ_%'
ORDER BY sequence_name;

COMMIT; 