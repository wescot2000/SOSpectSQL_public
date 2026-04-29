-- Table: wiped.relacion_protegidos

-- DROP TABLE IF EXISTS wiped.relacion_protegidos;

CREATE TABLE IF NOT EXISTS wiped.relacion_protegidos
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
