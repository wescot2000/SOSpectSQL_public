-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_categoria_alarma
-- CREADO: 2026-04-25 - Migración de catálogo de categorías de alarma como dimensión analítica

-- DROP TABLE IF EXISTS migracion.migra_categoria_alarma;

CREATE TABLE IF NOT EXISTS migracion.migra_categoria_alarma
(
    categoria_alarma_id integer,
    nombre character varying(50) COLLATE pg_catalog."default",
    descripcion character varying(500) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;


