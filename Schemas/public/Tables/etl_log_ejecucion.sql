-- Table: public.etl_log_ejecucion

-- DROP TABLE IF EXISTS public.etl_log_ejecucion;
-- Tabla para registrar ejecuciones principales del ETL

CREATE TABLE etl_log_ejecucion (
    ejecucion_id SERIAL PRIMARY KEY,
    fecha_inicio TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_fin TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'INICIADO', -- INICIADO, COMPLETADO, ERROR
    duracion INTERVAL,
    tablas_procesadas INT DEFAULT 0,
    tablas_con_error INT DEFAULT 0,
    registros_totales_leidos BIGINT DEFAULT 0,
    registros_totales_insertados BIGINT DEFAULT 0,
    registros_totales_actualizados BIGINT DEFAULT 0,
    mensaje_error TEXT,
    usuario VARCHAR(100),
    nombre_job VARCHAR(100),
    version_job VARCHAR(50),
    parametros_ejecucion TEXT,
    ip_origen VARCHAR(50)
)

TABLESPACE pg_default;
