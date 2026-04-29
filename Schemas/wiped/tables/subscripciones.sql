-- Table: wiped.subscripciones

-- DROP TABLE IF EXISTS wiped.subscripciones;

CREATE TABLE IF NOT EXISTS wiped.subscripciones
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
    observaciones character varying(500) COLLATE pg_catalog."default",
    radio_publicidad integer,
    flag_notifica_publicidad boolean,
    alarma_id bigint,
    radio_metros integer,
    duracion_dias integer,
    logo_habilitado boolean,
    contacto_habilitado boolean,
    domicilio_habilitado boolean,
    cantidad_media_adjunta integer,
    usuarios_push_notificados integer,
    texto_push_personalizado character varying(200) COLLATE pg_catalog."default",
    proveedor_acepto_terminos_chat boolean,
    fecha_proveedor_acepto_terminos timestamp with time zone,
    id_emprendimiento bigint
)

TABLESPACE pg_default;
