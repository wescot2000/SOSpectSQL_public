-- Table: migracion.migra_configuracion_costos_promocionales
-- CREADO: 2026-04-25 - Migración de configuración de costos para análisis histórico de precios

-- DROP TABLE IF EXISTS migracion.migra_configuracion_costos_promocionales;

CREATE TABLE IF NOT EXISTS migracion.migra_configuracion_costos_promocionales
(
    config_id integer,
    costo_base_promocion integer,
    costo_logo integer,
    costo_contacto integer,
    costo_domicilio integer,
    costo_por_500m_extra integer,
    costo_por_dia_extra integer,
    costo_por_media_extra integer,
    costo_por_50_usuarios_push integer,
    fecha_actualizacion timestamp without time zone,
    actualizado_por character varying(100) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;
