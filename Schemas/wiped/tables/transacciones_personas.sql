-- Table: wiped.transacciones_personas

-- DROP TABLE IF EXISTS wiped.transacciones_personas;

CREATE TABLE IF NOT EXISTS wiped.transacciones_personas
(
    transaccion_id bigint,
    persona_id bigint,
    poder_id integer,
    fecha_transaccion timestamp with time zone,
    ip_transaccion character varying(150) COLLATE pg_catalog."default",
    tipo_transaccion character varying(50) COLLATE pg_catalog."default",
    purchase_token character varying(5000) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;
