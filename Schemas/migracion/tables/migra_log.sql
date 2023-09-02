-- Table: migracion.migra_log

-- DROP TABLE IF EXISTS migracion.migra_log;

CREATE TABLE IF NOT EXISTS migracion.migra_log
(
    log_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    nombre_tabla character varying(150) COLLATE pg_catalog."default",
    registros_copiados bigint,
    fecha_migracion timestamp with time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_log
    OWNER to w4ll4c3;