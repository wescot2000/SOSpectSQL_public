-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_poderes_regalados

-- DROP TABLE IF EXISTS migracion.migra_poderes_regalados;

CREATE TABLE IF NOT EXISTS migracion.migra_poderes_regalados
(
    id_regalo bigint,
    persona_id bigint,
    cantidad_poderes_regalada integer,
    fecha_regalo timestamp with time zone,
    calificaciones_negativas integer,
    promedio_veracidad numeric(5,4)
)

TABLESPACE pg_default;


