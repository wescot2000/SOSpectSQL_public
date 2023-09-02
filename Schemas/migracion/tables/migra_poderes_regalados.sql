-- Table: migracion.migra_poderes_regalados

-- DROP TABLE IF EXISTS migracion.migra_poderes_regalados;

CREATE TABLE IF NOT EXISTS migracion.migra_poderes_regalados
(
    id_regalo bigint,
    persona_id bigint,
    cantidad_poderes_regalada integer,
    fecha_regalo timestamp with time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_poderes_regalados
    OWNER to w4ll4c3;