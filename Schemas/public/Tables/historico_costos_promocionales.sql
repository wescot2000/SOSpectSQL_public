-- Table: public.historico_costos_promocionales
-- Propósito: Conserva el historial de cambios de la tabla configuracion_costos_promocionales.
-- Cada fila representa un snapshot completo de la configuración vigente durante un período.
-- Solo se inserta un nuevo registro cuando al menos un valor cambia respecto al vigente
-- (idempotente: ejecutar sin cambios no genera filas duplicadas).

-- DROP TABLE IF EXISTS public.historico_costos_promocionales;

CREATE TABLE IF NOT EXISTS public.historico_costos_promocionales
(
    historico_id                bigint      NOT NULL GENERATED ALWAYS AS IDENTITY
                                            ( INCREMENT 1 START 1 MINVALUE 1
                                              MAXVALUE 9223372036854775807 CACHE 1 ),

    -- Snapshot completo de todos los costos vigentes en este período
    costo_base_promocion        integer     NOT NULL,
    costo_logo                  integer     NOT NULL,
    costo_contacto              integer     NOT NULL,
    costo_domicilio             integer     NOT NULL,
    costo_por_500m_extra        integer     NOT NULL,
    costo_por_dia_extra         integer     NOT NULL,
    costo_por_media_extra       integer     NOT NULL,
    costo_por_50_usuarios_push  integer     NOT NULL,

    -- Vigencia del snapshot
    fecha_inicio_vigencia       timestamp with time zone NOT NULL DEFAULT NOW(),
    fecha_fin_vigencia          timestamp with time zone,           -- NULL = configuración actualmente vigente

    -- Trazabilidad del cambio
    modificado_por              character varying(100) COLLATE pg_catalog."default",
    fecha_modificacion          timestamp with time zone NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_historico_costos_promocionales PRIMARY KEY (historico_id)
)
TABLESPACE pg_default;

-- Índice para consultar el registro vigente rápidamente
CREATE INDEX IF NOT EXISTS idx_hist_cp_vigente
    ON public.historico_costos_promocionales (fecha_fin_vigencia)
    WHERE fecha_fin_vigencia IS NULL;

-- Comentarios
COMMENT ON TABLE public.historico_costos_promocionales IS
'Histórico de cambios de la tabla configuracion_costos_promocionales.
Cada fila es un snapshot completo de todos los costos durante un período.
Solo se inserta un nuevo registro cuando al menos un costo cambia.
El registro con fecha_fin_vigencia = NULL es la configuración actualmente vigente.';

COMMENT ON COLUMN public.historico_costos_promocionales.historico_id IS
'PK autoincremental del registro histórico.';

COMMENT ON COLUMN public.historico_costos_promocionales.costo_base_promocion IS
'Snapshot: costo base en poderes para crear cualquier promoción local.';

COMMENT ON COLUMN public.historico_costos_promocionales.costo_logo IS
'Snapshot: costo en poderes por agregar logo del negocio.';

COMMENT ON COLUMN public.historico_costos_promocionales.costo_contacto IS
'Snapshot: costo en poderes por habilitar chat privado.';

COMMENT ON COLUMN public.historico_costos_promocionales.costo_domicilio IS
'Snapshot: costo en poderes por habilitar opción de domicilio.';

COMMENT ON COLUMN public.historico_costos_promocionales.costo_por_500m_extra IS
'Snapshot: costo en poderes por cada 500m adicionales de radio.';

COMMENT ON COLUMN public.historico_costos_promocionales.costo_por_dia_extra IS
'Snapshot: costo en poderes por cada día adicional de duración.';

COMMENT ON COLUMN public.historico_costos_promocionales.costo_por_media_extra IS
'Snapshot: costo en poderes por cada foto/video adicional.';

COMMENT ON COLUMN public.historico_costos_promocionales.costo_por_50_usuarios_push IS
'Snapshot: costo en poderes por cada 50 usuarios a los que se envía push.';

COMMENT ON COLUMN public.historico_costos_promocionales.fecha_inicio_vigencia IS
'Momento en que esta configuración de costos entró en vigor.';

COMMENT ON COLUMN public.historico_costos_promocionales.fecha_fin_vigencia IS
'Momento en que esta configuración dejó de estar vigente. NULL indica que es la configuración actual.';

COMMENT ON COLUMN public.historico_costos_promocionales.modificado_por IS
'Usuario o proceso que realizó el cambio (ej: LANZAMIENTO_2026, ADMIN).';
