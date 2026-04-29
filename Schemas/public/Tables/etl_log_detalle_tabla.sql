-- Table: public.etl_log_detalle_tabla

-- DROP TABLE IF EXISTS public.etl_log_detalle_tabla;
-- Tabla para registrar detalles de cada tabla procesada

CREATE TABLE etl_log_detalle_tabla (
    detalle_id SERIAL PRIMARY KEY,
    ejecucion_id INT REFERENCES etl_log_ejecucion(ejecucion_id),
    nombre_tabla VARCHAR(100) NOT NULL,
    esquema_origen VARCHAR(50),
    esquema_destino VARCHAR(50),
    fecha_inicio_proceso TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_fin_proceso TIMESTAMP,
    duracion INTERVAL,
    estado VARCHAR(20) NOT NULL DEFAULT 'INICIADO', -- INICIADO, COMPLETADO, ERROR, OMITIDO
    registros_leidos BIGINT DEFAULT 0,
    registros_insertados BIGINT DEFAULT 0,
    registros_actualizados BIGINT DEFAULT 0,
    registros_rechazados BIGINT DEFAULT 0,
    registros_con_error BIGINT DEFAULT 0,
    mensaje_error TEXT,
    query_origen TEXT,
    componente_talend VARCHAR(100),
    orden_ejecucion INT
)

TABLESPACE pg_default;
