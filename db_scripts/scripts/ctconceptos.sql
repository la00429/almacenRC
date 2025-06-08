create table CONCEPTOS (
   ID                NUMBER(6)            not null,
   NOMBRE            VARCHAR2(30)         not null,
   OBLIGATORIEDAD    VARCHAR2(1)          not null,
   TIPO              VARCHAR2(1)          not null, 
   PORCENTAJE        NUMBER(6,3)
);