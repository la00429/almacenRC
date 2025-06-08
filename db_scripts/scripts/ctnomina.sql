-- Creación de la estructura de la tabla NOMINAS
-- Creado por: Sergio Esteban Piña Vargas - Mario Andres Monroy Monroy
-- Fecha de creación: 03/09/2014
-- Modificado por:
-- Fecha de modificación:
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