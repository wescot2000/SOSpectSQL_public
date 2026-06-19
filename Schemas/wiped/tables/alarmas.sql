-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: wiped.alarmas

-- DROP TABLE IF EXISTS wiped.alarmas;

CREATE TABLE IF NOT EXISTS wiped.alarmas
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
    evaluada boolean NOT NULL DEFAULT false
)

TABLESPACE pg_default;


