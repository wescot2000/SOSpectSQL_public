-- FUNCTION: public.fn_listaralarmasrelacionadas(bigint)

-- DROP FUNCTION IF EXISTS public.fn_listaralarmasrelacionadas(bigint);

CREATE OR REPLACE FUNCTION public.fn_listaralarmasrelacionadas(p_alarma_id bigint)
RETURNS TABLE(alarma_id bigint) 
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
-- Unimos los resultados de ancestros y descendientes
SELECT alarma_id FROM AlarmasAncestros 
UNION 
SELECT alarma_id FROM AlarmasDescendientes;
$BODY$;

ALTER FUNCTION public.fn_listaralarmasrelacionadas(bigint)
    OWNER TO w4ll4c3;

