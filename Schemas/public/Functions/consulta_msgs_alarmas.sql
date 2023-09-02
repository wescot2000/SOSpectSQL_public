-- FUNCTION: public.consulta_msgs_alarmas(character varying, bigint)

-- DROP FUNCTION IF EXISTS public.consulta_msgs_alarmas(character varying, bigint);

CREATE OR REPLACE FUNCTION public.consulta_msgs_alarmas(
	p_user_id_thirdparty character varying,
	p_alarma_id bigint)
    RETURNS TABLE(persona_id bigint, texto character varying, fecha_mensaje timestamp with time zone, estado boolean, asunto character varying, idioma_origen character varying, alarma_id bigint) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

BEGIN
  RETURN QUERY

	select 
	cast(deriv.persona_id as bigint) as persona_id
	,cast('Recibiste recientemente una alerta cerca de ti, puedes verla aquí: ' as varchar(500)) as texto
	,cast(now() as timestamp with time zone) as fecha_mensaje
	,cast(True as boolean) as estado
	,cast('Notificación alerta cercana recibida'  as varchar(500)) as asunto
	,cast('es'  as varchar(10))  as idioma_origen
	,cast(deriv.alarma_id as bigint) as alarma_id
	from (
	select v.persona_id
	,v.alarma_id
	FROM vw_notificacion_alarmas v 
	left outer join mensajes_a_usuarios m
	on (v.persona_id=m.persona_id and v.alarma_id=m.alarma_id)
	WHERE v.user_id_thirdparty = p_user_id_thirdparty
	AND v.user_id_thirdparty=v.user_id_creador_alarma
	and m.mensaje_id is null
	and v.alarma_id=p_alarma_id
	group by v.persona_id, v.alarma_id) as deriv
	union
	select 
	cast(deriv.persona_id as bigint) as persona_id
	,cast('URGENTE: Tu protegido colocó una alerta, puedes verla aquí: ' as varchar(500)) as texto
	,cast(now() as timestamp with time zone) as fecha_mensaje
	,cast(True as boolean) as estado
	,cast('URGENTE: Tu protegido colocó una alerta'  as varchar(500)) as asunto
	,cast('es'  as varchar(10))  as idioma_origen
	,cast(deriv.alarma_id as bigint) as alarma_id
	from (
	select rp.id_persona_protector as persona_id
	,v.alarma_id
	FROM vw_notificacion_alarmas v 
	inner join personas p
	on (p.user_id_thirdparty=v.user_id_creador_alarma)
	inner join relacion_protegidos rp
	on (rp.id_persona_protegida=p.persona_id and now() between fecha_activacion and fecha_finalizacion)
	left outer join mensajes_a_usuarios m
	on (v.persona_id=m.persona_id and v.alarma_id=m.alarma_id)
	left outer join mensajes_a_usuarios m2
	on (rp.id_persona_protector=m2.persona_id and v.alarma_id=m2.alarma_id)
	WHERE v.user_id_creador_alarma = p_user_id_thirdparty
	AND v.user_id_thirdparty<>v.user_id_creador_alarma
	and m.mensaje_id is null
	and m2.mensaje_id is null
	and v.alarma_id=p_alarma_id
	group by rp.id_persona_protector, v.alarma_id) as deriv
	group by 1,2,3,4,5,6,7;
END;
$BODY$;

ALTER FUNCTION public.consulta_msgs_alarmas(character varying, bigint)
    OWNER TO w4ll4c3;
