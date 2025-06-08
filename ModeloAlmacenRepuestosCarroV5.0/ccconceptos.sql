alter table CONCEPTOS add (
CONSTRAINT conc_pk_id PRIMARY KEY (id),
CONSTRAINT conc_ck_tipo CHECK (tipo IN ('P'/*Pago*/,'D'/*Descuento*/)),
CONSTRAINT conc_ck_obligatoriedad CHECK (obligatoriedad IN ('O'/*opcional*/,'M'/*mandatorio*/))
);

