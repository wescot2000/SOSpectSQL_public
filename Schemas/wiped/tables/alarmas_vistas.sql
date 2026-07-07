-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: wiped.alarmas_vistas
-- CREADO: 2026-07-06 - Backup de vistas de analitica antes de eliminar datos del usuario.
-- Necesaria porque public.alarmas_vistas tiene FK RESTRICT a personas (fk_alarmas_vistas_persona),
-- lo que bloqueaba el DELETE FROM public.personas en wiped.eliminarusuario().

-- DROP TABLE IF EXISTS wiped.alarmas_vistas;

CREATE TABLE IF NOT EXISTS wiped.alarmas_vistas
(
    vista_id bigint,
    alarma_id bigint,
    persona_id bigint,
    fecha_entrada timestamp with time zone,
    fecha_salida timestamp with time zone,
    segundos_en_pantalla integer,
    fuente_vista character varying(30) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;
