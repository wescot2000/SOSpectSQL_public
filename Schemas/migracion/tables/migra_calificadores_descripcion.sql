-- Table: migracion.migra_calificadores_descripcion

-- DROP TABLE IF EXISTS migracion.migra_calificadores_descripcion;

CREATE TABLE IF NOT EXISTS migracion.migra_calificadores_descripcion
(
    calificacion_id bigint,
    iddescripcion bigint,
    persona_id bigint,
    calificacion character varying(50) COLLATE pg_catalog."default",
    fecha_calificacion timestamp with time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_calificadores_descripcion
    OWNER to w4ll4c3;