-- View: public.vw_autoridades_por_alarma
-- Módulo político: dado un alarma_id, devuelve la cadena completa de autoridades vigentes.
--
-- Cadena de responsabilidad: Edil (DISTRITO) → Alcalde (CIUDAD) → Gobernador (REGION) → Presidente (PAIS)
--
-- Resolución territorial con fallback en tres niveles:
--   1. barrio_normalizado → DISTRITO (comuna/JAL → Edil) — el más granular
--   2. ciudad_normalizada → CIUDAD (municipio → Alcalde) — fallback si no hay match de barrio
--   3. pais → paises.pais_id → Presidente — siempre disponible si hay país registrado
--
-- Las vigencias se filtran con CURRENT_DATE BETWEEN fecha_inicio AND COALESCE(fecha_fin, 'infinity').
-- Las métricas vienen de pol_metricas_territorio con periodo='30D'.
-- La tasa de resolución (pct_resolucion) viene de mv_metricas_politico (LEFT JOIN).
--
-- Prerequisitos:
--   CREATE EXTENSION IF NOT EXISTS unaccent;
--   Tables: pol_territorios, pol_homologacion_google, pol_cargos, pol_politicos, pol_vigencias
--   Table:  pol_metricas_territorio
--   Tables: alarmas_territorio (con barrio_normalizado, ciudad_normalizada), paises
--   Materialized view: mv_metricas_politico (creada por mv_metricas_politico.sql)
-- MODIFICADO: 2026-03-09 - Agregar pct_resolucion desde mv_metricas_politico
-- MODIFICADO: 2026-03-29 - Agregar pct_aprobacion desde mv_metricas_politico

CREATE OR REPLACE VIEW public.vw_autoridades_por_alarma AS
WITH

-- ════════════════════════════════════════════════════════════════════════════════
-- CTE 1: Resuelve el país de cada alarma (requerido para todos los niveles)
-- ════════════════════════════════════════════════════════════════════════════════
pais_alarma AS (
    SELECT
        at.alarma_id,
        p.pais_id
    FROM public.alarmas_territorio at
    JOIN public.paises p
        ON lower(unaccent(trim(at.pais))) = lower(unaccent(p.nombre_es))
),

-- ════════════════════════════════════════════════════════════════════════════════
-- CTE 2: Resuelve el DISTRITO via barrio (nivel más granular)
-- ════════════════════════════════════════════════════════════════════════════════
distrito_alarma AS (
    SELECT
        at.alarma_id,
        hg.territorio_id AS distrito_id
    FROM public.alarmas_territorio at
    JOIN pais_alarma pa ON pa.alarma_id = at.alarma_id
    JOIN public.pol_homologacion_google hg
        ON COALESCE(at.barrio_normalizado, lower(unaccent(trim(at.barrio))))
           = hg.nombre_google_normalizado
        AND hg.nivel_google = 'barrio'
        AND hg.pais_id = pa.pais_id
        AND hg.activo = TRUE
    WHERE at.barrio IS NOT NULL
),

-- ════════════════════════════════════════════════════════════════════════════════
-- CTE 3: Resuelve la CIUDAD via ciudad_normalizada (fallback cuando no hay barrio match)
-- ════════════════════════════════════════════════════════════════════════════════
ciudad_alarma AS (
    SELECT
        at.alarma_id,
        hg.territorio_id AS ciudad_id
    FROM public.alarmas_territorio at
    JOIN pais_alarma pa ON pa.alarma_id = at.alarma_id
    JOIN public.pol_homologacion_google hg
        ON COALESCE(at.ciudad_normalizada, lower(unaccent(trim(at.ciudad))))
           = hg.nombre_google_normalizado
        AND hg.nivel_google = 'ciudad'
        AND hg.pais_id = pa.pais_id
        AND hg.activo = TRUE
    WHERE at.ciudad IS NOT NULL
),

-- ════════════════════════════════════════════════════════════════════════════════
-- CTE 4: Cadena territorial completa: DISTRITO → CIUDAD → REGION
-- ════════════════════════════════════════════════════════════════════════════════
cadena AS (
    SELECT
        pa.alarma_id,
        pa.pais_id,
        da.distrito_id,
        -- CIUDAD: del DISTRITO (si existe) o directamente de ciudad_alarma
        COALESCE(pt_dist.parent_id, ca.ciudad_id) AS ciudad_id,
        -- REGION: del municipio derivado del DISTRITO, o del municipio directo
        COALESCE(
            pt_ciudad_via_dist.parent_id,
            pt_ciudad_directa.parent_id
        ) AS region_id
    FROM pais_alarma pa
    LEFT JOIN distrito_alarma da ON da.alarma_id = pa.alarma_id
    LEFT JOIN ciudad_alarma ca   ON ca.alarma_id = pa.alarma_id
    -- Subir DISTRITO → CIUDAD
    LEFT JOIN public.pol_territorios pt_dist
        ON pt_dist.territorio_id = da.distrito_id
        AND pt_dist.nivel = 'DISTRITO'
    -- Subir CIUDAD (via DISTRITO) → REGION
    LEFT JOIN public.pol_territorios pt_ciudad_via_dist
        ON pt_ciudad_via_dist.territorio_id = pt_dist.parent_id
        AND pt_ciudad_via_dist.nivel = 'CIUDAD'
    -- Subir CIUDAD (directa) → REGION
    LEFT JOIN public.pol_territorios pt_ciudad_directa
        ON pt_ciudad_directa.territorio_id = ca.ciudad_id
        AND pt_ciudad_directa.nivel = 'CIUDAD'
),

-- ════════════════════════════════════════════════════════════════════════════════
-- CTE 5: Autoridades vigentes — UNION ALL de los 4 niveles
-- ════════════════════════════════════════════════════════════════════════════════
autoridades AS (

    -- EDIL (DISTRITO / Comuna / JAL)
    SELECT
        c.alarma_id,
        cargo.orden_jerarquico,
        cargo.cargo_id,
        pol.politico_id,
        pol.nombre_completo,
        pol.foto_url,
        pol.partido,
        pol.email,
        pol.telefono,
        pol.sitio_web,
        pol.twitter,
        v.fecha_inicio,
        v.fecha_fin,
        pt.nombre               AS territorio_nombre,
        COALESCE(mt.cnt_alarmas_politico, 0) AS cnt_alarmas_30d,
        mm.pct_resolucion,
        mm.pct_aprobacion
    FROM cadena c
    JOIN public.pol_vigencias v
        ON v.territorio_id = c.distrito_id
        AND CURRENT_DATE BETWEEN v.fecha_inicio AND COALESCE(v.fecha_fin, 'infinity'::date)
        AND v.activo = TRUE
    JOIN public.pol_cargos cargo
        ON cargo.cargo_id = v.cargo_id
        AND cargo.nivel_territorial = 'DISTRITO'
    JOIN public.pol_politicos pol
        ON pol.politico_id = v.politico_id
        AND pol.activo = TRUE
    LEFT JOIN public.pol_territorios pt
        ON pt.territorio_id = c.distrito_id
    LEFT JOIN public.pol_metricas_territorio mt
        ON mt.territorio_id = c.distrito_id
        AND mt.pais_id IS NULL
        AND mt.periodo = '30D'
    LEFT JOIN public.mv_metricas_politico mm
        ON mm.politico_id = pol.politico_id
    WHERE c.distrito_id IS NOT NULL

    UNION ALL

    -- ALCALDE (CIUDAD / Municipio)
    SELECT
        c.alarma_id,
        cargo.orden_jerarquico,
        cargo.cargo_id,
        pol.politico_id,
        pol.nombre_completo,
        pol.foto_url,
        pol.partido,
        pol.email,
        pol.telefono,
        pol.sitio_web,
        pol.twitter,
        v.fecha_inicio,
        v.fecha_fin,
        pt.nombre,
        COALESCE(mt.cnt_alarmas_politico, 0),
        mm.pct_resolucion,
        mm.pct_aprobacion
    FROM cadena c
    JOIN public.pol_vigencias v
        ON v.territorio_id = c.ciudad_id
        AND CURRENT_DATE BETWEEN v.fecha_inicio AND COALESCE(v.fecha_fin, 'infinity'::date)
        AND v.activo = TRUE
    JOIN public.pol_cargos cargo
        ON cargo.cargo_id = v.cargo_id
        AND cargo.nivel_territorial = 'CIUDAD'
    JOIN public.pol_politicos pol
        ON pol.politico_id = v.politico_id
        AND pol.activo = TRUE
    LEFT JOIN public.pol_territorios pt
        ON pt.territorio_id = c.ciudad_id
    LEFT JOIN public.pol_metricas_territorio mt
        ON mt.territorio_id = c.ciudad_id
        AND mt.pais_id IS NULL
        AND mt.periodo = '30D'
    LEFT JOIN public.mv_metricas_politico mm
        ON mm.politico_id = pol.politico_id
    WHERE c.ciudad_id IS NOT NULL

    UNION ALL

    -- GOBERNADOR (REGION / Departamento)
    SELECT
        c.alarma_id,
        cargo.orden_jerarquico,
        cargo.cargo_id,
        pol.politico_id,
        pol.nombre_completo,
        pol.foto_url,
        pol.partido,
        pol.email,
        pol.telefono,
        pol.sitio_web,
        pol.twitter,
        v.fecha_inicio,
        v.fecha_fin,
        pt.nombre,
        COALESCE(mt.cnt_alarmas_politico, 0),
        mm.pct_resolucion,
        mm.pct_aprobacion
    FROM cadena c
    JOIN public.pol_vigencias v
        ON v.territorio_id = c.region_id
        AND CURRENT_DATE BETWEEN v.fecha_inicio AND COALESCE(v.fecha_fin, 'infinity'::date)
        AND v.activo = TRUE
    JOIN public.pol_cargos cargo
        ON cargo.cargo_id = v.cargo_id
        AND cargo.nivel_territorial = 'REGION'
    JOIN public.pol_politicos pol
        ON pol.politico_id = v.politico_id
        AND pol.activo = TRUE
    LEFT JOIN public.pol_territorios pt
        ON pt.territorio_id = c.region_id
    LEFT JOIN public.pol_metricas_territorio mt
        ON mt.territorio_id = c.region_id
        AND mt.pais_id IS NULL
        AND mt.periodo = '30D'
    LEFT JOIN public.mv_metricas_politico mm
        ON mm.politico_id = pol.politico_id
    WHERE c.region_id IS NOT NULL

    UNION ALL

    -- PRESIDENTE (PAIS)
    SELECT
        c.alarma_id,
        cargo.orden_jerarquico,
        cargo.cargo_id,
        pol.politico_id,
        pol.nombre_completo,
        pol.foto_url,
        pol.partido,
        pol.email,
        pol.telefono,
        pol.sitio_web,
        pol.twitter,
        v.fecha_inicio,
        v.fecha_fin,
        pa.nombre_es            AS territorio_nombre,
        COALESCE(mt.cnt_alarmas_politico, 0),
        mm.pct_resolucion,
        mm.pct_aprobacion
    FROM cadena c
    JOIN public.pol_vigencias v
        ON v.pais_id = c.pais_id
        AND v.cargo_id = 1
        AND CURRENT_DATE BETWEEN v.fecha_inicio AND COALESCE(v.fecha_fin, 'infinity'::date)
        AND v.activo = TRUE
    JOIN public.pol_cargos cargo
        ON cargo.cargo_id = v.cargo_id
    JOIN public.pol_politicos pol
        ON pol.politico_id = v.politico_id
        AND pol.activo = TRUE
    JOIN public.paises pa
        ON pa.pais_id = c.pais_id
    LEFT JOIN public.pol_metricas_territorio mt
        ON mt.pais_id = c.pais_id
        AND mt.territorio_id IS NULL
        AND mt.periodo = '30D'
    LEFT JOIN public.mv_metricas_politico mm
        ON mm.politico_id = pol.politico_id
    WHERE c.pais_id IS NOT NULL

)

SELECT
    alarma_id,
    orden_jerarquico,
    cargo_id,
    politico_id,
    nombre_completo,
    foto_url,
    partido,
    email,
    telefono,
    sitio_web,
    twitter,
    fecha_inicio,
    fecha_fin,
    territorio_nombre,
    cnt_alarmas_30d,
    pct_resolucion,
    pct_aprobacion
FROM autoridades
ORDER BY alarma_id, orden_jerarquico;

COMMENT ON VIEW public.vw_autoridades_por_alarma IS
'Dado un alarma_id, resuelve la cadena completa de autoridades vigentes (Edil/DISTRITO → Alcalde/CIUDAD → Gobernador/REGION → Presidente/PAIS). Usa pol_homologacion_google para mapear barrio/ciudad de Google a territorios oficiales. Incluye fallback: si barrio no resuelve, usa ciudad; siempre incluye Presidente si hay país. pct_resolucion y pct_aprobacion vienen de mv_metricas_politico (pueden ser NULL si no se ha refrescado aún).';
