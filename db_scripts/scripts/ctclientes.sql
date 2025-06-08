-- creacion tabla Clientes
-- creado por: Miguel Augusto Cubides Neira
-- fecha creacion: 3/09/2014

create table CLIENTES(
   NIT                  NUMBER(6)            not null,
   LUGAR             	NUMBER(6)            not null,
   NOMBRE       	VARCHAR2(20)         not null,
   APELLIDO		VARCHAR2(20)         not null,	
   DIRECCION            VARCHAR2(20)         not null,
   TELEFONO     	NUMBER(15),
   ESTADO               VARCHAR2(1) DEFAULT 'A'          not null,      
   MONTO_CREDITO        NUMBER(10)           not null	
);
