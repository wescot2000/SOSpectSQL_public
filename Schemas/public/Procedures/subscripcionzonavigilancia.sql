-- PROCEDURE: public.subscripcionzonavigilancia(character varying, numeric, numeric)

-- DROP PROCEDURE IF EXISTS public.subscripcionzonavigilancia(character varying, numeric, numeric);

CREATE OR REPLACE PROCEDURE public.subscripcionzonavigilancia(
	IN p_user_id_thirdparty_protector character varying,
	IN p_latitud_zona numeric,
	IN p_longitud_zona numeric)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	v_tipo_subscr_id INTEGER := 1;
	v_cantidad_subscripcion INTEGER := 1;
	v_cantidad_poderes INTEGER;
	v_tiempo_subscripcion_dias INTEGER;
	v_persona_id_protector BIGINT;
	v_saldo_actual_poderes INTEGER;
	v_ubicacion_id BIGINT;
	v_zona_cercana_suscrita INTEGER;
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
			cantidad_poderes
			,tiempo_subscripcion_horas/24 as tiempo_subscripcion_dias
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
			COUNT(*) 
		into 
			v_zona_cercana_suscrita
		FROM 
			subscripciones su
		left outer join 
			ubicaciones u
		on 
			(
				u.ubicacion_id=su.ubicacion_id and u."Tipo"='S'
			)
		where 
			ceiling(ABS((((p_Latitud_zona-u.latitud)+(p_Longitud_zona-u.longitud)*100)/0.000900)))<200
		and 
			now() between su.fecha_activacion and coalesce(su.fecha_finalizacion,now())
		and 
			su.persona_id=v_persona_id_protector;

		if 
			v_zona_cercana_suscrita>0 
		then	
			RAISE EXCEPTION 'No puede subscribir la zona porque el usuario ya tiene una zona suscrita activa a menos de 200 mts, puede eliminar la zona activa en menu > mis subscripciones';
		END IF;

		


		insert into 
			ubicaciones
				(
					persona_id
					,latitud
					,longitud
					,"Tipo"
				)
			VALUES
				(
					v_persona_id_protector
					,p_Latitud_zona
					,p_Longitud_zona
					,'S'
				);


		SELECT
			max(ubicacion_id) as ubicacion_id
		into 
			v_ubicacion_id
		from 
			ubicaciones
		where 
			persona_id=v_persona_id_protector
		and 
			"Tipo"='S';




		INSERT INTO
			subscripciones
				(
					ubicacion_id
					,persona_id
					,tipo_subscr_id
					,fecha_activacion
					,fecha_finalizacion
					,poderes_consumidos
				)
			VALUES
				(
					v_ubicacion_id
					,v_persona_id_protector
					,v_tipo_subscr_id
					,now()
					,now()  + make_interval(days => v_tiempo_subscripcion_dias)
					,v_cantidad_poderes
				);

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
ALTER PROCEDURE public.subscripcionzonavigilancia(character varying, numeric, numeric)
    OWNER TO w4ll4c3;
