-- Table: public.subscripciones
-- ACTUALIZADO: 14-01-2026 - Refactorización Multi-Emprendimiento
-- CAMBIOS:
--   1. Agregado campo id_emprendimiento para asociar suscripciones publicitarias a emprendimientos (13-01-2026)
--   2. ELIMINADO campo tipo_subscripcion (redundante, viola 3NF) - Usar JOIN con tiposubscripcion (14-01-2026)
--   3. ELIMINADO campo url_logo - Logo solo en emprendimientos.url_logo con versionamiento (14-01-2026)

-- DROP TABLE IF EXISTS public.subscripciones;

CREATE TABLE IF NOT EXISTS public.subscripciones
(
    subscripcion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    ubicacion_id bigint,
    radio_alarmas_id integer,
    persona_id bigint NOT NULL,
    tipo_subscr_id integer NOT NULL,
    fecha_activacion timestamp with time zone,
    fecha_finalizacion timestamp with time zone,
    poderes_consumidos integer,
    id_rel_protegido bigint,
    cantidad_protegidos_adquirida integer,
    observaciones character varying(500) COLLATE pg_catalog."default",
    radio_publicidad integer,
    flag_notifica_publicidad boolean,
    alarma_id bigint,
    radio_metros integer,
    duracion_dias integer,
    logo_habilitado boolean DEFAULT false,
    contacto_habilitado boolean DEFAULT false,
    domicilio_habilitado boolean DEFAULT false,
    cantidad_media_adjunta integer DEFAULT 1,
    usuarios_push_notificados integer DEFAULT 0,
    texto_push_personalizado character varying(200) COLLATE pg_catalog."default",
    proveedor_acepto_terminos_chat boolean DEFAULT false,
    fecha_proveedor_acepto_terminos timestamp with time zone,
    id_emprendimiento bigint,
    CONSTRAINT pk_subscripciones PRIMARY KEY (subscripcion_id),
    CONSTRAINT fk_subscrip_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_subscrip_reference_radio_al FOREIGN KEY (radio_alarmas_id)
        REFERENCES public.radio_alarmas (radio_alarmas_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_subscrip_reference_relprotegidos FOREIGN KEY (id_rel_protegido)
        REFERENCES public.relacion_protegidos (id_rel_protegido) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_subscrip_reference_tiposubscr FOREIGN KEY (tipo_subscr_id)
        REFERENCES public.tiposubscripcion (tipo_subscr_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_subscripciones_alarma FOREIGN KEY (alarma_id)
        REFERENCES public.alarmas (alarma_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE CASCADE,
    CONSTRAINT fk_subscripciones_emprendimiento FOREIGN KEY (id_emprendimiento)
        REFERENCES public.emprendimientos (id_emprendimiento) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    -- NOTA: Constraints de tipo_subscripcion eliminados porque el campo fue eliminado
    -- Para validar tipo de subscripción, hacer JOIN con tiposubscripcion usando tipo_subscr_id
    CONSTRAINT chk_subscripciones_cantidad_media CHECK (
        cantidad_media_adjunta BETWEEN 0 AND 10
    )
)

TABLESPACE pg_default;

-- Index: fki_fk_subscrip_reference_relprotegidos

-- DROP INDEX IF EXISTS public.fki_fk_subscrip_reference_relprotegidos;

CREATE INDEX IF NOT EXISTS fki_fk_subscrip_reference_relprotegidos
    ON public.subscripciones USING btree
    (id_rel_protegido ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_subscripciones_fecha_finalizacion

-- DROP INDEX IF EXISTS public.idx_subscripciones_fecha_finalizacion;

CREATE INDEX IF NOT EXISTS idx_subscripciones_fecha_finalizacion
    ON public.subscripciones USING btree
    (fecha_finalizacion ASC NULLS LAST)
    TABLESPACE pg_default;

-- Índice para búsquedas rápidas de subscripciones publicitarias activas
CREATE INDEX IF NOT EXISTS idx_subscripciones_publicidad_activa
    ON public.subscripciones(alarma_id, fecha_finalizacion)
    WHERE alarma_id IS NOT NULL;

-- Índice para búsquedas por emprendimiento (agregado 13-01-2026)
CREATE INDEX IF NOT EXISTS idx_subscripciones_emprendimiento
    ON public.subscripciones(id_emprendimiento)
    WHERE id_emprendimiento IS NOT NULL;

-- Comentarios para las columnas
COMMENT ON COLUMN public.subscripciones.tipo_subscr_id IS
'FK a tiposubscripcion. Para obtener el tipo de subscripción hacer JOIN: SELECT s.*, t.descripcion FROM subscripciones s JOIN tiposubscripcion t ON s.tipo_subscr_id = t.tipo_subscr_id. Campo tipo_subscripcion (VARCHAR) fue eliminado por redundancia (14-01-2026).';

COMMENT ON COLUMN public.subscripciones.alarma_id IS
'ID de la alarma asociada (solo para subscripciones de tipo "publicidad"). NULL para otros tipos de subscripción.';

COMMENT ON COLUMN public.subscripciones.radio_metros IS
'Radio de alcance en metros (solo para subscripciones de tipo "publicidad"). Define el área geográfica donde la alarma publicitaria será visible.';

COMMENT ON COLUMN public.subscripciones.duracion_dias IS
'Duración en días de la subscripción publicitaria. Se usa para calcular fecha_finalizacion.';

COMMENT ON COLUMN public.subscripciones.logo_habilitado IS
'Indica si el anunciante pagó por incluir logo (+10 poderes)';

COMMENT ON COLUMN public.subscripciones.contacto_habilitado IS
'Indica si se habilitó chat privado (+5 poderes)';

COMMENT ON COLUMN public.subscripciones.domicilio_habilitado IS
'Indica si se habilitó opción de domicilio/envío (+5 poderes)';

COMMENT ON COLUMN public.subscripciones.cantidad_media_adjunta IS
'Cantidad de fotos/videos incluidos en la promoción. Base: 1 (incluida). Cada adicional +20 poderes. Máximo: 10.';

COMMENT ON COLUMN public.subscripciones.usuarios_push_notificados IS
'Cantidad de usuarios que fueron notificados vía push (solo si se pagó por notificaciones push). Costo: +20 poderes por cada 50 usuarios.';

COMMENT ON COLUMN public.subscripciones.texto_push_personalizado IS
'Texto personalizado para notificación push (máximo 200 caracteres). NULL si no se pagó por push.';

COMMENT ON COLUMN public.subscripciones.proveedor_acepto_terminos_chat IS
'Indica si el proveedor aceptó los términos del chat al crear esta alarma promocional.';

COMMENT ON COLUMN public.subscripciones.fecha_proveedor_acepto_terminos IS
'Fecha y hora en que el proveedor aceptó los términos del chat para esta alarma promocional. Se hereda a todos los chats creados para esta alarma.';

COMMENT ON COLUMN public.subscripciones.id_emprendimiento IS
'FK a emprendimientos. Asocia esta suscripción publicitaria a un emprendimiento específico. El logo del emprendimiento está en emprendimientos.url_logo (NO en subscripciones). Agregado: 13-01-2026.';