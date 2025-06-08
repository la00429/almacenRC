-- creacion cc LIBRANZA
-- creado por:Jose Aguirre
-- fecha creacion: 02/09/2014

-- modificado por:

-- fecha modificacion:

-- descripcion:
alter table LIBRANZAS ADD(
	constraint lib_pk_id primary key (ID),
        constraint lib_fk_emp_cedula foreign key (CEDULA)
        references EMPLEADOS (CEDULA)
);