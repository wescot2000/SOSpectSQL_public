-- PROCEDURE: public.asignaralarma(bigint, character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.asignaralarma(bigint, character varying, character varying);

CREATE OR REPLACE PROCEDURE public.asignaralarma(
	IN p_alarma_id bigint,
	IN p_user_id_thirdparty character varying,
	IN p_idioma character varying)
LANGUAGE 'plpgsql'
AS $BODY$



DECLARE 
	v_persona_id BIGINT;
	v_latitud_alarma numeric(9,6);
	v_longitud_alarma numeric(9,6);
	v_latitud_originador numeric(9,6);
	v_longitud_originador numeric(9,6);
	v_distancia_alarma_originador numeric(9,2);
	v_persona_id_creador BIGINT;
	v_tipoalarma_id_actual INTEGER;
	v_estado_alarma VARCHAR(10);
	v_flag_es_policia boolean;
	v_NumeroPlaca VARCHAR(500);
	v_mensajeDescripcion VARCHAR(500);
	v_mensajeUsuario VARCHAR(500);
	v_asuntoUsuario VARCHAR(500);
	v_mensajePolicia VARCHAR(500);
	v_asuntoPolicia VARCHAR(500);
	v_msg_deniedAlarmClosed VARCHAR(500);
	v_msg_deniedOnlyAuthAllowed VARCHAR(500);
	v_msg_deniedAlarmAlreadyAssigned VARCHAR(500);
	v_verificacion_atencion integer;
BEGIN
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
			
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
	
	BEGIN

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

		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	

	END;
END
$BODY$;
ALTER PROCEDURE public.asignaralarma(bigint, character varying, character varying)
    OWNER TO w4ll4c3;
