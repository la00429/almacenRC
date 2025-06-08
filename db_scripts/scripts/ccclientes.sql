-- creacion de constraints tabla clientes
--creado por: Miguel Augusto Cubides Neira
--fecha creacion: 03/09/2014

alter table clientes add(
constraint cli_PK_Nit primary key (NIT), 
constraint cli_fk_lugares_lugar foreign key (lugar) references lugares(id),
constraint cli_CK_ESTADO_CLIENTE check (ESTADO in ('A','I','D') and ESTADO = upper(ESTADO))
);
 