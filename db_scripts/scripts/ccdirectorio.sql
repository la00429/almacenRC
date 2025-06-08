alter table DIRECTORIO add (
CONSTRAINT  directorios_pk_codidpr PRIMARY KEY (CODIGO,ID_PRODUCTO),
constraint DIR_FK_codigo foreign key (CODIGO) references PROVEEDORES (CODIGO),
constraint DIR_FK_idprod foreign key (ID_PRODUCTO) references PRODUCTOS (ID_PRODUCTO)
);