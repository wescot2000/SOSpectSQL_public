-- Table: migracion.migra_fotos_descripciones_alarmas
-- CREADO: 2026-04-25 - Migración de fotos/videos adjuntos a descripciones de alarmas cerradas

-- DROP TABLE IF EXISTS migracion.migra_fotos_descripciones_alarmas;

CREATE TABLE IF NOT EXISTS migracion.migra_fotos_descripciones_alarmas
(
    foto_id bigint,
    iddescripcion bigint,
    url_foto character varying(500) COLLATE pg_catalog."default",
    nombre_archivo_original character varying(200) COLLATE pg_catalog."default",
    tipo_mime character varying(50) COLLATE pg_catalog."default",
    tamano_bytes bigint,
    ancho_pixels integer,
    alto_pixels integer,
    es_video boolean,
    orden integer,
    fecha_subida timestamp with time zone,
    bucket_s3 character varying(100) COLLATE pg_catalog."default",
    thumbnail_url character varying(500) COLLATE pg_catalog."default",
    estado character varying(1) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;
