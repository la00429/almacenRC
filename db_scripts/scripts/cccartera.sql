alter table CARTERA add (
constraint CAR_PK_NUMFAC_CUO primary key (NUMERO_FACTURA,CUOTA),
constraint CAR_FK_FAC_NUMFAC foreign key (NUMERO_FACTURA) references FACTURAS (NUMERO)
);