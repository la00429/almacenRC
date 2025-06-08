-- creacion tabla Libranzas
-- creado por:Jose de camilo molina
-- fecha creacion: 02/09/2014

-- modificado por:

-- fecha modificacion:

-- descripcion:


create table EMPLEADOS (
   CEDULA               NUMBER(4)            not null,
   NOMBRE	        VARCHAR2(30)         not null,
   APELLIDO	        VARCHAR2(30)         not null,
   CORREO               VARCHAR2(30)         not null,
   GENERO               VARCHAR2(1)          not null,
   JEFE           	NUMBER(4),
   LUGAR            	NUMBER(6)            not null
);
