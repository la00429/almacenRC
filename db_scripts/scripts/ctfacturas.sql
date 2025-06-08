-- Creaci�n de la tabla FACTURA
-- Creado por: Brayan Alexis Gonz�lez Marciales, Jorge Ivan Gallo Gomez
-- Fecha de creaci�n: 02/09/2014
-- Modificado por:
-- Fecha de modificaci�n:
-- Observaciones:

CREATE TABLE facturas(
  numero     	       NUMBER(6)           	 NOT NULL,
  nit                  NUMBER(6)          	 NOT NULL,
  cedula               NUMBER(4)          	 NOT NULL,
  fecha_venta          DATE               	 NOT NULL,
  forma_pago           VARCHAR2(1)    DEFAULT 'P'  NOT NULL,
  numero_cuotas        NUMBER(3)          	 NOT NULL
);