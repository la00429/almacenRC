-- Creación de las condiciones de la tabla PRODUCTOS
-- Creado por: Vladimir González
-- Fecha de creación: 02/09/2014
-- Modificado por:
-- Fecha de modificación:
-- Observaciones:
alter table PRODUCTOS add(
	constraint PROD_PK_IDP primary key (ID_PRODUCTO),
	constraint PROD_FK_IDMAR foreign key (ID_MARCA) references MARCAS(ID_MARCA)
);