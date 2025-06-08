-- Creaci�n de la estructura de la tabla NOMINAS
-- Creado por: Sergio Esteban Pi�a Vargas - Mario Andres Monroy Monroy
-- Fecha de creaci�n: 03/09/2014
-- Modificado por:
-- Fecha de modificaci�n:
-- Observaciones:

create table NOMINA 
(
   ID_NOMINA            NUMBER(4)            not null,
   ID_CONTRATO          NUMBER(4)            not null,
   ID_CONCEPTO          NUMBER(6)            not null,
   ID_PERIODO           NUMBER(3)            not null,
   VALOR_NOMINA         NUMBER(10,2)         not null,
   NUMERO_HORAS         NUMBER(3)
);