-- Table: migracion.migra_dispositivos

-- DROP TABLE IF EXISTS migracion.migra_dispositivos;

CREATE TABLE IF NOT EXISTS migracion.migra_dispositivos
(
    id_dispositivo bigint,
    persona_id bigint,
    registrationid character varying(200) COLLATE pg_catalog."default",
    plataforma character varying(100) COLLATE pg_catalog."default",
    idioma character varying(10) COLLATE pg_catalog."default",
    fecha_inicio timestamp with time zone,
    fecha_fin timestamp with time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_dispositivos
    OWNER to w4ll4c3;