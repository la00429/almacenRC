-- Creación de la estructura de la tabla PRODUCTOS
-- Creado por: Vladimir González
-- Fecha de creación: 02/09/2014
-- Modificado por:
-- Fecha de modificación:
-- Observaciones:
create table PRODUCTOS
(
	ID_PRODUCTO          NUMBER(6)            NOT NULL,
   	ID_MARCA             NUMBER(6)            NOT NULL,
   	NOMBRE		     VARCHAR2(30)         NOT NULL,
   	STOCK                NUMBER(3)            NOT NULL,
   	VALOR_UNITARIO       NUMBER(6)            NOT NULL,
   	FECHA_VENC           DATE,
   	IVA                  NUMBER(2)            NOT NULL
);