-- Table: public.emprendimientos
-- Creado: 13-01-2026
-- Propósito: Separar datos de emprendimientos de personas, permitiendo multi-emprendimiento por usuario

-- DROP TABLE IF EXISTS public.emprendimientos CASCADE;

CREATE TABLE IF NOT EXISTS public.emprendimientos
(
    id_emprendimiento bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id_modificadora bigint NOT NULL,
    nombre_emprendimiento character varying(500) COLLATE pg_catalog."default" NOT NULL,
    nit_cedula_propietario character varying(80) COLLATE pg_catalog."default" NOT NULL,
    nombre_propietario character varying(500) COLLATE pg_catalog."default",
    url_logo character varying(500) COLLATE pg_catalog."default",
    flag_es_usuario_propietario boolean DEFAULT FALSE,
    fecha_inicio timestamp with time zone DEFAULT NOW(),
    fecha_fin timestamp with time zone DEFAULT NULL,
    reputacion_promedio numeric(3,2) DEFAULT 0.00,
    total_calificaciones integer DEFAULT 0,
    promedio_tiempo_respuesta_minutos integer DEFAULT 0,
    promedio_tiempo_entrega_horas integer DEFAULT 0,
    porcentaje_satisfaccion numeric(5,2) DEFAULT 0.00,
    total_chats_mes_actual integer DEFAULT 0,
    total_transacciones_exitosas integer DEFAULT 0,
    badges_ganados jsonb DEFAULT '[]'::jsonb,
    fecha_actualizacion_metricas timestamp with time zone,
    CONSTRAINT pk_emprendimientos PRIMARY KEY (id_emprendimiento),
    -- REMOVIDO 16-01-2026: Constraint UNIQUE simple no permite versionamiento
    -- CONSTRAINT uk_nit_cedula_propietario UNIQUE (nit_cedula_propietario),
    CONSTRAINT fk_emprendimientos_persona FOREIGN KEY (persona_id_modificadora)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT chk_reputacion CHECK (reputacion_promedio >= 0.00 AND reputacion_promedio <= 5.00),
    CONSTRAINT chk_satisfaccion CHECK (porcentaje_satisfaccion >= 0.00 AND porcentaje_satisfaccion <= 100.00)
)

TABLESPACE pg_default;


-- Comentarios
COMMENT ON TABLE public.emprendimientos IS
'Tabla de emprendimientos. Permite que un usuario gestione múltiples negocios. Las métricas de reputación y gamificación están atadas al emprendimiento, no a la persona.';

COMMENT ON COLUMN public.emprendimientos.id_emprendimiento IS
'Identificador único del emprendimiento (autogenerado)';

COMMENT ON COLUMN public.emprendimientos.persona_id_modificadora IS
'Usuario que actualmente está modificando/gestionando este emprendimiento. Puede cambiar con el tiempo.';

COMMENT ON COLUMN public.emprendimientos.nombre_emprendimiento IS
'Nombre comercial del emprendimiento (máximo 500 caracteres)';

COMMENT ON COLUMN public.emprendimientos.nit_cedula_propietario IS
'NIT o Cédula del propietario legal del emprendimiento. Es único y sirve como identificador para multi-usuario.';

COMMENT ON COLUMN public.emprendimientos.nombre_propietario IS
'Nombre del propietario legal del emprendimiento';

COMMENT ON COLUMN public.emprendimientos.url_logo IS
'URL del logo circular del emprendimiento (1024x1024 PNG, almacenado en S3). ÚNICO lugar donde se almacena el logo (NO en subscripciones). Se reutiliza en todas las promociones del emprendimiento. Versionamiento: cambiar logo crea nuevo registro con fecha_inicio=NOW(), cierra anterior con fecha_fin=NOW().';

COMMENT ON COLUMN public.emprendimientos.flag_es_usuario_propietario IS
'TRUE si el usuario actual (persona_id_modificadora) es el propietario legal que puede editar nombre y logo. FALSE si es subalterno.';

COMMENT ON COLUMN public.emprendimientos.fecha_inicio IS
'Fecha de creación del registro del emprendimiento en el sistema. Para versionamiento de logo: al cambiar logo se crea nuevo registro con fecha_inicio=NOW().';

COMMENT ON COLUMN public.emprendimientos.fecha_fin IS
'Fecha de fin de vigencia del emprendimiento (NULL si está activo). Para versionamiento: al cambiar logo se cierra registro anterior con fecha_fin=NOW(). Para consultar registro activo: WHERE fecha_fin IS NULL. Para historial: ORDER BY fecha_inicio DESC.';

COMMENT ON COLUMN public.emprendimientos.reputacion_promedio IS
'Reputación promedio calculada (0.00 a 5.00 estrellas). Calculado desde S3/Athena por proceso ETL nocturno.';

COMMENT ON COLUMN public.emprendimientos.total_calificaciones IS
'Total de calificaciones recibidas por este emprendimiento';

COMMENT ON COLUMN public.emprendimientos.promedio_tiempo_respuesta_minutos IS
'Tiempo promedio de respuesta en minutos (primera respuesta en chat). Calculado por ETL.';

COMMENT ON COLUMN public.emprendimientos.promedio_tiempo_entrega_horas IS
'Tiempo promedio de entrega en horas (desde confirmación hasta entrega). Calculado por ETL.';

COMMENT ON COLUMN public.emprendimientos.porcentaje_satisfaccion IS
'Porcentaje de satisfacción (0.00 a 100.00). Calculado desde S3/Athena por ETL.';

COMMENT ON COLUMN public.emprendimientos.total_chats_mes_actual IS
'Total de chats del mes actual para este emprendimiento';

COMMENT ON COLUMN public.emprendimientos.total_transacciones_exitosas IS
'Total de transacciones completadas exitosamente por este emprendimiento';

COMMENT ON COLUMN public.emprendimientos.badges_ganados IS
'Badges ganados (logros) por este emprendimiento. Array JSON de objetos: [{"id": "respuesta_rapida", "nombre": "Respuesta Rápida", "icono": "⚡"}]';

COMMENT ON COLUMN public.emprendimientos.fecha_actualizacion_metricas IS
'Fecha de la última actualización de las métricas de gamificación (actualizado por ETL nocturno)';

-- Índices
-- Index: idx_emprendimientos_persona

CREATE INDEX IF NOT EXISTS idx_emprendimientos_persona
    ON public.emprendimientos USING btree
    (persona_id_modificadora ASC NULLS LAST)
    TABLESPACE pg_default;

COMMENT ON INDEX public.idx_emprendimientos_persona IS
'Índice para listar emprendimientos de un usuario específico';

-- Index: idx_emprendimientos_activos

CREATE INDEX IF NOT EXISTS idx_emprendimientos_activos
    ON public.emprendimientos USING btree
    (fecha_fin ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE fecha_fin IS NULL;

COMMENT ON INDEX public.idx_emprendimientos_activos IS
'Índice para listar solo emprendimientos activos (fecha_fin IS NULL)';

-- Index: idx_emprendimientos_reputacion

CREATE INDEX IF NOT EXISTS idx_emprendimientos_reputacion
    ON public.emprendimientos USING btree
    (reputacion_promedio DESC NULLS LAST)
    TABLESPACE pg_default
    WHERE fecha_fin IS NULL;

COMMENT ON INDEX public.idx_emprendimientos_reputacion IS
'Índice para búsquedas ordenadas por reputación (solo emprendimientos activos)';

-- AGREGADO 16-01-2026: UNIQUE PARTIAL INDEX para versionamiento
-- Permite múltiples registros con el mismo NIT (para historial de logos)
-- pero GARANTIZA que solo UNO esté activo (fecha_fin IS NULL)
CREATE UNIQUE INDEX IF NOT EXISTS idx_uk_nit_cedula_activo
    ON public.emprendimientos USING btree
    (nit_cedula_propietario COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE fecha_fin IS NULL;

COMMENT ON INDEX public.idx_uk_nit_cedula_activo IS
'Índice único parcial: garantiza que solo exista UN emprendimiento activo por NIT (fecha_fin IS NULL). Permite múltiples registros históricos del mismo NIT para versionamiento de logos.';
