-- Creación de las condiciones de la tabla NOMINAS
-- Creado por: Sergio Esteban Piña Vargas - Mario Andres Monroy Monroy
-- Fecha de creación: 03/09/2014
-- Modificado por:
-- Fecha de modificación:
-- Observaciones:

alter table NOMINA add (
	constraint NOM_PK primary key (ID_NOMINA),
	constraint NOM_FK_PER_IDPER foreign key (ID_PERIODO) references PERIODOS (ID),
	constraint NOM_FK_CONTRATO_IDCONT foreign key (ID_CONTRATO) references CONTRATOS (ID_CONTRATO),
	constraint NOM_FK_CONCEPTO_IDCONC foreign key (ID_CONCEPTO) references CONCEPTOS (ID)
);