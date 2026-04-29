-- Table: wiped.descripcionesalarmas

-- DROP TABLE IF EXISTS wiped.descripcionesalarmas;

CREATE TABLE IF NOT EXISTS wiped.descripcionesalarmas
(
    iddescripcion bigint,
    alarma_id bigint,
    persona_id bigint,
    descripcionalarma character varying(500) COLLATE pg_catalog."default",
    descripcionsospechoso character varying(500) COLLATE pg_catalog."default",
    descripcionvehiculo character varying(500) COLLATE pg_catalog."default",
    descripcionarmas character varying(500) COLLATE pg_catalog."default",
    fechadescripcion timestamp with time zone,
    calificaciondescripcion smallint,
    veracidadalarma boolean,
    flageditado boolean,
    latitud_originador numeric(9,6),
    longitud_originador numeric(9,6),
    ip_usuario_originador character varying(50) COLLATE pg_catalog."default",
    distancia_alarma_originador numeric(9,2),
    idioma_origen character varying(10) COLLATE pg_catalog."default",
    flag_es_cierre_alarma boolean,
    flag_hubo_captura boolean,
    flag_persona_encontrada boolean,
    flag_mascota_recuperada boolean
)

TABLESPACE pg_default;
