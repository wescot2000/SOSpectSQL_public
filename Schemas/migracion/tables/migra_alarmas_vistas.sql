-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_alarmas_vistas
-- CREADO: 2026-07-06 - Archivo de vistas de analitica antes de que el cascade de alarmas las borre.
-- public.alarmas_vistas tiene FK ON DELETE CASCADE a alarmas: si no se archiva aqui ANTES
-- de purgar la alarma en migrar_datos(), el dato de analitica se pierde sin backup.

-- DROP TABLE IF EXISTS migracion.migra_alarmas_vistas;

CREATE TABLE IF NOT EXISTS migracion.migra_alarmas_vistas
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
