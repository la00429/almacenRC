-- Creaci�n de las condiciones de la tabla PRODUCTOS
-- Creado por: Vladimir Gonz�lez
-- Fecha de creaci�n: 02/09/2014
-- Modificado por:
-- Fecha de modificaci�n:
-- Observaciones:
alter table PRODUCTOS add(
	constraint PROD_PK_IDP primary key (ID_PRODUCTO),
	constraint PROD_FK_IDMAR foreign key (ID_MARCA) references MARCAS(ID_MARCA)
);