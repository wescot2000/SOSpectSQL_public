-- Table: migracion.migra_subscripciones

-- DROP TABLE IF EXISTS migracion.migra_subscripciones;

CREATE TABLE IF NOT EXISTS migracion.migra_subscripciones
(
    subscripcion_id bigint,
    ubicacion_id bigint,
    radio_alarmas_id integer,
    persona_id bigint,
    tipo_subscr_id integer,
    fecha_activacion timestamp with time zone,
    fecha_finalizacion timestamp with time zone,
    poderes_consumidos integer,
    id_rel_protegido bigint,
    cantidad_protegidos_adquirida integer,
    observaciones character varying(500) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_subscripciones
    OWNER to w4ll4c3;