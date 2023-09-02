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
    saldo_poderes integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_personas
    OWNER to w4ll4c3;