-- autores Harold Noah Parra Gonzalez
-- Jonathan Giovanny Camargo Sanabria
alter table VENTAS add ( 
	CONSTRAINT facturas_pk_id_numero PRIMARY KEY (id,numero),
	CONSTRAINT facturas_FK_numero FOREIGN KEY (NUMERO) REFERENCES FACTURAS (NUMERO), 
      	CONSTRAINT producto_FK_id FOREIGN KEY (ID) REFERENCES PRODUCTOS (ID_PRODUCTO)
);
