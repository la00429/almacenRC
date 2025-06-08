-- creacion cc LUGARES
-- creado por:Jose de Jesus Aguirre
-- fecha creacion: 02/09/2014

-- modificado por:

-- fecha modificacion:

-- descripcion:

alter table LUGARES ADD(
 constraint LUG_PK_ID primary key (ID),
 constraint LUG_FK_LUG_UBIC foreign key (UBICADO) references LUGARES (ID),
 constraint LUG_CK_TIPO_LUG check (TIPO_LUGAR in ('P','D','M') and TIPO_LUGAR = upper(TIPO_LUGAR))   	
);