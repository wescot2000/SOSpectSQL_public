-- FUNCTION: public.fn_asignaralarma(bigint, character varying, character varying)

-- DROP FUNCTION IF EXISTS public.fn_asignaralarma(bigint, character varying, character varying);

CREATE OR REPLACE FUNCTION public.fn_asignaralarma(
	p_alarma_id bigint,
	p_user_id_thirdparty VARCHAR(150),
	p_idioma VARCHAR(10))
    RETURNS TABLE(v_user_id_thirdparty_creador_out VARCHAR(150), alarma_id_out bigint, txt_notif VARCHAR(450), idioma_destino VARCHAR(10)) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$


DECLARE 
	v_persona_id BIGINT;
	v_latitud_alarma numeric(9,6);
	v_longitud_alarma numeric(9,6);
	v_latitud_originador numeric(9,6);
	v_longitud_originador numeric(9,6);
	v_distancia_alarma_originador numeric(9,2);
	v_persona_id_creador BIGINT;
    v_user_id_thirdparty_creador VARCHAR(150);
	v_tipoalarma_id_actual INTEGER;
	v_estado_alarma VARCHAR(10);
	v_flag_es_policia boolean;
	v_NumeroPlaca VARCHAR(450);
	v_mensajeDescripcion VARCHAR(450);
	v_mensajeUsuario VARCHAR(450);
	v_asuntoUsuario VARCHAR(450);
	v_mensajePolicia VARCHAR(450);
	v_asuntoPolicia VARCHAR(450);
	v_msg_deniedAlarmClosed VARCHAR(450);
	v_msg_deniedOnlyAuthAllowed VARCHAR(450);
	v_msg_deniedAlarmAlreadyAssigned VARCHAR(450);
	v_verificacion_atencion integer;
    v_mensajeNotificacion VARCHAR(450);
    v_idioma_creador_alarma VARCHAR(10);

BEGIN

	select 
			al.latitud,
			al.longitud,
			al.tipoalarma_id,
			al.persona_id,
			al.estado_alarma
		INTO
			v_latitud_alarma,
			v_longitud_alarma,
			v_tipoalarma_id_actual,
			v_persona_id_creador,
			v_estado_alarma
		FROM
			alarmas al
		where 
			al.alarma_id=p_alarma_id;

		v_msg_deniedAlarmClosed := obtener_traduccion('msg_deniedAlarmClosed', p_idioma);

		IF v_estado_alarma = 'C' THEN
			RAISE EXCEPTION '%', v_msg_deniedAlarmClosed;
		END IF;

		SELECT 
			p.persona_id
			,u.latitud
			,u.longitud
			,ceiling(ABS((((v_latitud_alarma-u.latitud)+(v_longitud_alarma-u.longitud)*100)/0.000900))) as distancia_en_metros
			,p.flag_es_policia
			,p.numeroplaca
		INTO 
			v_persona_id
			,v_latitud_originador
			,v_longitud_originador
			,v_distancia_alarma_originador
			,v_flag_es_policia
			,v_NumeroPlaca
		FROM 
			personas p
		left outer join 
			ubicaciones u
		on
			(
				p.persona_id=u.persona_id
				and u."Tipo"='P'
			)
		WHERE 
			user_id_thirdparty=p_user_id_thirdparty;

		v_msg_deniedOnlyAuthAllowed := obtener_traduccion('msg_deniedOnlyAuthAllowed', p_idioma);

		IF v_flag_es_policia is false then
			RAISE EXCEPTION '%', v_msg_deniedOnlyAuthAllowed;
		END IF;

        select
            p.user_id_thirdparty
            ,d.idioma
        into 
            v_user_id_thirdparty_creador
            ,v_idioma_creador_alarma
        from 
            personas p
        inner join 
            dispositivos d
        on 
            (d.persona_id=p.persona_id and d.fecha_fin is null)
        where
            p.persona_id= v_persona_id_creador;


		select 
			count(*)
		into 
			v_verificacion_atencion
		from 
			public.atencion_policiaca ap
		where 
			ap.alarma_id in (SELECT alarma_id FROM public.fn_listaralarmasrelacionadas(p_alarma_id))
		and 
			ap.persona_id = v_persona_id;

		v_msg_deniedAlarmAlreadyAssigned := obtener_traduccion('msg_deniedAlarmAlreadyAssigned', p_idioma);

		IF v_verificacion_atencion > 0 then
			RAISE EXCEPTION '%', v_msg_deniedAlarmAlreadyAssigned;
		END IF;

		v_mensajeDescripcion := obtener_traduccion('msg_description', p_idioma);
		v_mensajeDescripcion := REPLACE(v_mensajeDescripcion, '{distance}', v_distancia_alarma_originador::text);
		v_mensajeUsuario := obtener_traduccion('msg_user', p_idioma);
		v_mensajeUsuario := REPLACE(v_mensajeUsuario, '{id}', coalesce(v_NumeroPlaca,'Undefined'));
		v_mensajePolicia := obtener_traduccion('msg_police', p_idioma);
		v_mensajePolicia := REPLACE(v_mensajePolicia, '{id}', coalesce(v_NumeroPlaca,'Undefined'));
		v_asuntoUsuario := obtener_traduccion('subject_user', p_idioma);
		v_asuntoPolicia := obtener_traduccion('subject_police', p_idioma);
		v_asuntoPolicia := REPLACE(v_asuntoPolicia, '{alarm_id}', cast(p_alarma_id as varchar(100)));
        v_mensajeNotificacion := obtener_traduccion('v_mensajeNotificacion', p_idioma);
		v_mensajeNotificacion := REPLACE(v_mensajeNotificacion, '{p_alarma_id}', p_alarma_id::text);


		INSERT INTO 
			descripcionesalarmas 
				(
					persona_id
					,alarma_id
					,DescripcionAlarma
					,fechadescripcion
					,latitud_originador
					,longitud_originador
					,distancia_alarma_originador
					,idioma_origen
				)
		VALUES
			(
				v_persona_id
				,p_alarma_id
				,v_mensajeDescripcion
				,now()
				,v_latitud_originador
				,v_longitud_originador
				,v_distancia_alarma_originador
				,p_idioma
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
				v_persona_id_creador
				,v_mensajeUsuario
				,now()
				,cast(true as boolean)
				,v_asuntoUsuario
				,p_idioma
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
				,alarma_id
			)
		VALUES
			(
				v_persona_id
				,v_mensajePolicia
				,now()
				,cast(true as boolean)
				,v_asuntoPolicia
				,p_idioma
				,p_alarma_id
			);
    
    WITH CTE_Descripciones AS (
			SELECT alarma_id
			FROM public.fn_listaralarmasrelacionadas(p_alarma_id)
		)
		, CTE_Result AS (
			SELECT alarma_id
			FROM CTE_Descripciones
			UNION ALL
			SELECT p_alarma_id
			WHERE NOT EXISTS (SELECT 1 FROM CTE_Descripciones)
		)

		INSERT INTO atencion_policiaca (alarma_id, persona_id, fecha_autoasignacion)
		SELECT alarma_id, v_persona_id, now()
		FROM CTE_Result;

	RETURN QUERY 
	SELECT DISTINCT v_user_id_thirdparty_creador, p_alarma_id, v_mensajeNotificacion,v_idioma_creador_alarma;

EXCEPTION
	WHEN OTHERS THEN
		-- Devuelve un valor nulo y el error. 
		-- Puedes modificar esto según lo que desees hacer en caso de excepción.
		RETURN QUERY SELECT 'Error'::VARCHAR(150), -1::BIGINT, sqlerrm::VARCHAR(450), 'Error'::VARCHAR(10);

END;
$BODY$;

ALTER FUNCTION public.fn_asignaralarma(bigint, character varying, character varying)
    OWNER TO w4ll4c3;
