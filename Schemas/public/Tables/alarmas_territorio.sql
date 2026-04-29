-- Table: public.alarmas_territorio

-- DROP TABLE IF EXISTS public.alarmas_territorio;

CREATE TABLE IF NOT EXISTS public.alarmas_territorio
(
    alarma_id           BIGINT PRIMARY KEY,
    barrio              VARCHAR(150),        -- NULLABLE: Nivel más granular (neighborhood)
    ciudad              VARCHAR(150),        -- NULLABLE: Ciudad o municipio (locality)
    pais                VARCHAR(100),        -- NULLABLE: País (country)
    barrio_normalizado  VARCHAR(150),        -- lowercase sin tildes; calculado por TerritorialService al insertar
    ciudad_normalizada  VARCHAR(150),        -- lowercase sin tildes; calculado por TerritorialService al insertar
    created_at          TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT fk_alarmas_territorio_alarmas
        FOREIGN KEY (alarma_id)
        REFERENCES public.alarmas (alarma_id)
        ON DELETE CASCADE
)

TABLESPACE pg_default;


COMMENT ON TABLE public.alarmas_territorio IS
'Almacena información territorial mínima y universal para operación de la app. Vigencia: 32 días (datos transaccionales). Solo guarda 3 campos extraídos de Google Reverse Geocoding. El JSON completo se almacena en S3 para analítica histórica.';

COMMENT ON COLUMN public.alarmas_territorio.alarma_id IS
'ID único de la alarma (PK y FK a public.alarmas)';

COMMENT ON COLUMN public.alarmas_territorio.barrio IS
'Nombre del barrio o vecindario extraído de tipo "neighborhood" de Google. NULLABLE: No todos los países/ciudades tienen este nivel. Ejemplo: "Normandía", "Unicentro", "El Poblado"';

COMMENT ON COLUMN public.alarmas_territorio.ciudad IS
'Nombre de la ciudad o municipio extraído de tipo "locality" de Google. NULLABLE: Permite flexibilidad global. Ejemplo: "Bogotá", "Medellín", "Ciudad de México"';

COMMENT ON COLUMN public.alarmas_territorio.pais IS
'Nombre del país extraído de tipo "country" de Google. NULLABLE: Permite manejo de casos edge. Ejemplo: "Colombia", "México", "Argentina"';

COMMENT ON COLUMN public.alarmas_territorio.barrio_normalizado IS
'Barrio en minúsculas sin tildes (calculado por TerritorialService al insertar). Usado para join con pol_homologacion_google sin llamar unaccent() en tiempo de consulta.';

COMMENT ON COLUMN public.alarmas_territorio.ciudad_normalizada IS
'Ciudad en minúsculas sin tildes (calculado por TerritorialService al insertar). Usado para join con pol_homologacion_google sin llamar unaccent() en tiempo de consulta.';

COMMENT ON COLUMN public.alarmas_territorio.created_at IS
'Timestamp de creación del registro territorial';

-- Índice compuesto para queries geográficas
CREATE INDEX IF NOT EXISTS idx_alarmas_territorio_pais_ciudad
ON public.alarmas_territorio(pais, ciudad);

-- Índice para búsquedas por barrio
CREATE INDEX IF NOT EXISTS idx_alarmas_territorio_barrio
ON public.alarmas_territorio(barrio)
WHERE barrio IS NOT NULL;

-- Índice para búsquedas por país
CREATE INDEX IF NOT EXISTS idx_alarmas_territorio_pais
ON public.alarmas_territorio(pais)
WHERE pais IS NOT NULL;

-- Índice para búsquedas por ciudad
CREATE INDEX IF NOT EXISTS idx_alarmas_territorio_ciudad
ON public.alarmas_territorio(ciudad)
WHERE ciudad IS NOT NULL;
