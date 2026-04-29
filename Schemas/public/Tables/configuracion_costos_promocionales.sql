-- Table: public.configuracion_costos_promocionales

-- DROP TABLE IF EXISTS public.configuracion_costos_promocionales;

CREATE TABLE IF NOT EXISTS public.configuracion_costos_promocionales
(
    config_id integer NOT NULL DEFAULT 1,
    costo_base_promocion integer NOT NULL DEFAULT 40,
    costo_logo integer NOT NULL DEFAULT 10,
    costo_contacto integer NOT NULL DEFAULT 5,
    costo_domicilio integer NOT NULL DEFAULT 5,
    costo_por_500m_extra integer NOT NULL DEFAULT 20,
    costo_por_dia_extra integer NOT NULL DEFAULT 10,
    costo_por_media_extra integer NOT NULL DEFAULT 20,
    costo_por_50_usuarios_push integer NOT NULL DEFAULT 20,
    fecha_actualizacion timestamp without time zone DEFAULT NOW(),
    actualizado_por character varying(100) COLLATE pg_catalog."default",
    CONSTRAINT configuracion_costos_promocionales_pkey PRIMARY KEY (config_id),
    CONSTRAINT configuracion_costos_promocionales_config_id_check CHECK (config_id = 1)
)

TABLESPACE pg_default;


COMMENT ON TABLE public.configuracion_costos_promocionales IS
'Tabla de configuración centralizada para los costos de alarmas promocionales. Solo debe existir 1 registro (config_id = 1).';

COMMENT ON COLUMN public.configuracion_costos_promocionales.costo_base_promocion IS
'Costo base en poderes para crear cualquier promoción local (incluye 1 día, 100m radio, 1 foto/video).';

COMMENT ON COLUMN public.configuracion_costos_promocionales.costo_logo IS
'Costo en poderes por agregar el logo del negocio a la promoción.';

COMMENT ON COLUMN public.configuracion_costos_promocionales.costo_contacto IS
'Costo en poderes por habilitar chat privado con los usuarios interesados.';

COMMENT ON COLUMN public.configuracion_costos_promocionales.costo_domicilio IS
'Costo en poderes por permitir que usuarios soliciten domicilio.';

COMMENT ON COLUMN public.configuracion_costos_promocionales.costo_por_500m_extra IS
'Costo en poderes por cada 500 metros adicionales al radio base de 100m.';

COMMENT ON COLUMN public.configuracion_costos_promocionales.costo_por_dia_extra IS
'Costo en poderes por cada día adicional a la duración base de 1 día.';

COMMENT ON COLUMN public.configuracion_costos_promocionales.costo_por_media_extra IS
'Costo en poderes por cada foto/video adicional al incluido en el costo base.';

COMMENT ON COLUMN public.configuracion_costos_promocionales.costo_por_50_usuarios_push IS
'Costo en poderes por cada 50 usuarios a los que se envía notificación push.';

-- Insertar configuración por defecto
INSERT INTO public.configuracion_costos_promocionales
(
    config_id,
    costo_base_promocion,
    costo_logo,
    costo_contacto,
    costo_domicilio,
    costo_por_500m_extra,
    costo_por_dia_extra,
    costo_por_media_extra,
    costo_por_50_usuarios_push,
    actualizado_por
)
VALUES
(
    1,
    10,
    2,
    1,
    1,
    5,
    2,
    5,
    5,
    'LANZAMIENTO_2026'
)
ON CONFLICT (config_id) DO UPDATE
SET
    costo_base_promocion = EXCLUDED.costo_base_promocion,
    costo_logo = EXCLUDED.costo_logo,
    costo_contacto = EXCLUDED.costo_contacto,
    costo_domicilio = EXCLUDED.costo_domicilio,
    costo_por_500m_extra = EXCLUDED.costo_por_500m_extra,
    costo_por_dia_extra = EXCLUDED.costo_por_dia_extra,
    costo_por_media_extra = EXCLUDED.costo_por_media_extra,
    costo_por_50_usuarios_push = EXCLUDED.costo_por_50_usuarios_push,
    actualizado_por = EXCLUDED.actualizado_por;
