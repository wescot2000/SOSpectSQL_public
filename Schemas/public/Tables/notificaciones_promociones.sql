-- Table: public.notificaciones_promociones
-- Propósito: Auditoría de usuarios notificados en promociones locales
-- Creado: 30-01-2026
-- Permite: Ver CUÁLES usuarios fueron incluidos en el envío de push notifications
-- IMPORTANTE: envio_aceptado_firebase indica si Firebase ACEPTÓ el mensaje,
--             NO garantiza entrega al dispositivo del usuario.

-- DROP TABLE IF EXISTS public.notificaciones_promociones;

CREATE TABLE IF NOT EXISTS public.notificaciones_promociones
(
    id_notificacion_promocion bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    subscripcion_id bigint NOT NULL,
    user_id_thirdparty character varying(150) COLLATE pg_catalog."default" NOT NULL,
    envio_aceptado_firebase boolean DEFAULT NULL,
    error_code character varying(50) COLLATE pg_catalog."default" DEFAULT NULL,
    -- NOTA: fecha_envio NO se guarda aquí, usar subscripciones.fecha_activacion

    CONSTRAINT pk_notificaciones_promociones PRIMARY KEY (id_notificacion_promocion),
    CONSTRAINT fk_notif_promo_subscripcion FOREIGN KEY (subscripcion_id)
        REFERENCES public.subscripciones (subscripcion_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE CASCADE,
    CONSTRAINT chk_notif_promo_user_id CHECK (LENGTH(user_id_thirdparty) > 0)
)

TABLESPACE pg_default;


-- Índice para búsquedas por suscripción (consulta principal de auditoría)
CREATE INDEX IF NOT EXISTS idx_notif_promo_subscripcion
    ON public.notificaciones_promociones USING btree
    (subscripcion_id ASC NULLS LAST)
    TABLESPACE pg_default;

-- Índice para búsquedas por usuario (si se necesita historial de notificaciones de un usuario)
CREATE INDEX IF NOT EXISTS idx_notif_promo_user_id
    ON public.notificaciones_promociones USING btree
    (user_id_thirdparty ASC NULLS LAST)
    TABLESPACE pg_default;

-- Índice compuesto para consultas de auditoría por promoción y estado
CREATE INDEX IF NOT EXISTS idx_notif_promo_audit
    ON public.notificaciones_promociones USING btree
    (subscripcion_id ASC NULLS LAST, envio_aceptado_firebase ASC NULLS LAST)
    TABLESPACE pg_default;

-- Comentarios para documentación
COMMENT ON TABLE public.notificaciones_promociones IS
'Auditoría de usuarios notificados en promociones locales. Permite ver CUÁLES usuarios fueron incluidos en el envío de push notifications para cada suscripción promocional.';

COMMENT ON COLUMN public.notificaciones_promociones.id_notificacion_promocion IS
'Identificador único del registro de notificación.';

COMMENT ON COLUMN public.notificaciones_promociones.subscripcion_id IS
'FK a subscripciones. Identifica la suscripción promocional a la que pertenece esta notificación.';

COMMENT ON COLUMN public.notificaciones_promociones.user_id_thirdparty IS
'Identificador anónimo del usuario notificado (Firebase UID). El propietario de la promoción puede reconocer IDs de conocidos para verificar transparencia.';

COMMENT ON COLUMN public.notificaciones_promociones.envio_aceptado_firebase IS
'Indica si Firebase Cloud Messaging ACEPTÓ el mensaje (TRUE/FALSE). NULL si aún no se ha procesado. IMPORTANTE: TRUE NO garantiza entrega al dispositivo - solo significa que Firebase lo tiene en cola para intentar entregar.';

COMMENT ON COLUMN public.notificaciones_promociones.error_code IS
'Código de error de Firebase si el envío fue rechazado. Valores comunes: UNREGISTERED (app desinstalada), INVALID_TOKEN (token FCM inválido), SENDER_ID_MISMATCH (configuración incorrecta).';
