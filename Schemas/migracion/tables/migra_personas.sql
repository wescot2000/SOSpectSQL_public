-- Table: migracion.migra_personas

-- DROP TABLE IF EXISTS migracion.migra_personas;

CREATE TABLE IF NOT EXISTS migracion.migra_personas
(
    persona_id bigint,
    radio_alarmas_id integer,
    login character varying(150) COLLATE pg_catalog."default",
    user_id_thirdparty character varying(150) COLLATE pg_catalog."default",
    fechacreacion date,
    marca_bloqueo integer,
    credibilidad_persona numeric(5,2),
    fecha_ultima_marca_bloqueo timestamp with time zone,
    tiempo_refresco_mapa integer,
    saldo_poderes integer,
    flag_es_policia boolean,
    numeroplaca character varying(500) COLLATE pg_catalog."default",
    dependenciaasignada character varying(500) COLLATE pg_catalog."default",
    ciudad character varying(500) COLLATE pg_catalog."default",
    pais character varying(500) COLLATE pg_catalog."default",
    flag_es_admin boolean,
    remitentecambio character varying(500) COLLATE pg_catalog."default",
    fechacorreosolicitud character varying(500) COLLATE pg_catalog."default",
    asuntocorreosolicitud character varying(500) COLLATE pg_catalog."default",
    fechaaplicacionsolicitud timestamp with time zone,
    notif_alarma_cercana_habilitada boolean,
    notif_alarma_protegido_habilitada boolean,
    notif_alarma_zona_vigilancia_habilitada boolean,
    notif_alarma_policia_habilitada boolean,
    fecha_act_configuracion_notif timestamp with time zone,
    dias_notif_policia_apagada integer,
    nombres character varying(500) COLLATE pg_catalog."default",
    apellidos character varying(500) COLLATE pg_catalog."default",
    numero_movil character varying(100) COLLATE pg_catalog."default",
    email character varying(500) COLLATE pg_catalog."default",
    persona_lider_redconf_id bigint,
    national_id character varying(100) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;
