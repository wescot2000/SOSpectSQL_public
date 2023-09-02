-- PROCEDURE: public.subscripcionradioalarmas(character varying, integer)

-- DROP PROCEDURE IF EXISTS public.subscripcionradioalarmas(character varying, integer);

CREATE OR REPLACE PROCEDURE public.subscripcionradioalarmas(
	IN p_user_id_thirdparty_protector character varying,
	IN p_cantidad_subscripcion integer)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	v_tipo_subscr_id INTEGER := 2;
	v_cantidad_poderes INTEGER;
	v_tiempo_subscripcion_dias INTEGER;
	v_persona_id_protector BIGINT;
	v_saldo_actual_poderes INTEGER;
	v_radio_alarmas_id INTEGER;
	v_radio_actual_mts INTEGER;
	v_subscripcion_id BIGINT;
	v_poderes_usados INTEGER;
	v_multiplicador INTEGER;
BEGIN
	BEGIN

		SELECT 
				persona_id
			INTO 
				v_persona_id_protector
		FROM 
			personas
		WHERE
			user_id_thirdparty=p_user_id_thirdparty_protector;

		select 
			saldo_poderes
		INTO
			v_saldo_actual_poderes
		from
			personas
		WHERE
			persona_id=v_persona_id_protector;

		select 
			count(*) 
		into 
			v_multiplicador
		FROM 	
			obtener_radio_alarmas (p_user_id_thirdparty_protector) 
		where 
			radio_mts between 0 and p_cantidad_subscripcion; 

		select 
			cantidad_poderes*v_multiplicador
			,(tiempo_subscripcion_horas/24)*v_multiplicador as tiempo_subscripcion_dias
		into
			v_cantidad_poderes
			,v_tiempo_subscripcion_dias
		from 
			public.valorsubscripciones v
		inner 
			join public.tiposubscripcion t
		on (
				t.tipo_subscr_id=v.tipo_subscr_id
			)
		where 
			t.tipo_subscr_id=v_tipo_subscr_id
		order by 
			t.descripcion_tipo;
		
		if 
			v_saldo_actual_poderes=0 or v_cantidad_poderes>v_saldo_actual_poderes
		then	
			RAISE EXCEPTION 'El usuario no cuenta con los poderes suficientes, debe comprar poderes para continuar';
		END IF;
		
		SELECT 
			subscripcion_id,poderes_consumidos
		INTO
			v_subscripcion_id,v_poderes_usados
		FROM 
			subscripciones
		WHERE
			persona_id=v_persona_id_protector
		AND
			tipo_subscr_id=v_tipo_subscr_id
		AND
			now() between fecha_activacion and coalesce(fecha_finalizacion,now());


		select 
			coalesce(asub.radio_mts,a.radio_mts) radio
		into
			v_radio_actual_mts
		from 
			personas p
		inner join 
			radio_alarmas a
		on 
			(
				a.radio_alarmas_id=p.radio_alarmas_id
			)
		left outer join 
			subscripciones s
		on 
			(
				s.persona_id=p.persona_id 
				and now() between s.fecha_activacion 
				and coalesce(s.fecha_finalizacion,now())
				and s.tipo_subscr_id=v_tipo_subscr_id
				)
		left outer join 
			radio_alarmas asub
		on 
			(
				asub.radio_alarmas_id=s.radio_alarmas_id
			)
		WHERE 
			p.persona_id=v_persona_id_protector;

		
		SELECT
			radio_alarmas_id
		into 
			v_radio_alarmas_id
		from 
			radio_alarmas
		WHERE
			radio_mts=p_cantidad_subscripcion;
		
		if v_radio_alarmas_id is NULL 
		then	
			RAISE EXCEPTION 'El nuevo diametro solicitado no esta disponible, reportar este caso a soporte';
		END IF;

		

		if v_subscripcion_id is null 
		then

			INSERT INTO
				subscripciones
					(
						persona_id
						,radio_alarmas_id
						,tipo_subscr_id
						,fecha_activacion
						,fecha_finalizacion
						,poderes_consumidos
					)
				VALUES
					(
						v_persona_id_protector
						,v_radio_alarmas_id
						,v_tipo_subscr_id
						,now()
						,now()  + make_interval(days => v_tiempo_subscripcion_dias)
						,v_cantidad_poderes
					);
			
			ELSE

				UPDATE
					subscripciones
				set 
					radio_alarmas_id = v_radio_alarmas_id,
					fecha_finalizacion = fecha_finalizacion  + make_interval(days => v_tiempo_subscripcion_dias),
					poderes_consumidos=v_poderes_usados+v_cantidad_poderes
				where 
					subscripcion_id=v_subscripcion_id;


			end if;

			UPDATE 
				personas
			SET 
				saldo_poderes=v_saldo_actual_poderes-v_cantidad_poderes
			WHERE 
				persona_id=v_persona_id_protector;


		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.subscripcionradioalarmas(character varying, integer)
    OWNER TO w4ll4c3;
