-- Table: wiped.calificadores_descripcion

-- DROP TABLE IF EXISTS wiped.calificadores_descripcion;

CREATE TABLE IF NOT EXISTS wiped.calificadores_descripcion
(
    calificacion_id bigint,
    iddescripcion bigint,
    persona_id bigint,
    calificacion character varying(50) COLLATE pg_catalog."default",
    fecha_calificacion timestamp with time zone
)

TABLESPACE pg_default;
