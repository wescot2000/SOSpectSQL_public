-- Table: public.paises
-- Tabla maestra de países con código ISO Alpha-2 como PK
-- Creado: 2026-02-26
-- Propósito: Tabla maestra de países para resolver código ISO alpha-2 → nombre legible en español.
-- Relacionada con: personas.pais (ISO alpha-2), dispositivos.pais_id (ISO alpha-2), ubicaciones.pais_id (ISO alpha-2)
-- Nota: paises_convenios.pais_id usa ISO alpha-3 (COL, MEX) — estándar distinto.
--       Se agrega iso_alpha_2 a paises_convenios para mantener compatibilidad.

CREATE TABLE IF NOT EXISTS public.paises
(
    pais_id char(2) NOT NULL,           -- ISO Alpha-2: CO, MX, US, AR
    nombre_es varchar(100),    -- Nombre en español: Colombia, México, Argentina
    name_en varchar(100),
    nom varchar(100),
    iso3 varchar(3),
    phone_code varchar(100),
    continente varchar(100),
    CONSTRAINT pk_paises PRIMARY KEY (pais_id)
)
TABLESPACE pg_default;


COMMENT ON TABLE public.paises IS 'Tabla maestra de países. pais_id = ISO Alpha-2 (2 caracteres: CO, MX, US). nombre_es = nombre en español. Usada para resolver personas.pais, dispositivos.pais_id y ubicaciones.pais_id.';
