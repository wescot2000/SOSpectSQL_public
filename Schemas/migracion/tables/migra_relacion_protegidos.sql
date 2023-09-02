-- Table: migracion.migra_relacion_protegidos

-- DROP TABLE IF EXISTS migracion.migra_relacion_protegidos;

CREATE TABLE IF NOT EXISTS migracion.migra_relacion_protegidos
(
    id_rel_protegido bigint,
    tiporelacion_id integer,
    id_persona_protector bigint,
    id_persona_protegida bigint,
    poderes_consumidos integer,
    fecha_activacion timestamp with time zone,
    fecha_finalizacion timestamp with time zone,
    fecha_suspension timestamp with time zone,
    fecha_reactivacion timestamp with time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_relacion_protegidos
    OWNER to w4ll4c3;