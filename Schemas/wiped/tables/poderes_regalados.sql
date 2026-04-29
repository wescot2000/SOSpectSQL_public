-- Table: wiped.poderes_regalados

-- DROP TABLE IF EXISTS wiped.poderes_regalados;

CREATE TABLE IF NOT EXISTS wiped.poderes_regalados
(
    id_regalo bigint,
    persona_id bigint,
    cantidad_poderes_regalada integer,
    fecha_regalo timestamp with time zone,
    calificaciones_negativas integer,
    promedio_veracidad numeric(5,4)
)

TABLESPACE pg_default;
