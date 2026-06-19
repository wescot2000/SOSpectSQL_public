-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_tipoalarma

-- DROP TABLE IF EXISTS migracion.migra_tipoalarma;

CREATE TABLE IF NOT EXISTS migracion.migra_tipoalarma
(
    tipoalarma_id integer,
    descripciontipoalarma character varying(50) COLLATE pg_catalog."default",
    icono character varying(50) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;


ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN minutos_vigencia integer NOT NULL DEFAULT 90;

ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN radio_interes_metros integer;

ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN short_alias character varying(30);

ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN is_advertising boolean;

ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN categoria_alarma_id integer;

ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN es_indicador_politico boolean;

ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN visible_en_app_android boolean;

ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN visible_en_app_ios boolean;

ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN requiere_mensaje_advertencia_android boolean;

ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN requiere_mensaje_advertencia_ios boolean;

ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN tipo_cierre character varying(20);

ALTER TABLE migracion.migra_tipoalarma
ADD COLUMN color_fondo_feed character varying(9);

