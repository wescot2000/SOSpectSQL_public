-- Table: migracion.migra_alarmas
-- MODIFICADO: 2026-04-25 - Agregar contadores denormalizados de interacciones sociales (sincronizar con public.alarmas 2026-02-26)

-- DROP TABLE IF EXISTS migracion.migra_alarmas;

CREATE TABLE IF NOT EXISTS migracion.migra_alarmas
(
    alarma_id bigint,
    persona_id bigint,
    tipoalarma_id integer,
    fecha_alarma timestamp with time zone,
    latitud numeric(9,6),
    longitud numeric(9,6),
    calificacion_alarma numeric(5,2),
    estado_alarma character varying(1) COLLATE pg_catalog."default",
    latitud_originador numeric(9,6),
    longitud_originador numeric(9,6),
    ip_usuario_originador character varying(50) COLLATE pg_catalog."default",
    distancia_alarma_originador numeric(9,2),
    alarma_id_padre bigint,
    evaluada boolean,
    cnt_likes integer NOT NULL DEFAULT 0,
    cnt_reenvios integer NOT NULL DEFAULT 0,
    cnt_verdaderos integer NOT NULL DEFAULT 0,
    cnt_falsos integer NOT NULL DEFAULT 0
)

TABLESPACE pg_default;
