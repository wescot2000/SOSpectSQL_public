-- Table: migracion.migra_poderes

-- DROP TABLE IF EXISTS migracion.migra_poderes;

CREATE TABLE IF NOT EXISTS migracion.migra_poderes
(
    poder_id integer,
    cantidad integer,
    valor_cop integer,
    valor_usd numeric(5,2),
    fecha_inicio timestamp with time zone,
    fecha_fin timestamp with time zone,
    "ProductId" character varying(200) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_poderes
    OWNER to w4ll4c3;