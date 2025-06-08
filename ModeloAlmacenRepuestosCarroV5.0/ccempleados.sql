-- modificacion de la tabla empleados
-- creado por:Jose camilo molina
-- fecha creacion: 02/09/2014

-- modificado por:

-- fecha modificacion:

-- descripcion:


alter table EMPLEADOS ADD(
constraint emp_pk_cedula primary key (cedula),
constraint emp_fk_emp_jefe foreign key (jefe) references EMPLEADOS (CEDULA),
constraint emp_fk_lugares_lugar foreign key (LUGAR) references lugares(ID),
constraint emp_uk_correo unique(correo),
constraint EMPLEADO_ck_GENE check (GENERO in ('F','M') and GENERO = upper(GENERO))
);
