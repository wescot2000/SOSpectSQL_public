-- Table: public.pol_territorios
-- Módulo político: árbol geográfico de territorios administrados por autoridades electas.
-- Niveles universales (extensibles a cualquier país):
--   REGION   → Colombia: Departamento | México: Estado | España: Comunidad Autónoma
--   CIUDAD   → Colombia: Municipio    | México: Municipio | España: Municipio
--   DISTRITO → Colombia: Comuna/JAL   | México: Colonia   | España: Distrito
-- El nivel PAIS usa la tabla paises existente (pais_id CHAR(2) ISO Alpha-2).
-- Requiere extensión ltree: CREATE EXTENSION IF NOT EXISTS ltree;

CREATE TABLE IF NOT EXISTS public.pol_territorios
(
    territorio_id       INTEGER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nivel               VARCHAR(20)     NOT NULL,
    -- 'REGION' (ej: Departamento), 'CIUDAD' (ej: Municipio), 'DISTRITO' (ej: Comuna/JAL)
    nombre_nivel_local  VARCHAR(50),
    -- Nombre local del nivel para mostrar en UI: 'Departamento', 'Estado', 'Provincia', etc.
    nombre              VARCHAR(150)    NOT NULL,
    nombre_oficial      VARCHAR(150),
    -- Nombre formal completo si difiere del nombre corto
    codigo_dane         VARCHAR(20),
    -- Código DANE Colombia (Departamento:2dig, Municipio:5dig, Comuna:variable)
    parent_id           INTEGER
                        REFERENCES public.pol_territorios(territorio_id) ON DELETE RESTRICT,
    -- FK al territorio padre. Poblado para CIUDAD y DISTRITO.
    parent_pais_id      CHAR(2)
                        REFERENCES public.paises(pais_id) ON DELETE RESTRICT,
    -- FK al país. Poblado solo para REGION (nivel más alto en esta tabla).
    path                ltree,
    -- Ruta jerárquica. Ej: CO.76 (Valle del Cauca) | CO.76.76001 (Cali) | CO.76.76001.18 (Comuna 18)
    activo              BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

    CONSTRAINT chk_pol_territorios_nivel
        CHECK (nivel IN ('REGION', 'CIUDAD', 'DISTRITO')),

    CONSTRAINT chk_pol_territorios_parent
        CHECK (
            (nivel = 'REGION'
             AND parent_pais_id IS NOT NULL
             AND parent_id IS NULL)
         OR (nivel IN ('CIUDAD', 'DISTRITO')
             AND parent_id IS NOT NULL
             AND parent_pais_id IS NULL)
        )
)

TABLESPACE pg_default;

COMMENT ON TABLE public.pol_territorios IS
'Árbol geográfico de territorios para el módulo político. Niveles universales: REGION (departamento/estado), CIUDAD (municipio), DISTRITO (comuna/localidad/JAL). El nivel PAIS usa la tabla paises. Prefijo pol_ = módulo político.';

COMMENT ON COLUMN public.pol_territorios.nivel IS
'Nivel jerárquico universal: REGION (hijo de paises), CIUDAD (hijo de REGION), DISTRITO (hijo de CIUDAD).';

COMMENT ON COLUMN public.pol_territorios.nombre_nivel_local IS
'Nombre local del nivel para mostrar en UI según país. Colombia: Departamento/Municipio/Comuna. México: Estado/Municipio/Colonia.';

COMMENT ON COLUMN public.pol_territorios.path IS
'Ruta ltree. Ejemplo: CO.76 (Valle del Cauca), CO.76.76001 (Cali), CO.76.76001.18 (Comuna 18 Cali). Requiere extensión ltree.';

COMMENT ON COLUMN public.pol_territorios.parent_pais_id IS
'FK a paises.pais_id. Poblado solo cuando nivel=REGION.';

COMMENT ON COLUMN public.pol_territorios.parent_id IS
'FK al territorio padre en esta misma tabla. Poblado cuando nivel=CIUDAD o DISTRITO.';

-- Índice GiST para consultas ltree (ancestros, descendientes)
CREATE INDEX IF NOT EXISTS idx_pol_territorios_path
    ON public.pol_territorios USING GIST (path);

CREATE INDEX IF NOT EXISTS idx_pol_territorios_nivel
    ON public.pol_territorios(nivel);

CREATE INDEX IF NOT EXISTS idx_pol_territorios_parent_id
    ON public.pol_territorios(parent_id)
    WHERE parent_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_pol_territorios_parent_pais
    ON public.pol_territorios(parent_pais_id)
    WHERE parent_pais_id IS NOT NULL;
