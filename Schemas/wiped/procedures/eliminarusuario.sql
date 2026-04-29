-- PROCEDURE: wiped.eliminarusuario(character varying)

-- DROP PROCEDURE IF EXISTS wiped.eliminarusuario(character varying);

CREATE OR REPLACE PROCEDURE wiped.eliminarusuario(
	IN p_user_id_thirdparty character varying)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
	p_persona_id BIGINT;

BEGIN
	BEGIN
		SELECT 
				persona_id
			INTO 
				p_persona_id
		FROM 
			public.personas
		WHERE
			user_id_thirdparty=p_user_id_thirdparty;

		/*SACAR COPIA TEMPORAL DE DATOS WIPED POR SI SURGEN RECLAMACIONES TRAS EL BORRADO DE DATOS QUE HAGA EL USUARIO*/

		insert into wiped.calificadores_descripcion
		select * from public.calificadores_descripcion	
		where iddescripcion in (select iddescripcion from public.descripcionesalarmas where persona_id=p_persona_id);

		insert into wiped.calificadores_descripcion
		select * from public.calificadores_descripcion	
		where iddescripcion in (select iddescripcion from public.descripcionesalarmas where alarma_id in (select alarma_id from public.alarmas where persona_id=p_persona_id));

		insert into wiped.calificadores_descripcion
		select *  from public.calificadores_descripcion	
		where persona_id =p_persona_id;

		insert into wiped.dispositivos
		select * from public.dispositivos
		where persona_id=p_persona_id;

		insert into wiped.ubicaciones
		select * from public.ubicaciones
		where persona_id=p_persona_id;

		insert into wiped.ubicaciones_testing
		select * from public.ubicaciones_testing
		where persona_id=p_persona_id;

		insert into wiped.descripcionesalarmas
		select * from public.descripcionesalarmas
		where persona_id=p_persona_id;
		
		insert into wiped.notificaciones_persona
		select * from public.notificaciones_persona
		where alarma_id in (select alarma_id from public.alarmas where persona_id=p_persona_id);

		insert into wiped.descripcionesalarmas
		select * from public.descripcionesalarmas
		where alarma_id in (select alarma_id from public.alarmas where persona_id=p_persona_id);

		insert into wiped.mensajes_a_usuarios
		select * from public.mensajes_a_usuarios
		where persona_id=p_persona_id;

		insert into wiped.mensajes_a_usuarios
		select * from public.mensajes_a_usuarios
		where alarma_id in (select alarma_id from public.alarmas where persona_id=p_persona_id);

		insert into wiped.atencion_policiaca
		select * from public.atencion_policiaca
		where alarma_id in (select alarma_id from public.alarmas where persona_id=p_persona_id);

		insert into wiped.atencion_policiaca
		select * from public.atencion_policiaca
		where persona_id =p_persona_id;

		insert into wiped.alarmas
		select * from public.alarmas
		where persona_id=p_persona_id;

		insert into wiped.subscripciones
		select *  from public.subscripciones
		where id_rel_protegido in (select id_rel_protegido from public.relacion_protegidos where id_persona_protector=p_persona_id);

		insert into wiped.subscripciones
		select * from public.subscripciones
		where id_rel_protegido in (select id_rel_protegido from public.relacion_protegidos where id_persona_protegida=p_persona_id);

		insert into wiped.relacion_protegidos
		select * from public.relacion_protegidos
		where id_persona_protector=p_persona_id;

		insert into wiped.relacion_protegidos
		select *  from public.relacion_protegidos
		where id_persona_protegida=p_persona_id;

		insert into wiped.subscripciones
		select * from public.subscripciones
		where persona_id=p_persona_id;

		insert into wiped.transacciones_personas
		select * from public.transacciones_personas
		where persona_id=p_persona_id;

		insert into wiped.aceptacion_condiciones
		select * from public.aceptacion_condiciones
		where persona_id=p_persona_id;

		insert into wiped.permisos_pendientes_protegidos
		select * from public.permisos_pendientes_protegidos
		where persona_id_protector=p_persona_id;

		insert into wiped.permisos_pendientes_protegidos
		select * from public.permisos_pendientes_protegidos
		where persona_id_protegido=p_persona_id;

		insert into wiped.notificaciones_persona
		select * from public.notificaciones_persona
		where persona_id=p_persona_id;

		insert into wiped.poderes_regalados
		select * from public.poderes_regalados
		where persona_id=p_persona_id;

		-- Backup de chats publicitarios (agregado 16-02-2026)
		insert into wiped.chat_publicidad
		select * from public.chat_publicidad
		where proveedor_persona_id=p_persona_id;

		insert into wiped.chat_publicidad
		select * from public.chat_publicidad
		where interesado_persona_id=p_persona_id
		and chat_id not in (select chat_id from wiped.chat_publicidad);

		-- Backup de mensajes de chat publicitarios (agregado 16-02-2026)
		insert into wiped.mensajes_chat_publicidad
		select * from public.mensajes_chat_publicidad
		where chat_id in (select chat_id from wiped.chat_publicidad);

		INSERT INTO wiped.personas (
			persona_id,
			radio_alarmas_id,
			login,
			user_id_thirdparty,
			fechacreacion,
			marca_bloqueo,
			credibilidad_persona,
			fecha_ultima_marca_bloqueo,
			tiempo_refresco_mapa,
			saldo_poderes,
			flag_es_policia,
			numeroplaca,
			dependenciaasignada,
			ciudad,
			pais,
			flag_es_admin,
			remitentecambio,
			fechacorreosolicitud,
			asuntocorreosolicitud,
			fechaaplicacionsolicitud,
			notif_alarma_cercana_habilitada,
			notif_alarma_protegido_habilitada,
			notif_alarma_zona_vigilancia_habilitada,
			notif_alarma_policia_habilitada,
			fecha_act_configuracion_notif,
			dias_notif_policia_apagada,
			nombres,
			apellidos,
			numero_movil,
			email,
			persona_lider_redconf_id,
			national_id,
			flag_red_confianza,
			fecha_red_confianza,
			limite_alarmas_feed,
			intervalo_background_minutos
		)
		SELECT
			persona_id,
			radio_alarmas_id,
			login,
			user_id_thirdparty,
			fechacreacion,
			marca_bloqueo,
			credibilidad_persona,
			fecha_ultima_marca_bloqueo,
			tiempo_refresco_mapa,
			saldo_poderes,
			flag_es_policia,
			numeroplaca,
			dependenciaasignada,
			ciudad,
			pais,
			flag_es_admin,
			remitentecambio,
			fechacorreosolicitud,
			asuntocorreosolicitud,
			fechaaplicacionsolicitud,
			notif_alarma_cercana_habilitada,
			notif_alarma_protegido_habilitada,
			notif_alarma_zona_vigilancia_habilitada,
			notif_alarma_policia_habilitada,
			fecha_act_configuracion_notif,
			dias_notif_policia_apagada,
			nombres,
			apellidos,
			numero_movil,
			email,
			persona_lider_redconf_id,
			national_id,
			flag_red_confianza,
			fecha_red_confianza,
			limite_alarmas_feed,
			intervalo_background_minutos
		FROM public.personas
		WHERE persona_id = p_persona_id;

		/*FIN DE COPIA, INICIO DE ELIMINACIONES*/

		-- Eliminar mensajes de chat publicitarios PRIMERO (tienen FK a chat_publicidad Y a personas como remitente)
		delete from public.mensajes_chat_publicidad
		where chat_id in (
			select chat_id from public.chat_publicidad 
			where proveedor_persona_id=p_persona_id OR interesado_persona_id=p_persona_id
		);

		delete from public.mensajes_chat_publicidad
		where remitente_persona_id=p_persona_id;

		-- Eliminar chats publicitarios (tienen FK a personas)
		delete from public.chat_publicidad
		where proveedor_persona_id=p_persona_id;

		delete from public.chat_publicidad
		where interesado_persona_id=p_persona_id;

		delete from public.calificadores_descripcion	
		where iddescripcion in (select iddescripcion from public.descripcionesalarmas where persona_id=p_persona_id);

		delete from public.calificadores_descripcion	
		where iddescripcion in (select iddescripcion from public.descripcionesalarmas where alarma_id in (select alarma_id from public.alarmas where persona_id=p_persona_id));

		delete from public.calificadores_descripcion	
		where persona_id =p_persona_id;

		delete from public.dispositivos
		where persona_id=p_persona_id;

		delete from public.ubicaciones
		where persona_id=p_persona_id;

		delete from public.ubicaciones_testing
		where persona_id=p_persona_id;

		delete from public.descripcionesalarmas
		where persona_id=p_persona_id;

		delete from public.notificaciones_persona
		where alarma_id in (select alarma_id from public.alarmas where persona_id=p_persona_id);

		delete from public.descripcionesalarmas
		where alarma_id in (select alarma_id from public.alarmas where persona_id=p_persona_id);

		delete from public.mensajes_a_usuarios
		where persona_id=p_persona_id;

		delete from public.mensajes_a_usuarios
		where alarma_id in (select alarma_id from public.alarmas where persona_id=p_persona_id);

		delete from public.atencion_policiaca
		where alarma_id in (select alarma_id from public.alarmas where persona_id=p_persona_id);

		delete from public.atencion_policiaca
		where persona_id =p_persona_id;


		delete from public.alarmas
		where persona_id=p_persona_id;

		delete from public.subscripciones
		where id_rel_protegido in (select id_rel_protegido from public.relacion_protegidos where id_persona_protector=p_persona_id);

		delete from public.subscripciones
		where id_rel_protegido in (select id_rel_protegido from public.relacion_protegidos where id_persona_protegida=p_persona_id);

		delete from public.relacion_protegidos
		where id_persona_protector=p_persona_id;

		delete from public.relacion_protegidos
		where id_persona_protegida=p_persona_id;

		delete from public.subscripciones
		where persona_id=p_persona_id;

		delete from public.transacciones_personas
		where persona_id=p_persona_id;

		delete from public.aceptacion_condiciones
		where persona_id=p_persona_id;

		delete from public.permisos_pendientes_protegidos
		where persona_id_protector=p_persona_id;

		delete from public.permisos_pendientes_protegidos
		where persona_id_protegido=p_persona_id;

		delete from public.notificaciones_persona
		where persona_id=p_persona_id;

		delete from public.poderes_regalados
		where persona_id=p_persona_id;

		delete from public.personas
		where persona_id=p_persona_id;
		
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
