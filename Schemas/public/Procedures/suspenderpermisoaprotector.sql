-- PROCEDURE: public.suspenderpermisoaprotector(character varying, integer)

-- DROP PROCEDURE IF EXISTS public.suspenderpermisoaprotector(character varying, integer);

CREATE OR REPLACE PROCEDURE public.suspenderpermisoaprotector(
	IN p_user_id_thirdparty_protegido character varying,
	IN p_tiempo_suspension integer)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
    
	v_persona_id_protegido BIGINT;
	v_suspensiones_aplicadas INTEGER;
	v_subscripciones_activas INTEGER;

BEGIN
    SELECT 
            persona_id
        INTO 
            v_persona_id_protegido
    FROM 
        personas
    WHERE
        user_id_thirdparty=p_user_id_thirdparty_protegido;

	select 
		count(*) 
	into 
		v_subscripciones_activas
	from 
		subscripciones s
	inner join 
		relacion_protegidos rp
	on 
		(
			s.id_rel_protegido=rp.id_rel_protegido and cast(now() as timestamp with time zone) between s.fecha_activacion and s.fecha_finalizacion
		)
	where 
		rp.id_persona_protegida=v_persona_id_protegido;

	IF v_subscripciones_activas = 0 then
			RAISE EXCEPTION 'No existen subscripciones activas de protector-protegido. No se puede aplicar suspensión por esa razón. Comunícate con la persona que seguía tus alarmas para renovar esa subscripción';	
	END IF;	

	SELECT 
		count(*) 
	into 
		v_suspensiones_aplicadas
	FROM 
		relacion_protegidos RP
	where 
		cast(now() as timestamp with time zone) between fecha_suspension and fecha_reactivacion
	and 
		rp.id_persona_protegida=v_persona_id_protegido;

	
    IF v_suspensiones_aplicadas > 0 then
			RAISE EXCEPTION 'Ya hay un tiempo de suspensión aplicado para evitar enviar notificaciones a los protectores de tu cuenta. No se puede aplicar uno nuevo hasta finalizar la suspensión actual';	
	END IF;	

	update
        relacion_protegidos
    set
        fecha_suspension=cast(now() as timestamp with time zone)
		,fecha_reactivacion=cast(now() as timestamp with time zone)  + make_interval(hours => p_tiempo_suspension)
    where
        id_persona_protegida=v_persona_id_protegido
	and 
		cast(now() as timestamp with time zone) between fecha_activacion and fecha_finalizacion;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION '%', sqlerrm;
END;
$BODY$;
ALTER PROCEDURE public.suspenderpermisoaprotector(character varying, integer)
    OWNER TO w4ll4c3;
