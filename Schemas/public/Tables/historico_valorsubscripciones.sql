-- Table: public.historico_valorsubscripciones
-- Propósito: Conserva el historial de cambios de precios en la tabla valorsubscripciones.
-- Cada fila representa una configuración vigente para un registro de valorsubscripciones
-- durante un período determinado. Solo se inserta un nuevo registro cuando los valores
-- realmente cambian (idempotente: ejecutar sin cambios no genera filas duplicadas).

-- DROP TABLE IF EXISTS public.historico_valorsubscripciones;

CREATE TABLE IF NOT EXISTS public.historico_valorsubscripciones
(
    historico_id            bigint      NOT NULL GENERATED ALWAYS AS IDENTITY
                                        ( INCREMENT 1 START 1 MINVALUE 1
                                          MAXVALUE 9223372036854775807 CACHE 1 ),

    -- Clave del registro origen
    valorsubscripcion_id    integer     NOT NULL,

    -- Snapshot de los valores vigentes en este período
    tipo_subscr_id          integer     NOT NULL,
    cantidad_subscripcion   integer,
    cantidad_poderes        integer     NOT NULL,
    tiempo_subscripcion_horas integer,

    -- Vigencia del snapshot
    fecha_inicio_vigencia   timestamp with time zone NOT NULL DEFAULT NOW(),
    fecha_fin_vigencia      timestamp with time zone,           -- NULL = registro actualmente vigente

    -- Trazabilidad del cambio
    modificado_por          character varying(100) COLLATE pg_catalog."default",
    fecha_modificacion      timestamp with time zone NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_historico_valorsubscripciones PRIMARY KEY (historico_id)
)
TABLESPACE pg_default;

-- Índices para consultas de auditoría
CREATE INDEX IF NOT EXISTS idx_hist_vs_valorsubscripcion_id
    ON public.historico_valorsubscripciones (valorsubscripcion_id);

CREATE INDEX IF NOT EXISTS idx_hist_vs_vigencia
    ON public.historico_valorsubscripciones (valorsubscripcion_id, fecha_fin_vigencia)
    WHERE fecha_fin_vigencia IS NULL;

-- Comentarios
COMMENT ON TABLE public.historico_valorsubscripciones IS
'Histórico de cambios de precios (en poderes) de la tabla valorsubscripciones.
Solo se inserta un nuevo registro cuando los valores realmente cambian.
El registro con fecha_fin_vigencia = NULL es el actualmente vigente.';

COMMENT ON COLUMN public.historico_valorsubscripciones.historico_id IS
'PK autoincremental del registro histórico.';

COMMENT ON COLUMN public.historico_valorsubscripciones.valorsubscripcion_id IS
'FK al registro de valorsubscripciones al que pertenece este snapshot.';

COMMENT ON COLUMN public.historico_valorsubscripciones.cantidad_poderes IS
'Costo en poderes vigente durante este período.';

COMMENT ON COLUMN public.historico_valorsubscripciones.fecha_inicio_vigencia IS
'Momento en que este precio entró en vigor.';

COMMENT ON COLUMN public.historico_valorsubscripciones.fecha_fin_vigencia IS
'Momento en que este precio dejó de estar vigente. NULL indica que es el precio actual.';

COMMENT ON COLUMN public.historico_valorsubscripciones.modificado_por IS
'Usuario o proceso que realizó el cambio (ej: LANZAMIENTO_2026, ADMIN).';
