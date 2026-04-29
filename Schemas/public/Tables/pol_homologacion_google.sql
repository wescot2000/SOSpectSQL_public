-- Table: public.pol_homologacion_google
-- Módulo político: mapea los nombres que devuelve Google Reverse Geocoding
-- a territorios oficiales en pol_territorios.
--
-- Resuelve dos problemas:
--   1. Variantes de nombre: "Bogotá", "Bogota", "Bogotá D.C.", "Santafé de Bogotá" → mismo CIUDAD
--   2. Salto de nivel: barrio (Google) → DISTRITO (la comarca del edil)
--      "Simón Bolívar", "Simon Bolivar", "Barrio Simón Bolívar" → Comuna 18 de Cali
--
-- nivel_google:
--   'barrio' → territorio_id debe ser un DISTRITO (el edil no es por barrio sino por comuna)
--   'ciudad' → territorio_id debe ser una CIUDAD (municipio)
--
-- El matching siempre usa nombre_google_normalizado (lowercase sin tildes) para mayor tolerancia.

CREATE TABLE IF NOT EXISTS public.pol_homologacion_google
(
    homologacion_id             INTEGER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_google               VARCHAR(200)    NOT NULL,
    -- Texto exacto tal como lo devuelve Google Reverse Geocoding
    nombre_google_normalizado   VARCHAR(200)    NOT NULL,
    -- lowercase sin tildes para matching tolerante. Ej: "simón bolívar" → "simon bolivar"
    nivel_google                VARCHAR(20)     NOT NULL,
    -- 'barrio' o 'ciudad'
    territorio_id               INTEGER         NOT NULL
                                REFERENCES public.pol_territorios(territorio_id) ON DELETE CASCADE,
    -- Para nivel_google='barrio' → DISTRITO; para nivel_google='ciudad' → CIUDAD
    pais_id                     CHAR(2)         NOT NULL
                                REFERENCES public.paises(pais_id) ON DELETE CASCADE,
    -- Permite distinguir "Cali" Colombia de "Cali" si existiera en otro país
    activo                      BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

    CONSTRAINT chk_pol_homologacion_nivel
        CHECK (nivel_google IN ('barrio', 'ciudad')),

    CONSTRAINT uq_pol_homologacion
        UNIQUE (nombre_google_normalizado, nivel_google, pais_id)
)

TABLESPACE pg_default;

COMMENT ON TABLE public.pol_homologacion_google IS
'Mapea variantes de nombres de Google Reverse Geocoding a territorios oficiales en pol_territorios. nivel_google=barrio resuelve a DISTRITO (comuna); nivel_google=ciudad resuelve a CIUDAD (municipio). El matching usa nombre_google_normalizado (lowercase, sin tildes).';

COMMENT ON COLUMN public.pol_homologacion_google.nombre_google IS
'Texto original tal como lo devuelve Google. Se guarda para auditoría y referencia.';

COMMENT ON COLUMN public.pol_homologacion_google.nombre_google_normalizado IS
'Texto en lowercase sin tildes para matching insensible a acentos y mayúsculas. Ejemplo: "Simón Bolívar" → "simon bolivar". Generado con lower(unaccent(trim(nombre_google))).';

COMMENT ON COLUMN public.pol_homologacion_google.nivel_google IS
'Nivel del campo de Google que se mapea: barrio (neighborhood) → resuelve a DISTRITO; ciudad (locality) → resuelve a CIUDAD.';

-- Índice principal para el join de la vista (pais_id, nivel_google, nombre_google_normalizado)
CREATE INDEX IF NOT EXISTS idx_pol_homologacion_lookup
    ON public.pol_homologacion_google(pais_id, nivel_google, nombre_google_normalizado);

CREATE INDEX IF NOT EXISTS idx_pol_homologacion_territorio
    ON public.pol_homologacion_google(territorio_id);
