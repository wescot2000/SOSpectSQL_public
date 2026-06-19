-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_historico_costos_promocionales
-- CREADO: 2026-04-25 - Migración de historial de costos expirados para análisis de tendencias de precios

-- DROP TABLE IF EXISTS migracion.migra_historico_costos_promocionales;

CREATE TABLE IF NOT EXISTS migracion.migra_historico_costos_promocionales
(
    historico_id bigint,
    costo_base_promocion integer,
    costo_logo integer,
    costo_contacto integer,
    costo_domicilio integer,
    costo_por_500m_extra integer,
    costo_por_dia_extra integer,
    costo_por_media_extra integer,
    costo_por_50_usuarios_push integer,
    fecha_inicio_vigencia timestamp with time zone,
    fecha_fin_vigencia timestamp with time zone,
    modificado_por character varying(100) COLLATE pg_catalog."default",
    fecha_modificacion timestamp with time zone
)

TABLESPACE pg_default;


