-- FUNCTION: public.fn_listardescripcionesalarma(bigint, character varying)

-- DROP FUNCTION IF EXISTS public.fn_listardescripcionesalarma(bigint, character varying);

CREATE OR REPLACE FUNCTION public.fn_listardescripcionesalarma(
	p_alarma_id bigint,
	p_user_id_thirdparty character varying)
    RETURNS TABLE(iddescripcion bigint, alarma_id bigint, persona_id bigint, descripcionalarma character varying, descripcionsospechoso character varying, descripcionvehiculo character varying, descripcionarmas character varying, flageditado boolean, fechadescripcion timestamp without time zone, propietario_descripcion boolean, calificacion_otras_descripciones character varying, calificaciondescripcion integer, tipoalarma_id integer, descripciontipoalarma character varying, idioma_origen character varying, esalarmaactiva boolean) 
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
    case when al.estado_alarma is null then cast(TRUE AS BOOLEAN) ELSE CAST (FALSE AS BOOLEAN) END AS EsAlarmaActiva
FROM descripcionesalarmas da
-- Unimos los resultados de ancestros y descendientes
INNER JOIN (SELECT alarma_id FROM AlarmasAncestros UNION SELECT alarma_id FROM AlarmasDescendientes) AS AlarmasFinal ON AlarmasFinal.alarma_id = da.alarma_id
INNER JOIN alarmas al ON al.alarma_id = da.alarma_id
INNER JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
LEFT OUTER JOIN calificadores_descripcion cd ON cd.iddescripcion = da.iddescripcion
LEFT OUTER JOIN personas p ON p.persona_id = cd.persona_id
LEFT OUTER JOIN personas pp ON pp.persona_id = da.persona_id
WHERE da.veracidadalarma IS NULL;
$BODY$;

ALTER FUNCTION public.fn_listardescripcionesalarma(bigint, character varying)
    OWNER TO w4ll4c3;
