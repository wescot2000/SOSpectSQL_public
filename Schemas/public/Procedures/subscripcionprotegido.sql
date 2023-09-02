-- PROCEDURE: public.subscripcionprotegido(character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.subscripcionprotegido(character varying, character varying);

CREATE OR REPLACE PROCEDURE public.subscripcionprotegido(
	IN p_user_id_thirdparty_protector character varying,
	IN p_user_id_thirdparty_protegido character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	v_tipo_subscr_id INTEGER := 3;
	v_cantidad_subscripcion INTEGER := 1;
	v_cantidad_poderes INTEGER;
	v_tiempo_subscripcion_dias INTEGER;
	v_persona_id_protector BIGINT;
	v_persona_id_protegido BIGINT;
	v_saldo_actual_poderes INTEGER;
	v_id_rel_protegido BIGINT;
	v_permiso_aprobado INTEGER;
	v_login_protector varchar(150);
	v_login_protegido varchar(150);
	v_subscripcion_existente INTEGER;
	v_tiporelacion_id integer;
BEGIN
	BEGIN

		SELECT 
				persona_id,login
			INTO 
				v_persona_id_protector,v_login_protector
		FROM 
			personas
		WHERE
			user_id_thirdparty=p_user_id_thirdparty_protector;

		SELECT 
				persona_id,login
			INTO 
				v_persona_id_protegido,v_login_protegido
		FROM 
			personas
		WHERE
			user_id_thirdparty=p_user_id_thirdparty_protegido;

		SELECT
			tiporelacion_id
		INTO
			v_tiporelacion_id
		FROM 
			permisos_pendientes_protegidos
		WHERE
			persona_id_protector=v_persona_id_protector
		AND 
			persona_id_protegido=v_persona_id_protegido;

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
			count(*)
		INTO 
			v_permiso_aprobado
		FROM 
			permisos_pendientes_protegidos
		WHERE
			persona_id_protegido=v_persona_id_protegido
		and 
			persona_id_protector=v_persona_id_protector
		and 
			flag_aprobado is true
		and 
			fecha_aprobado is not null;

		if 
			v_permiso_aprobado=0 
		then	
			RAISE EXCEPTION 'El usuario no cuenta con aprobacion por parte del protegido para continuar';
		END IF;

		select 
			count(*) 
		into 
			v_subscripcion_existente
		from 
			relacion_protegidos rp
		inner join 
			subscripciones s
		on 
			(
				s.id_rel_protegido=rp.id_rel_protegido and now() between s.fecha_activacion and coalesce(s.fecha_finalizacion,now())
			)
		where 
			rp.id_persona_protector=v_persona_id_protector
		and 
			rp.id_persona_protegida=v_persona_id_protegido
		and 
			now() between rp.fecha_activacion and coalesce(rp.fecha_finalizacion,now());

		if 
			v_subscripcion_existente>0 
		then	
			RAISE EXCEPTION 'No se puede realizar la subscripción solicitada nuevamente porque ya se encuentra activa entre los usuarios requeridos';
		END IF;

		INSERT INTO 
			relacion_protegidos
				(
					tiporelacion_id
					,id_persona_protector
					,id_persona_protegida
					,poderes_consumidos
					,fecha_activacion
					,fecha_finalizacion
				)
			VALUES
				(
					v_tiporelacion_id
					,v_persona_id_protector
					,v_persona_id_protegido
					,v_cantidad_poderes
					,now()
					,now()  + make_interval(days => v_tiempo_subscripcion_dias)
				);
				
			select 
				max(id_rel_protegido)
			INTO
				v_id_rel_protegido
			from 
				relacion_protegidos
			where
				id_persona_protector=v_persona_id_protector
			AND	
				id_persona_protegida=v_persona_id_protegido;



		INSERT INTO
			subscripciones
				(
					persona_id
					,tipo_subscr_id
					,fecha_activacion
					,fecha_finalizacion
					,poderes_consumidos
					,id_rel_protegido
					,cantidad_protegidos_adquirida
				)
			VALUES
				(
					v_persona_id_protector
					,v_tipo_subscr_id
					,now()
					,now()  + make_interval(days => v_tiempo_subscripcion_dias)
					,v_cantidad_poderes
					,v_id_rel_protegido
					,v_cantidad_subscripcion
				);

				UPDATE 
					personas
				SET 
					saldo_poderes=v_saldo_actual_poderes-v_cantidad_poderes
				WHERE 
					persona_id=v_persona_id_protector;

		INSERT INTO 
			mensajes_a_usuarios
				(
					persona_id
					,texto
					,fecha_mensaje
					,estado
					,asunto
					,idioma_origen
				)
			VALUES
				(
					v_persona_id_protector
					,'Ahora sigues las alarmas que coloque el usuario '||v_login_protegido||'. Si estas usando los poderes de regalo, el tiempo de seguimiento es 30 dias. Si usaste poderes comprados el tiempo es el definido en el listado de subscripciones'
					,now()
					,cast(true as boolean)
					,'Ahora sigues las alarmas de '||v_login_protegido||'.'
					,'es'
				);

			INSERT INTO 
			mensajes_a_usuarios
				(
					persona_id
					,texto
					,fecha_mensaje
					,estado
					,asunto
					,idioma_origen
				)
			VALUES
				(
					v_persona_id_protegido
					,'A partir de ahora el usuario '||v_login_protector||' sigue tus alarmas por un tiempo de '||v_tiempo_subscripcion_dias||' días.'
					,now()
					,cast(true as boolean)
					,'Ahora '||v_login_protector||' sigue las alarmas que coloques en SOSpect.'
					,'es'
				);



		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.subscripcionprotegido(character varying, character varying)
    OWNER TO w4ll4c3;
