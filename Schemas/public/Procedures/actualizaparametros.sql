-- PROCEDURE: public.actualizaparametros(character varying, character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.actualizaparametros(character varying, character varying, character varying);

CREATE OR REPLACE PROCEDURE public.actualizaparametros(
	IN p_user_id_thirdparty character varying,
	IN p_registrationid character varying,
	IN p_idioma character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	v_persona_id BIGINT;
	v_registrationidexistente INTEGER;
	v_mensaje_para_usuario  VARCHAR(500);
	v_mensaje_para_usuario2  VARCHAR(500);
	v_mensaje_id bigint;
	v_mensaje_id2 bigint;
BEGIN
	BEGIN
		SELECT 
				persona_id
			INTO 
				v_persona_id
		FROM 
			personas
		WHERE
			user_id_thirdparty=p_user_id_thirdparty;
			
		select 
			count(*) as cantidad
		INTO
			v_registrationidexistente
		FROM
			dispositivos
		where
			persona_id=v_persona_id
			and registrationid=p_registrationid
			and fecha_fin is null;

		select 
			case 
				when p.marca_bloqueo between 1 and 5 and p.fecha_ultima_marca_bloqueo>now()-interval '1' day 
				then cast('Advertencia: calificaste como falsa una alarma cercana a ti que resulto ser verdadera tras una hora de votaciones. Tu marca de bloqueo se incrementa en 1. Tu cuenta se bloqueara 2 meses cuando llegues a 6 marcas por incorrecto uso' as varchar(500)) 
				when p.marca_bloqueo = 6 and p.fecha_ultima_marca_bloqueo>now()-interval '1' day 
				then cast('Alerta: calificaste como falsa una alarma cercana a ti que resulto ser verdadera tras una hora de votaciones. Es la marca 6, tu cuenta se bloquea hasta la fecha: '|| p.fecha_ultima_marca_bloqueo+interval '60' ||'.' as varchar(500)) 
				when p.marca_bloqueo between 7 and 8 and p.fecha_ultima_marca_bloqueo>now()-interval '1' day 
				then cast('Advertencia: calificaste como falsa una alarma cercana a ti que resulto ser verdadera tras una hora de votaciones. Tu marca de bloqueo se incrementa en 1. Tu cuenta se bloqueara 6 meses con 8 marcas por incorrecto uso' as varchar(500)) 
				when p.marca_bloqueo = 9 and p.fecha_ultima_marca_bloqueo>now()-interval '1' day 
				then cast('Alerta: calificaste como falsa una alarma cercana a ti que resulto ser verdadera tras una hora de votaciones. Es la marca 9, tu cuenta se bloqueara hasta la fecha: '|| p.fecha_ultima_marca_bloqueo+interval '180' ||'.' as varchar(500)) 
				when p.marca_bloqueo = 10 and p.fecha_ultima_marca_bloqueo>now()-interval '1' day 
				then cast('Alerta: calificaste como falsa una alarma cercana a ti que resulto ser verdadera tras una hora de votaciones. Es la marca 10, tu cuenta se suspende definitivamente.' as varchar(500)) 
				end as MensajeParaUsuario
		INTO
			v_mensaje_para_usuario
		from 
				personas p
		where p.persona_id=v_persona_id;


		select 
			case 
				when al.alarma_id is not null  and al.calificacion_alarma<50
				then cast('Notificación: colocaste alarmas recientemente cuya votacion indica que era una falsa alarma. La credibilidad de tus futuras alarmas se ha reducido.' as varchar(500)) 
				when al.alarma_id is not null  and al.calificacion_alarma>=50
				then cast('Notificación: colocaste alarmas recientemente cuya votacion indica que era una alarma verdadera. La credibilidad de tus futuras alarmas se ha incrementado.' as varchar(500)) 
				end as MensajeParaUsuario
		INTO
			v_mensaje_para_usuario2
		from 
				personas p
		inner join 
				alarmas al
		on
			(
				al.persona_id=p.persona_id 
			and al.estado_alarma is not null 
			and al.calificacion_alarma is not null 		
			and fecha_alarma>now()-interval '1' day
			)
		where p.persona_id=v_persona_id
		and 
			(
				SELECT COUNT(*) 
				FROM descripcionesalarmas da
				WHERE da.alarma_id = al.alarma_id 
				AND da.veracidadalarma IS NOT NULL
			) > 2;
		
		select 
			mensaje_id
		INTO
			v_mensaje_id
		from 
			mensajes_a_usuarios
		where 
			persona_id=v_persona_id
		and
			texto=v_mensaje_para_usuario
		and 
			fecha_mensaje>now()-interval '15' day;

		select 
			mensaje_id
		INTO
			v_mensaje_id2
		from 
			mensajes_a_usuarios
		where 
			persona_id=v_persona_id
		and
			texto=v_mensaje_para_usuario2
		and 
			fecha_mensaje>now()-interval '15' day;
						
		UPDATE 
			dispositivos
		SET	
			idioma=p_idioma
		WHERE 
			persona_id=v_persona_id
		AND
			registrationid=p_registrationid
		AND	
			fecha_fin is null;

		
		IF v_mensaje_para_usuario is not null and v_mensaje_id is null THEN
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
					v_persona_id
					,v_mensaje_para_usuario
					,now()
					,cast(True as boolean)
					,'Recibiste marca negativa que puede bloquear tu usuario'
					,'es'
				);
		end if;

		IF v_mensaje_para_usuario2 is not null and v_mensaje_id2 is null THEN
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
					v_persona_id
					,v_mensaje_para_usuario2
					,now()
					,cast(True as boolean)
					,'La credibilidad de tus futuras alarmas ha sido modificada'
					,'es'
				);
		end if;

		
		
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.actualizaparametros(character varying, character varying, character varying)
    OWNER TO w4ll4c3;
