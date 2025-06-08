-- creacion tabla LUGARES
-- creado por:Jose de Jesus Aguirre
-- fecha creacion: 02/09/2014

-- modificado por:

-- fecha modificacion:

-- descripcion:

create table LUGARES(
   ID                   NUMBER(6)  		       Not null,
   UBICADO              NUMBER(6),
   NOMBRE               VARCHAR2(20)                   not null,
   TIPO_LUGAR           VARCHAR2(1)    DEFAULT'M'      not null
);