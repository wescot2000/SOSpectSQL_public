-- Table: migracion.migra_historico_valorsubscripciones
-- CREADO: 2026-04-25 - Migración de historial de valores de subscripciones para análisis de precios

-- DROP TABLE IF EXISTS migracion.migra_historico_valorsubscripciones;

CREATE TABLE IF NOT EXISTS migracion.migra_historico_valorsubscripciones
(
    historico_id bigint,
    valorsubscripcion_id integer,
    tipo_subscr_id integer,
    cantidad_subscripcion integer,
    cantidad_poderes integer,
    tiempo_subscripcion_horas integer,
    fecha_inicio_vigencia timestamp with time zone,
    fecha_fin_vigencia timestamp with time zone,
    modificado_por character varying(100) COLLATE pg_catalog."default",
    fecha_modificacion timestamp with time zone
)

TABLESPACE pg_default;
