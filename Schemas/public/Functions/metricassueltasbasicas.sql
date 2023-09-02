-- FUNCTION: public.metricassueltasbasicas(text)

-- DROP FUNCTION IF EXISTS public.metricassueltasbasicas(text);

CREATE OR REPLACE FUNCTION public.metricassueltasbasicas(
	user_id_thirdparty_in text)
    RETURNS TABLE(metrica character varying, cantidad bigint) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
	
	SELECT 
	cast('Poderes ganados por regalos' as varchar (500)) as metrica
	,coalesce(sum(PR.cantidad_poderes_regalada),0)::BIGINT as cantidad
	FROM PERSONAS P
	left outer JOIN PODERES_REGALADOS PR
	ON (PR.persona_id=p.persona_id and PR.fecha_regalo >= now() - interval '30 days')
	where p.user_id_thirdparty=user_id_thirdparty_in
	group by 1
	
	UNION ALL

	SELECT 
		subquery.metrica,
		SUM(subquery.cantidad)::BIGINT as cantidad
	FROM
		(
			SELECT 
				cast('Personas que agradecieron mi ayuda' as varchar (500)) as metrica,
				count(cd.calificacion_id) as cantidad
			FROM PERSONAS P
			left outer join DescripcionesAlarmas da
				on (da.persona_id=p.persona_id and FechaDescripcion >= now() - interval '30 days')
			left outer join calificadores_descripcion cd
				on (cd.idDescripcion=da.iddescripcion and cd.calificacion='Positivo')
			where p.user_id_thirdparty=user_id_thirdparty_in
			group by 1

			UNION ALL

			SELECT 
				cast('Personas que agradecieron mi ayuda' as varchar (500)) as metrica,
				count(da.idDescripcion) as cantidad
			from personas p
			left outer join alarmas al
				on (al.persona_id=p.persona_id and fecha_alarma >= now() - interval '30 days')
			left outer join descripcionesalarmas da
				on (da.alarma_id=al.alarma_id and da.veracidadalarma is true)
			where p.user_id_thirdparty=user_id_thirdparty_in
			group by 1
		) as subquery
	GROUP BY subquery.metrica

	UNION ALL

	SELECT 
		subquery.metrica,
		SUM(subquery.cantidad)::BIGINT as cantidad
	FROM
		(
			SELECT 
				cast('Personas que reportaron mi ayuda como negativa o falsa' as varchar (500)) as metrica,
				count(cd.calificacion_id) as cantidad
			FROM PERSONAS P
			left outer join DescripcionesAlarmas da
				on (da.persona_id=p.persona_id and FechaDescripcion >= now() - interval '30 days')
			left outer join calificadores_descripcion cd
				on (cd.idDescripcion=da.iddescripcion and cd.calificacion='Negativo')
			where p.user_id_thirdparty=user_id_thirdparty_in
			group by 1

			UNION ALL

			SELECT 
				cast('Personas que reportaron mi ayuda como negativa o falsa' as varchar (500)) as metrica,
				count(da.idDescripcion) as cantidad
			from personas p
			left outer join alarmas al
				on (al.persona_id=p.persona_id and fecha_alarma >= now() - interval '30 days')
			left outer join descripcionesalarmas da
				on (da.alarma_id=al.alarma_id and da.veracidadalarma is false)
			where p.user_id_thirdparty=user_id_thirdparty_in
			group by 1
		) as subquery
	GROUP BY subquery.metrica

	UNION ALL

	SELECT 
	cast('Cantidad de notificaciones de alarma enviadas de mi parte' as varchar (500)) as metrica,
	count(np.notificacion_id)::BIGINT as cantidad
	FROM PERSONAS P
	left outer join alarmas al
	on (al.persona_id=p.persona_id and fecha_alarma >= now() - interval '30 days')
	left outer join notificaciones_persona np
	on (np.alarma_id=al.alarma_id and p.persona_id<>np.persona_id)
	where p.user_id_thirdparty=user_id_thirdparty_in
	group by 1

	UNION ALL

	SELECT 
	cast('Cantidad real de personas que recibieron mis alarmas' as varchar (500)) as metrica,
	count(distinct np.persona_id)::BIGINT as cantidad
	FROM PERSONAS P
	left outer join alarmas al
	on (al.persona_id=p.persona_id and fecha_alarma >= now() - interval '30 days')
	left outer join notificaciones_persona np
	on (np.alarma_id=al.alarma_id and p.persona_id<>np.persona_id)
	where p.user_id_thirdparty=user_id_thirdparty_in
	group by 1

	UNION ALL

	SELECT 
	cast('Mi radio actual de recepcion y envio de alarmas en metros' as varchar (500)) as metrica,
	coalesce(rasub.radio_mts,ra.radio_mts)::BIGINT as cantidad
	from personas p
	left outer join radio_alarmas ra
	on (p.radio_alarmas_id=ra.radio_alarmas_id)
	left outer join subscripciones s
	on (s.persona_id=p.persona_id and s.radio_alarmas_id is not null and now() between s.fecha_activacion and coalesce(s.fecha_finalizacion,now()))
	left outer join radio_alarmas rasub
	on (s.radio_alarmas_id=rasub.radio_alarmas_id)
	where p.user_id_thirdparty=user_id_thirdparty_in

	UNION ALL

	SELECT 
	cast('Cantidad real de personas en mi radio actual' as varchar (500)) as metrica,
	count(distinct users.persona_id)::BIGINT as cantidad
	from personas p
	left outer join radio_alarmas ra
	on (p.radio_alarmas_id=ra.radio_alarmas_id)
	left outer join subscripciones s
	on (s.persona_id=p.persona_id and s.radio_alarmas_id is not null and now() between s.fecha_activacion and coalesce(s.fecha_finalizacion,now()))
	left outer join radio_alarmas rasub
	on (s.radio_alarmas_id=rasub.radio_alarmas_id)
	left outer join ubicaciones u_user
	on (u_user."Tipo"='P' and u_user.persona_id=p.persona_id)
	left outer join ubicaciones users
	on (users."Tipo"='P' and p.persona_id<>users.persona_id and
	users.latitud 
		BETWEEN u_user.latitud-coalesce(rasub.radio_double,ra.radio_double)
		AND u_user.latitud+coalesce(rasub.radio_double,ra.radio_double)
	AND 
		users.longitud 
		BETWEEN u_user.longitud-coalesce(rasub.radio_double,ra.radio_double)
		AND u_user.longitud+coalesce(rasub.radio_double,ra.radio_double)
	)
	where p.user_id_thirdparty=user_id_thirdparty_in
	group by 1

	UNION ALL

	SELECT 
	cast('Cantidad real de personas en un radio de un kilometro y medio' as varchar (500)) as metrica,
	count(distinct users.persona_id)::BIGINT as cantidad
	from personas p
	left outer join ubicaciones u_user
	on (u_user."Tipo"='P' and u_user.persona_id=p.persona_id)
	left outer join ubicaciones users
	on (users."Tipo"='P' and p.persona_id<>users.persona_id and
	users.latitud 
		BETWEEN u_user.latitud-0.013500
		AND u_user.latitud+0.013500
	AND 
		users.longitud 
		BETWEEN u_user.longitud-0.013500
		AND u_user.longitud+0.013500
	)
	where p.user_id_thirdparty=user_id_thirdparty_in
	group by 1

	UNION ALL

	SELECT 
	cast('Promedio de tiempo en minutos entre lanzamiento de alarma en mi zona y la primera calificacion o descripcion' as varchar (500)) as metrica,
	(EXTRACT(EPOCH FROM AVG(da.fechadescripcion - al.fecha_alarma))/60)::BIGINT as cantidad
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
	group by 1

	UNION ALL

	SELECT 
	cast('Cantidad de alarmas colocadas por mis protegidos' as varchar (500)) as metrica,
	count(distinct al.alarma_id)::BIGINT as cantidad
	FROM personas p
	INNER JOIN subscripciones s
	ON (
		s.persona_id = p.persona_id
		AND (
			s.fecha_activacion <= now() AND coalesce(s.fecha_finalizacion, now()) >= now() - interval '30 days'
		)
	)
	INNER JOIN relacion_protegidos rp
	ON (
		rp.id_rel_protegido = s.id_rel_protegido
		AND (
			rp.fecha_activacion <= now() AND coalesce(rp.fecha_finalizacion, now()) >= now() - interval '30 days'
		)
	)
	INNER JOIN alarmas al
	ON (
		al.persona_id = rp.id_persona_protegida 
		AND al.fecha_alarma BETWEEN 
			GREATEST(rp.fecha_activacion, now() - interval '30 days') 
			AND 
			LEAST(coalesce(rp.fecha_finalizacion, now()), now())
	)
	WHERE p.user_id_thirdparty = user_id_thirdparty_in
	group by 1

	UNION ALL

	SELECT 
	cast('Cantidad de alarmas colocadas en las zonas de vigilancia suscritas' as varchar (500)) as metrica,
	count(distinct al.alarma_id)::BIGINT as cantidad
	FROM personas p
	INNER JOIN subscripciones s
	ON (
		s.persona_id = p.persona_id
		AND (
			s.fecha_activacion <= now() AND coalesce(s.fecha_finalizacion, now()) >= now() - interval '30 days'
		)
	)
	INNER JOIN ubicaciones u
	ON (
		u.ubicacion_id = s.ubicacion_id
		AND u."Tipo"='S'
	)
	INNER JOIN alarmas al
	on
	(
			(u.latitud 
			between al.latitud-0.001800
			and al.latitud+0.001800
		and 
			u.longitud 
			between al.longitud-0.001800
			and al.longitud+0.001800
		and u."Tipo"='S')
			
		AND al.fecha_alarma BETWEEN 
			GREATEST(s.fecha_activacion, now() - interval '30 days') 
			AND 
			LEAST(coalesce(s.fecha_finalizacion, now()), now())
	)
	WHERE p.user_id_thirdparty = user_id_thirdparty_in
	group by 1;

END; 
$BODY$;

ALTER FUNCTION public.metricassueltasbasicas(text)
    OWNER TO w4ll4c3;
