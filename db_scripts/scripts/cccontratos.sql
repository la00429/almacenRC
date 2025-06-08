alter table CONTRATOS add (
	constraint PK_CONTRATO primary key (id_contrato),
	constraint FK_CONTRATO_R6_EMPLEADO foreign key (CEDULA)
      		references EMPLEADOS (CEDULA)
);
