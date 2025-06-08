-- creacion CC DETALLES
-- creado por:Jose de Jesus Aguirre
-- fecha creacion: 02/09/2014

-- modificado por:

-- fecha modificacion:

-- descripcion:


alter table DETALLES ADD(
	 constraint det_pk_id primary key (LIBRANZA, PERIODO),
	constraint det_fk_per foreign key (PERIODO)
      	references PERIODOS (ID),
    	constraint det_fk_lib foreign key (LIBRANZA)
      references LIBRANZAS (ID)
);