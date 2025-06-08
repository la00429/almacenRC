-- creacion tabla Libranzas
-- creado por:Jose de Jesus Aguirre
-- fecha creacion: 02/09/2014

-- modificado por:

-- fecha modificacion:

-- descripcion:

create table LIBRANZAS(
   ID          		NUMBER(3)            not null,
   CEDULA               NUMBER(4)            not null,
   VALOR       		NUMBER(10,2)         not null,
   FECHA       		DATE                 not null,
   TOTAL_CUOTAS         NUMBER(2)            not null,
   CUOTA_ACTUAL         NUMBER(2)
);
