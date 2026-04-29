-- FUNCTION: public.fn_listardescripcionesalarma(bigint, character varying)

-- DROP FUNCTION IF EXISTS public.fn_listardescripcionesalarma(bigint, character varying);

CREATE OR REPLACE FUNCTION public.fn_listardescripcionesalarma(
	p_alarma_id bigint,
	p_user_id_thirdparty character varying)
    RETURNS TABLE(
		iddescripcion bigint,
		alarma_id bigint,
		persona_id bigint,
		descripcionalarma character varying,
		descripcionsospechoso character varying,
		descripcionvehiculo character varying,
		descripcionarmas character varying,
		flageditado boolean,
		fechadescripcion timestamp without time zone,
		propietario_descripcion boolean,
		calificacion_otras_descripciones character varying,
		calificaciondescripcion integer,
		tipoalarma_id integer,
		descripciontipoalarma character varying,
		idioma_origen character varying,
		esalarmaactiva boolean,
		flag_red_confianza boolean,
		fotos_json text,
		categoria_alarma_id integer
	)
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
WITH RECURSIVE AlarmasAncestros AS (
    -- Base case: Empezar con la alarma especificada
    SELECT alarma_id, alarma_id_padre
    FROM alarmas
    WHERE alarma_id = p_alarma_id
    UNION ALL
    -- Caso recursivo: Ancestros (buscando hacia arriba)
    SELECT a.alarma_id, a.alarma_id_padre
    FROM alarmas a
    JOIN AlarmasAncestros aa ON a.alarma_id = aa.alarma_id_padre
),
AlarmasDescendientes AS (
    -- Base case: Empezar con la alarma especificada
    SELECT alarma_id, alarma_id_padre
    FROM alarmas
    WHERE alarma_id = p_alarma_id
    UNION ALL
    -- Caso recursivo: Descendientes (buscando hacia abajo)
    SELECT a.alarma_id, a.alarma_id_padre
    FROM alarmas a
    JOIN AlarmasDescendientes ad ON a.alarma_id_padre = ad.alarma_id
)
SELECT
    da.iddescripcion,
    da.alarma_id,
    da.persona_id,
    descripcionalarma,
    descripcionsospechoso,
    descripcionvehiculo,
    descripcionarmas,
    FlagEditado,
    fechadescripcion,
    CASE WHEN pp.user_id_thirdparty = p_user_id_thirdparty THEN true ELSE false END AS propietario_descripcion,
    coalesce(cd.calificacion, 'Apagado') as calificacion_otras_descripciones,
    coalesce(da.calificaciondescripcion,0) as calificaciondescripcion,
    ta.tipoalarma_id,
    ta.descripciontipoalarma,
    coalesce(da.idioma_origen,'en') as idioma_origen,
    case when al.estado_alarma is null then cast(TRUE AS BOOLEAN) ELSE CAST (FALSE AS BOOLEAN) END AS EsAlarmaActiva,
    coalesce(pp.flag_red_confianza, cast(FALSE as boolean)) as flag_red_confianza,
    -- Nueva columna: array de fotos en formato JSON
    coalesce(
        (SELECT json_agg(
            json_build_object(
                'foto_id', f.foto_id,
                'url_foto', f.url_foto,
                'thumbnail_url', f.thumbnail_url,
                'nombre_archivo_original', f.nombre_archivo_original,
                'tipo_mime', f.tipo_mime,
                'tamano_bytes', f.tamano_bytes,
                'ancho_pixels', f.ancho_pixels,
                'alto_pixels', f.alto_pixels,
                'es_video', f.es_video,
                'orden', f.orden,
                'fecha_subida', f.fecha_subida
            ) ORDER BY f.orden ASC NULLS LAST, f.fecha_subida ASC
        )::text
        FROM fotos_descripciones_alarmas f
        WHERE f.iddescripcion = da.iddescripcion
          AND f.estado = 'A'
        ),
        '[]'::text
    ) as fotos_json,
    ta.categoria_alarma_id
FROM descripcionesalarmas da
-- Unimos los resultados de ancestros y descendientes
INNER JOIN (SELECT alarma_id FROM AlarmasAncestros UNION SELECT alarma_id FROM AlarmasDescendientes) AS AlarmasFinal ON AlarmasFinal.alarma_id = da.alarma_id
INNER JOIN alarmas al ON al.alarma_id = da.alarma_id
INNER JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
LEFT OUTER JOIN calificadores_descripcion cd ON cd.iddescripcion = da.iddescripcion
LEFT OUTER JOIN personas p ON p.persona_id = cd.persona_id
LEFT OUTER JOIN personas pp ON pp.persona_id = da.persona_id
WHERE da.veracidadalarma IS NULL

UNION ALL
-- Fila sintética: se emite SOLO cuando la alarma no tiene descripciones.
-- Garantiza que siempre retorne al menos 1 fila con categoria_alarma_id
-- para que el ViewModel pueda actualizar el botón de autoridades responsables.
SELECT
    0::bigint                        AS iddescripcion,
    p_alarma_id                      AS alarma_id,
    NULL::bigint                     AS persona_id,
    NULL::character varying          AS descripcionalarma,
    NULL::character varying          AS descripcionsospechoso,
    NULL::character varying          AS descripcionvehiculo,
    NULL::character varying          AS descripcionarmas,
    FALSE                            AS flageditado,
    NOW()                            AS fechadescripcion,
    FALSE                            AS propietario_descripcion,
    'Apagado'::character varying     AS calificacion_otras_descripciones,
    0                                AS calificaciondescripcion,
    ta_base.tipoalarma_id::integer,
    ta_base.descripciontipoalarma,
    'es'::character varying          AS idioma_origen,
    CASE WHEN al_base.estado_alarma IS NULL THEN TRUE ELSE FALSE END AS esalarmaactiva,
    FALSE                            AS flag_red_confianza,
    '[]'::text                       AS fotos_json,
    ta_base.categoria_alarma_id
FROM alarmas al_base
INNER JOIN tipoalarma ta_base ON ta_base.tipoalarma_id = al_base.tipoalarma_id
WHERE al_base.alarma_id = p_alarma_id
  AND NOT EXISTS (
      SELECT 1
      FROM descripcionesalarmas da_check
      INNER JOIN (SELECT alarma_id FROM AlarmasAncestros
                  UNION
                  SELECT alarma_id FROM AlarmasDescendientes) AS AlarmasFinal_check
          ON AlarmasFinal_check.alarma_id = da_check.alarma_id
      WHERE da_check.veracidadalarma IS NULL
  );
$BODY$;
