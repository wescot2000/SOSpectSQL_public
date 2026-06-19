-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_radio_alarmas

-- DROP TABLE IF EXISTS migracion.migra_radio_alarmas;

CREATE TABLE IF NOT EXISTS migracion.migra_radio_alarmas
(
    radio_alarmas_id integer,
    radio_mts integer,
    radio_double numeric(8,6),
    poderes_consumidos integer
)

TABLESPACE pg_default;


