-- Creación de la tabla FACTURA
-- Creado por: Brayan Alexis González Marciales, Jorge Ivan Gallo Gomez
-- Fecha de creación: 02/09/2014
-- Modificado por:
-- Fecha de modificación:
-- Observaciones:

CREATE TABLE facturas(
  numero     	       NUMBER(6)           	 NOT NULL,
  nit                  NUMBER(6)          	 NOT NULL,
  cedula               NUMBER(4)          	 NOT NULL,
  fecha_venta          DATE               	 NOT NULL,
  forma_pago           VARCHAR2(1)    DEFAULT 'P'  NOT NULL,
  numero_cuotas        NUMBER(3)          	 NOT NULL
);