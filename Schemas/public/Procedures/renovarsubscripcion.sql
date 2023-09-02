-- PROCEDURE: public.renovarsubscripcion(bigint, character varying, integer)

-- DROP PROCEDURE IF EXISTS public.renovarsubscripcion(bigint, character varying, integer);

CREATE OR REPLACE PROCEDURE public.renovarsubscripcion(
	IN p_subscripcion_id bigint,
	IN p_user_id_thirdparty_protector character varying,
	IN p_cantidad_poderes integer)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
	v_persona_id BIGINT;
	v_id_rel_protegido BIGINT;
	v_poderes_usuario INTEGER;
	v_tiempo_subscripcion_dias INTEGER;
BEGIN
	BEGIN

		SELECT 
			persona_id,saldo_poderes
		INTO 
			v_persona_id,v_poderes_usuario
		FROM 
			personas
		WHERE
			user_id_thirdParty=p_user_id_thirdparty_protector;

		SELECT
			id_rel_protegido
		into 
			v_id_rel_protegido
		from 
			subscripciones
		where 
			subscripcion_id=p_subscripcion_id;

		if v_poderes_usuario < p_cantidad_poderes then
			raise exception '%', concat('Cantidad insuficiente de poderes. El saldo del usuario es: ', v_poderes_usuario, ' poderes, y para esta subscripción se requieren: ', p_cantidad_poderes);
		end if;

		SELECT
			((s.poderes_consumidos/vs.cantidad_poderes)*vs.tiempo_subscripcion_horas)/24 as tiempo_subscripcion_dias
		INTO
			v_tiempo_subscripcion_dias
		from 
			subscripciones s
		inner join 
			tiposubscripcion ts
		on 
			(ts.tipo_subscr_id=s.tipo_subscr_id)
		inner join 
			valorsubscripciones vs
		on 
			(
				vs.tipo_subscr_id=ts.tipo_subscr_id
			)
		where
			s.subscripcion_id=p_subscripcion_id;

		if v_id_rel_protegido is not null then
			
			UPDATE
				relacion_protegidos
			SET
			fecha_finalizacion = CASE 
									WHEN fecha_finalizacion IS NULL THEN cast(now() as timestamp with time zone)
									WHEN fecha_finalizacion < cast(now() as timestamp with time zone) THEN cast(now() as timestamp with time zone)
									ELSE fecha_finalizacion
								END + make_interval(days => v_tiempo_subscripcion_dias)
			WHERE
				id_rel_protegido=v_id_rel_protegido;

		end if;

		UPDATE
			subscripciones
		SET
			fecha_finalizacion = CASE 
									WHEN fecha_finalizacion IS NULL THEN cast(now() as timestamp with time zone)
									WHEN fecha_finalizacion < cast(now() as timestamp with time zone) THEN cast(now() as timestamp with time zone)
									ELSE fecha_finalizacion
								END + make_interval(days => v_tiempo_subscripcion_dias)
		WHERE
			subscripcion_id = p_subscripcion_id;

		UPDATE 
			personas
		SET 
			saldo_poderes=v_poderes_usuario-p_cantidad_poderes
		WHERE 
			persona_id=v_persona_id;
			
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.renovarsubscripcion(bigint, character varying, integer)
    OWNER TO w4ll4c3;
