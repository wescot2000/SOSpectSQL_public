-- Table: public.personas
-- ACTUALIZADO: 13-01-2026 - Refactorización Multi-Emprendimiento
-- CAMBIOS: Eliminados campos de métricas y emprendimiento (movidos a tabla emprendimientos)
-- ACTUALIZADO: 2026-02-26 - Agregar paises_feed_filtro para filtro de países en feed "Para Ti"
-- ACTUALIZADO: 2026-04-02 - Agregar nickname: apodo asignado por el líder al agregar un usuario a su red de confianza

-- DROP TABLE IF EXISTS public.personas;

CREATE TABLE IF NOT EXISTS public.personas
(
    persona_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    radio_alarmas_id integer DEFAULT 1,
    login character varying(150) COLLATE pg_catalog."default" NOT NULL,
    user_id_thirdparty character varying(150) COLLATE pg_catalog."default" NOT NULL,
    fechacreacion date,
    marca_bloqueo integer,
    credibilidad_persona numeric(5,2) DEFAULT 100.00,
    fecha_ultima_marca_bloqueo timestamp with time zone,
    tiempo_refresco_mapa integer,
    saldo_poderes integer DEFAULT 0,
    flag_es_policia boolean,
    numeroplaca character varying(500) COLLATE pg_catalog."default",
    dependenciaasignada character varying(500) COLLATE pg_catalog."default",
    ciudad character varying(500) COLLATE pg_catalog."default",
    pais character varying(500) COLLATE pg_catalog."default",
    flag_es_admin boolean,
    remitentecambio character varying(500) COLLATE pg_catalog."default",
    fechacorreosolicitud character varying(500) COLLATE pg_catalog."default",
    asuntocorreosolicitud character varying(500) COLLATE pg_catalog."default",
    fechaaplicacionsolicitud timestamp with time zone,
    notif_alarma_cercana_habilitada boolean DEFAULT true,
    notif_alarma_protegido_habilitada boolean DEFAULT true,
    notif_alarma_zona_vigilancia_habilitada boolean DEFAULT true,
    notif_alarma_policia_habilitada boolean DEFAULT true,
    fecha_act_configuracion_notif timestamp with time zone,
    dias_notif_policia_apagada integer,
    nombres character varying(500) COLLATE pg_catalog."default",
    apellidos character varying(500) COLLATE pg_catalog."default",
    numero_movil character varying(100) COLLATE pg_catalog."default",
    email character varying(500) COLLATE pg_catalog."default",
    persona_lider_redconf_id bigint,
    national_id character varying(100) COLLATE pg_catalog."default",
    flag_red_confianza boolean,
    fecha_red_confianza timestamp with time zone,
    limite_alarmas_feed integer DEFAULT 50,
    intervalo_background_minutos integer DEFAULT 5,
    -- Filtro de países para el feed "Para Ti". NULL = sin filtro (mostrar todos los países).
    -- Array de nombres de países tal como aparecen en alarmas_territorio.pais
    paises_feed_filtro text[],
    -- Apodo asignado por el líder de red al agregar este usuario a su red de confianza.
    -- Solo puede ser establecido una vez (al momento del alta en la red). NULL si no pertenece a ninguna red.
    nickname character varying(100) COLLATE pg_catalog."default",

    -- ❌ CAMPOS ELIMINADOS (Movidos a tabla emprendimientos):
    -- es_proveedor boolean DEFAULT false,
    -- fecha_primer_promocion timestamp with time zone,
    -- url_logo_emprendimiento text,
    -- fecha_actualizacion_logo timestamp with time zone,
    -- reputacion_promedio numeric(3,2) DEFAULT 0.00,
    -- total_calificaciones integer DEFAULT 0,
    -- promedio_tiempo_respuesta_minutos integer DEFAULT 0,
    -- promedio_tiempo_entrega_horas integer DEFAULT 0,
    -- porcentaje_satisfaccion numeric(5,2) DEFAULT 0.00,
    -- total_chats_mes_actual integer DEFAULT 0,
    -- total_transacciones_exitosas integer DEFAULT 0,
    -- badges_ganados jsonb DEFAULT '[]'::jsonb,
    -- fecha_actualizacion_metricas timestamp with time zone,

    CONSTRAINT pk_personas PRIMARY KEY (persona_id),
    CONSTRAINT chk_limite_alarmas_feed CHECK (limite_alarmas_feed IN (10, 20, 25, 50, 75, 100, 125, 150, 175, 200, 300, 500)),
    CONSTRAINT chk_intervalo_background_minutos CHECK (intervalo_background_minutos >= 1 AND intervalo_background_minutos <= 30),
    CONSTRAINT "uk_3Id" UNIQUE (user_id_thirdparty),
    CONSTRAINT uk_login UNIQUE (login),
    CONSTRAINT fk_persona_reference_personalider FOREIGN KEY (persona_lider_redconf_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;


COMMENT ON TABLE public.personas IS
'Tabla de usuarios del sistema SOSpect. Contiene información personal y de configuración. Las métricas de gamificación y datos de emprendimientos están en la tabla emprendimientos (desde 13-01-2026).';

COMMENT ON COLUMN public.personas.limite_alarmas_feed IS
'Límite de alarmas a mostrar en el feed. Valores permitidos: 10, 20, 50, 100, 200, 300, 500. Por defecto: 50.';

COMMENT ON COLUMN public.personas.intervalo_background_minutos IS
'Intervalo en minutos para que el servicio de background actualice la ubicación del usuario y verifique alarmas críticas. Rango: 1-30 minutos. Por defecto: 5 minutos. Configurable por el usuario en Configuración de Notificaciones.';

COMMENT ON COLUMN public.personas.national_id IS
'Cédula o identificación nacional del usuario. Se usa para validar emprendimientos en tabla emprendimientos.';

COMMENT ON COLUMN public.personas.nickname IS
'Apodo asignado por el líder de red de confianza al momento de agregar este usuario. Permite al líder reconocer al miembro aunque sus datos reales sean anónimos. Solo se establece una vez, en la acción de alta en la red.';

-- Index: idx_idpersonas

-- DROP INDEX IF EXISTS public.idx_idpersonas;

CREATE INDEX IF NOT EXISTS idx_idpersonas
    ON public.personas USING btree
    (user_id_thirdparty COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: idx_loginpersonas

-- DROP INDEX IF EXISTS public.idx_loginpersonas;

CREATE INDEX IF NOT EXISTS idx_loginpersonas
    ON public.personas USING btree
    (login COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

-- ❌ ÍNDICES ELIMINADOS (campos movidos a emprendimientos):
-- DROP INDEX IF EXISTS public.idx_personas_es_proveedor;
-- DROP INDEX IF EXISTS public.idx_personas_reputacion;
