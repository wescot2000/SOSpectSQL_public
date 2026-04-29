-- Table: public.chat_publicidad
-- ACTUALIZADO: 14-01-2026 - Refactorización Multi-Emprendimiento
-- CAMBIOS:
--   1. Agregado campo subscripcion_id para JOIN directo con emprendimientos (13-01-2026)
--   2. Agregados campos de métricas de chat (para ETL y gamificación) (13-01-2026)
--   3. ELIMINADOS campos del proveedor (proveedor_acepto_terminos, fecha_proveedor_acepto) - Se heredan desde subscripciones (14-01-2026)

-- DROP TABLE IF EXISTS public.chat_publicidad;

CREATE TABLE IF NOT EXISTS public.chat_publicidad
(
    chat_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    alarma_id bigint NOT NULL,
    proveedor_persona_id bigint NOT NULL,
    interesado_persona_id bigint NOT NULL,
    fecha_inicio timestamp with time zone DEFAULT NOW(),
    estado character varying(20) COLLATE pg_catalog."default" DEFAULT 'active',
    fecha_estado_cambio timestamp with time zone DEFAULT NOW(),
    interesado_acepto_terminos boolean DEFAULT false,
    fecha_interesado_acepto timestamp with time zone,
    subscripcion_id bigint,

    -- CAMPOS DE MÉTRICAS (agregados 13-01-2026 para ETL y gamificación)
    calificacion_servicio integer,
    comentario_cliente text COLLATE pg_catalog."default",
    fecha_calificacion timestamp with time zone,
    fecha_primera_respuesta_proveedor timestamp with time zone,
    fecha_pedido timestamp with time zone,
    fecha_entrega_confirmada timestamp with time zone,

    CONSTRAINT pk_chat_publicidad PRIMARY KEY (chat_id),
    CONSTRAINT chk_calificacion_servicio CHECK (calificacion_servicio IS NULL OR (calificacion_servicio BETWEEN 1 AND 5)),
    CONSTRAINT fk_chat_publicidad_alarma FOREIGN KEY (alarma_id)
        REFERENCES public.alarmas (alarma_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE CASCADE,
    CONSTRAINT fk_chat_publicidad_proveedor FOREIGN KEY (proveedor_persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_chat_publicidad_interesado FOREIGN KEY (interesado_persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_chat_publicidad_subscripcion FOREIGN KEY (subscripcion_id)
        REFERENCES public.subscripciones (subscripcion_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT chk_chat_publicidad_estado CHECK (estado IN ('active', 'closed', 'archived'))
)

TABLESPACE pg_default;


COMMENT ON TABLE public.chat_publicidad IS
'Chats privados 1-a-1 entre proveedores (anunciantes) e interesados (usuarios) para alarmas publicitarias. Requiere aceptación de términos de ambas partes antes de activarse.';

COMMENT ON COLUMN public.chat_publicidad.estado IS
'Estado del chat: "active" (chat creado y habilitado), "closed" (cerrado manualmente), "archived" (archivado por ETL después de 32 días de inactividad).';

-- Índice para búsquedas rápidas por alarma
CREATE INDEX IF NOT EXISTS idx_chat_publicidad_alarma
    ON public.chat_publicidad USING btree
    (alarma_id ASC NULLS LAST)
    TABLESPACE pg_default;

-- Índice para búsquedas rápidas por proveedor
CREATE INDEX IF NOT EXISTS idx_chat_publicidad_proveedor
    ON public.chat_publicidad USING btree
    (proveedor_persona_id ASC NULLS LAST)
    TABLESPACE pg_default;

-- Índice para búsquedas rápidas por interesado
CREATE INDEX IF NOT EXISTS idx_chat_publicidad_interesado
    ON public.chat_publicidad USING btree
    (interesado_persona_id ASC NULLS LAST)
    TABLESPACE pg_default;

-- Índice para búsquedas rápidas por estado
CREATE INDEX IF NOT EXISTS idx_chat_publicidad_estado
    ON public.chat_publicidad USING btree
    (estado ASC NULLS LAST)
    TABLESPACE pg_default;

-- Índice único compuesto para evitar chats duplicados
CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_publicidad_unique
    ON public.chat_publicidad(alarma_id, interesado_persona_id)
    WHERE estado = 'active';

-- Índice para búsquedas por subscripcion (agregado 13-01-2026)
CREATE INDEX IF NOT EXISTS idx_chat_publicidad_subscripcion
    ON public.chat_publicidad USING btree
    (subscripcion_id ASC NULLS LAST)
    TABLESPACE pg_default;

COMMENT ON INDEX public.idx_chat_publicidad_unique IS
'Previene chats duplicados entre el mismo interesado y la misma alarma (solo para chats activos).';

COMMENT ON INDEX public.idx_chat_publicidad_subscripcion IS
'Índice para búsquedas de chats por suscripción (necesario para JOIN con emprendimientos en el trigger). Agregado: 13-01-2026.';

COMMENT ON COLUMN public.chat_publicidad.subscripcion_id IS
'FK a subscripciones. Los términos aceptados por el proveedor se heredan desde subscripciones.proveedor_acepto_terminos_chat y subscripciones.fecha_proveedor_acepto_terminos (NO duplicar aquí). Agregado: 13-01-2026.';

COMMENT ON COLUMN public.chat_publicidad.interesado_acepto_terminos IS
'Indica si el interesado (cliente) aceptó los términos para ESTE chat específico. Cada interesado acepta independientemente. También conocido como usuario_acepto_terminos.';

COMMENT ON COLUMN public.chat_publicidad.calificacion_servicio IS
'Calificación del servicio por parte del cliente (1-5 estrellas). NULL si no ha calificado aún. Usado por ETL para calcular reputación_promedio del emprendimiento.';

COMMENT ON COLUMN public.chat_publicidad.comentario_cliente IS
'Comentario opcional del cliente sobre el servicio recibido. Se muestra en el perfil público del emprendimiento.';

COMMENT ON COLUMN public.chat_publicidad.fecha_calificacion IS
'Fecha y hora en que el cliente calificó el servicio. Trigger para actualizar métricas en tiempo real.';

COMMENT ON COLUMN public.chat_publicidad.fecha_primera_respuesta_proveedor IS
'Fecha y hora de la primera respuesta del proveedor en el chat. Usado por ETL para calcular promedio_tiempo_respuesta_minutos.';

COMMENT ON COLUMN public.chat_publicidad.fecha_pedido IS
'Fecha y hora en que el cliente confirmó un pedido. Usado para calcular tiempo de entrega.';

COMMENT ON COLUMN public.chat_publicidad.fecha_entrega_confirmada IS
'Fecha y hora en que se confirmó la entrega del pedido. Usado por ETL para calcular promedio_tiempo_entrega_horas.';
