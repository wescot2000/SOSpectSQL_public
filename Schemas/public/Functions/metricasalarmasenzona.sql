-- FUNCTION: public.metricasalarmasenzona(text)

-- DROP FUNCTION IF EXISTS public.metricasalarmasenzona(text);

CREATE OR REPLACE FUNCTION public.metricasalarmasenzona(
	user_id_thirdparty_in text)
    RETURNS TABLE(metrica character varying, total_alarmas bigint, alarmas_ciertas bigint, alarmas_falsas bigint, porcentaje_ciertas numeric) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

BEGIN
    RETURN QUERY

	SELECT 
		cast('Porcentaje de alarmas ciertas frente a falsas en un radio de un kilometro y medio' as varchar (500)) as metrica,
		COUNT(distinct al.alarma_id) as total_alarmas,
		COUNT(distinct (CASE WHEN al.calificacion_alarma  >= 50 THEN al.alarma_id END)) as alarmas_ciertas,
		COUNT(distinct(CASE WHEN al.calificacion_alarma < 50 THEN al.alarma_id END)) as alarmas_falsas,
		(COUNT(distinct (CASE WHEN al.calificacion_alarma  >= 50 THEN al.alarma_id END))::decimal / NULLIF(COUNT(distinct al.alarma_id), 0) * 1)::numeric as porcentaje_ciertas
	FROM alarmas al
	INNER JOIN descripcionesalarmas da
	ON (da.alarma_id=al.alarma_id)
	inner join ubicaciones u
	on (u."Tipo"='P')
	inner join personas p
	on (p.persona_id=u.persona_id)
	inner join (
		SELECT latitud, longitud
		FROM ubicaciones u_user
		WHERE u_user."Tipo" = 'P' 
		AND u_user.persona_id = (
			SELECT persona_id 
			FROM personas 
			WHERE user_id_thirdparty=user_id_thirdparty_in
		)
	) as user_location
	on (
		u.latitud 
		BETWEEN user_location.latitud-0.013500
		AND user_location.latitud+0.013500
		AND 
		u.longitud 
		BETWEEN user_location.longitud-0.013500
		AND user_location.longitud+0.013500
	)
	where al.fecha_alarma >= now() - interval '30 days'
	GROUP BY 1;

END; 
$BODY$;

ALTER FUNCTION public.metricasalarmasenzona(text)
    OWNER TO w4ll4c3;
