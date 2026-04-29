-- Table: public.pol_cargos
-- Módulo político: catálogo de cargos públicos electos.
-- El nivel_territorial indica a qué nivel del árbol geográfico corresponde el cargo,
-- permitiendo construir la cadena de responsabilidad:
--   Edil (DISTRITO) → Alcalde (CIUDAD) → Gobernador (REGION) → Presidente (PAIS)

CREATE TABLE IF NOT EXISTS public.pol_cargos
(
    cargo_id            SMALLINT        PRIMARY KEY,
    nombre_cargo        VARCHAR(100)    NOT NULL,
    -- Nombre descriptivo del cargo. Ej: 'Presidente', 'Alcalde'
    -- La app muestra el nombre localizado al usuario via AppResources clave "Cargo_{cargo_id}"
    nivel_territorial   VARCHAR(20)     NOT NULL,
    -- Nivel del árbol geográfico que administra este cargo
    orden_jerarquico    SMALLINT        NOT NULL,
    -- 1 = más alto (Presidente); 4 = más granular (Edil)
    activo              BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_pol_cargos_nivel
        CHECK (nivel_territorial IN ('PAIS', 'REGION', 'CIUDAD', 'DISTRITO'))
)

TABLESPACE pg_default;

COMMENT ON TABLE public.pol_cargos IS
'Catálogo de cargos políticos electos. nombre_es es el descriptivo canónico para queries en BD. La app localiza el nombre al idioma del usuario via AppResources clave "Cargo_{cargo_id}".';

COMMENT ON COLUMN public.pol_cargos.nombre_cargo IS
'Nombre descriptivo del cargo. Usado en queries directos sobre la BD. La app usa AppResources clave "Cargo_{cargo_id}" para mostrar el nombre en el idioma del usuario.';

COMMENT ON COLUMN public.pol_cargos.nivel_territorial IS
'Nivel del árbol geográfico: PAIS (presidente), REGION (gobernador/estado), CIUDAD (alcalde/municipio), DISTRITO (edil/JAL/comuna).';

COMMENT ON COLUMN public.pol_cargos.orden_jerarquico IS
'Posición en la cadena de autoridad. 1=Presidente (mayor jerarquía), 4=Edil (más granular). Ordena la lista en la pantalla MAUI de menor a mayor granularidad.';

