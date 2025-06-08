-- Creación de las condiciones de la tabla FACTURA
-- Creado por: Brayan Alexis González Marciales, Jorge Ivan Gallo Gomez
-- Fecha de creación: 02/09/2014
-- Modificado por:
-- Fecha de modificación:
-- Observaciones:

ALTER table facturas ADD(
 	CONSTRAINT  facturas_pk_numfac PRIMARY KEY (numero),
   	CONSTRAINT  fac_fk_nit FOREIGN KEY (nit) REFERENCES clientes (nit),
	CONSTRAINT  fac_fk_ced FOREIGN KEY (cedula) REFERENCES empleados (cedula),
 	CONSTRAINT  fac_ck_forpag CHECK (forma_pago IN ('C','P')) 
);