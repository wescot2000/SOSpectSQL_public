-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_atencion_policiaca

-- DROP TABLE IF EXISTS migracion.migra_atencion_policiaca;

CREATE TABLE IF NOT EXISTS migracion.migra_atencion_policiaca
(
    atencion_policiaca_id bigint,
    alarma_id bigint,
    persona_id bigint,
    fecha_autoasignacion timestamp with time zone
)

TABLESPACE pg_default;


