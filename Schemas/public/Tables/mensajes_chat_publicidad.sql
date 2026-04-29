-- Table: public.mensajes_chat_publicidad

-- DROP TABLE IF EXISTS public.mensajes_chat_publicidad;

CREATE TABLE IF NOT EXISTS public.mensajes_chat_publicidad
(
    mensaje_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    chat_id bigint NOT NULL,
    remitente_persona_id bigint NOT NULL,
    contenido text COLLATE pg_catalog."default" NOT NULL,
    fecha_envio timestamp with time zone DEFAULT NOW(),
    leido boolean DEFAULT false,
    fecha_lectura timestamp with time zone,
    url_media character varying(500) COLLATE pg_catalog."default",
    tipo_media character varying(20) COLLATE pg_catalog."default",
    -- 2026-04-10: Traducción automática de mensajes
    idioma_origen character varying(10) COLLATE pg_catalog."default",
    contenido_traducido text COLLATE pg_catalog."default",
    idioma_traduccion character varying(10) COLLATE pg_catalog."default",
    CONSTRAINT pk_mensajes_chat_publicidad PRIMARY KEY (mensaje_id),
    CONSTRAINT fk_mensajes_chat_publicidad_chat FOREIGN KEY (chat_id)
        REFERENCES public.chat_publicidad (chat_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE CASCADE,
    CONSTRAINT fk_mensajes_chat_publicidad_remitente FOREIGN KEY (remitente_persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT chk_mensajes_tipo_media CHECK (tipo_media IN ('image', 'video', NULL))
)

TABLESPACE pg_default;


COMMENT ON TABLE public.mensajes_chat_publicidad IS
'Mensajes dentro de chats publicitarios 1-a-1. Soporta texto e imágenes/videos adjuntos.';

COMMENT ON COLUMN public.mensajes_chat_publicidad.tipo_media IS
'Tipo de media adjunto: "image", "video", o NULL si es solo texto.';

COMMENT ON COLUMN public.mensajes_chat_publicidad.idioma_origen IS
'Código de idioma del dispositivo del remitente al momento de enviar el mensaje (ej: "es", "en", "pt"). Se usa para traducir al idioma del receptor.';

COMMENT ON COLUMN public.mensajes_chat_publicidad.contenido_traducido IS
'Caché de la última traducción aplicada al contenido. Se llena la primera vez que un receptor con idioma diferente lee el mensaje, evitando re-traducir en lecturas futuras.';

COMMENT ON COLUMN public.mensajes_chat_publicidad.idioma_traduccion IS
'Código de idioma al que se tradujo el contenido_traducido (ej: "en"). Permite invalidar el caché si el receptor tiene un idioma distinto al cacheado.';

-- Índice para búsquedas rápidas de mensajes por chat (ordenados por fecha)
CREATE INDEX IF NOT EXISTS idx_mensajes_chat_publicidad_chat
    ON public.mensajes_chat_publicidad USING btree
    (chat_id ASC NULLS LAST, fecha_envio DESC)
    TABLESPACE pg_default;

-- Índice para búsquedas rápidas por remitente
CREATE INDEX IF NOT EXISTS idx_mensajes_chat_publicidad_remitente
    ON public.mensajes_chat_publicidad USING btree
    (remitente_persona_id ASC NULLS LAST)
    TABLESPACE pg_default;

-- Índice para búsquedas rápidas de mensajes no leídos
CREATE INDEX IF NOT EXISTS idx_mensajes_chat_publicidad_leido
    ON public.mensajes_chat_publicidad (leido)
    WHERE leido = false;
