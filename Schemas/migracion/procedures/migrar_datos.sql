-- PROCEDURE: migracion.migrar_datos()
-- MODIFICADO: 16-02-2026 - Cambio de RAISE WARNING a RAISE EXCEPTION para detectar errores de migración
-- MODIFICADO: 23-02-2026 - Ampliar retención de datos de 32 días a 120 días
-- MODIFICADO: 25-04-2026 - Corregir bloque alarmas: listar columnas explícitamente por cambio en public.alarmas (2026-02-26); eliminar bloque duplicado de traducciones_contrato

-- DROP PROCEDURE IF EXISTS migracion.migrar_datos();

CREATE OR REPLACE PROCEDURE migracion.migrar_datos(
	)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
    v_cantidad_registros bigint;
BEGIN
    -- Migra alarmas
    BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_alarmas;

        WITH new_alarmas AS (
            SELECT * FROM public.alarmas
            WHERE estado_alarma = 'C'  -- Solo alarmas cerradas
              AND alarma_id NOT IN (SELECT alarma_id FROM migracion.migra_alarmas)
        )
        INSERT INTO migracion.migra_alarmas (
            alarma_id,
            persona_id,
            tipoalarma_id,
            fecha_alarma,
            latitud,
            longitud,
            calificacion_alarma,
            estado_alarma,
            latitud_originador,
            longitud_originador,
            ip_usuario_originador,
            distancia_alarma_originador,
            alarma_id_padre,
            evaluada,
            cnt_likes,
            cnt_reenvios,
            cnt_verdaderos,
            cnt_falsos
        )
        SELECT
            alarma_id,
            persona_id,
            tipoalarma_id,
            fecha_alarma,
            latitud,
            longitud,
            calificacion_alarma,
            estado_alarma,
            latitud_originador,
            longitud_originador,
            ip_usuario_originador,
            distancia_alarma_originador,
            alarma_id_padre,
            evaluada,
            cnt_likes,
            cnt_reenvios,
            cnt_verdaderos,
            cnt_falsos
        FROM new_alarmas;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_alarmas;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('alarmas', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando alarmas: %', SQLERRM;
    END;

	-- Migra DescripcionesAlarmas

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_DescripcionesAlarmas;

        WITH new_DescripcionesAlarmas AS (
            SELECT da.* FROM public.DescripcionesAlarmas da
            INNER JOIN public.alarmas al
            ON (al.alarma_id=da.alarma_id)
            WHERE al.estado_alarma = 'C'  -- Solo descripciones de alarmas cerradas
              AND da.IdDescripcion NOT IN (SELECT IdDescripcion FROM migracion.migra_DescripcionesAlarmas)
        )
        INSERT INTO migracion.migra_DescripcionesAlarmas SELECT * FROM new_DescripcionesAlarmas;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_DescripcionesAlarmas;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('DescripcionesAlarmas', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando DescripcionesAlarmas: %', SQLERRM;
    END;
	
	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_calificadores_descripcion;

        WITH new_calificadores_descripcion AS (
            SELECT cd.* FROM public.calificadores_descripcion cd
            INNER JOIN public.DescripcionesAlarmas da
            ON(cd.IdDescripcion=da.IdDescripcion)
            INNER JOIN public.alarmas al
            ON (al.alarma_id=da.alarma_id)
            WHERE al.estado_alarma = 'C'  -- Solo calificadores de alarmas cerradas
              AND cd.calificacion_id NOT IN (SELECT calificacion_id FROM migracion.migra_calificadores_descripcion)
        )
        INSERT INTO migracion.migra_calificadores_descripcion SELECT * FROM new_calificadores_descripcion;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_calificadores_descripcion;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('calificadores_descripcion', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando calificadores_descripcion: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_personas;

        WITH new_personas AS (
                SELECT 
                    p.persona_id,
                    p.radio_alarmas_id,
                    p.login,
                    p.user_id_thirdparty,
                    p.fechacreacion,
                    p.marca_bloqueo,
                    p.credibilidad_persona,
                    p.fecha_ultima_marca_bloqueo,
                    p.tiempo_refresco_mapa,
                    p.saldo_poderes,
                    p.flag_es_policia,
                    p.numeroplaca,
                    p.dependenciaasignada,
                    p.ciudad,
                    p.pais,
                    p.flag_es_admin,
                    p.remitentecambio,
                    p.fechacorreosolicitud,
                    p.asuntocorreosolicitud,
                    p.fechaaplicacionsolicitud,
                    p.notif_alarma_cercana_habilitada,
                    p.notif_alarma_protegido_habilitada,
                    p.notif_alarma_zona_vigilancia_habilitada,
                    p.notif_alarma_policia_habilitada,
                    p.fecha_act_configuracion_notif,
                    p.dias_notif_policia_apagada,
                    p.nombres,
                    p.apellidos,
                    p.numero_movil,
                    p.email,
                    p.persona_lider_redconf_id,
                    p.national_id,
                    p.flag_red_confianza,
                    p.fecha_red_confianza
                FROM public.personas p
                WHERE p.persona_id NOT IN (SELECT persona_id FROM migracion.migra_personas)
                /*and (fechacreacion>now() - interval '10 days' or fecha_ultima_marca_bloqueo>now() - interval '10 days')*/
            )
            INSERT INTO migracion.migra_personas (
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
                fecha_red_confianza
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
                fecha_red_confianza
            FROM new_personas;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_personas;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('personas', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando personas: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_radio_alarmas;

        WITH new_radio_alarmas AS (
            SELECT p.* FROM public.radio_alarmas p
            WHERE p.radio_alarmas_id NOT IN (SELECT radio_alarmas_id FROM migracion.migra_radio_alarmas)
        )
        INSERT INTO migracion.migra_radio_alarmas SELECT * FROM new_radio_alarmas;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_radio_alarmas;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('radio_alarmas', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando radio_alarmas: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_relacion_protegidos;

        WITH new_relacion_protegidos AS (
            SELECT p.* FROM public.relacion_protegidos p
			inner join public.subscripciones s
			on (s.id_rel_protegido=p.id_rel_protegido)
            WHERE p.id_rel_protegido NOT IN (SELECT id_rel_protegido FROM migracion.migra_relacion_protegidos)
			and ((s.fecha_finalizacion between now() - interval '5 days' and now()) or now() BETWEEN s.fecha_activacion and coalesce(s.fecha_finalizacion,now()))
        )
        INSERT INTO migracion.migra_relacion_protegidos SELECT * FROM new_relacion_protegidos;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_relacion_protegidos;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('relacion_protegidos', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando relacion_protegidos: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_subscripciones;

        WITH new_subscripciones AS (
            SELECT s.*
            FROM public.subscripciones s
            LEFT JOIN public.alarmas a ON s.alarma_id = a.alarma_id AND s.persona_id = a.persona_id
            WHERE s.subscripcion_id NOT IN (SELECT subscripcion_id FROM migracion.migra_subscripciones)
            AND (
                -- Para subscripciones sin alarma: migrar si ya finalizaron
                (s.alarma_id IS NULL AND s.fecha_finalizacion < now())
                OR
                -- Para subscripciones con alarma (promocionales): migrar si la alarma está cerrada Y la subscripción finalizó
                (s.alarma_id IS NOT NULL AND a.estado_alarma = 'C' AND s.fecha_finalizacion < now())
            )
        )
        INSERT INTO migracion.migra_subscripciones SELECT * FROM new_subscripciones;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_subscripciones;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('subscripciones', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando subscripciones: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_tipoalarma;

        WITH new_tipoalarma AS (
            SELECT p.* FROM public.tipoalarma p
            WHERE p.tipoalarma_id NOT IN (SELECT tipoalarma_id FROM migracion.migra_tipoalarma)
        )
        INSERT INTO migracion.migra_tipoalarma SELECT * FROM new_tipoalarma;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_tipoalarma;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('tipoalarma', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando tipoalarma: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_ubicaciones;

        WITH new_ubicaciones AS (
            SELECT p.* FROM public.ubicaciones p
            WHERE p.ubicacion_id NOT IN (SELECT ubicacion_id FROM migracion.migra_ubicaciones)
        )
        INSERT INTO migracion.migra_ubicaciones SELECT * FROM new_ubicaciones;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_ubicaciones;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('ubicaciones', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando ubicaciones: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_ubicaciones_testing;

        WITH new_ubicaciones_testing AS (
            SELECT p.* FROM public.ubicaciones_testing p
            WHERE p.ubicacion_id NOT IN (SELECT ubicacion_id FROM migracion.migra_ubicaciones_testing)
			and fecha_ubicacion < now() - interval '2 days' 
        )
        INSERT INTO migracion.migra_ubicaciones_testing SELECT * FROM new_ubicaciones_testing;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_ubicaciones_testing;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('ubicaciones_testing', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando ubicaciones_testing: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_poderes_regalados;

        WITH new_poderes_regalados AS (
            SELECT p.* FROM public.poderes_regalados p
            WHERE p.id_regalo NOT IN (SELECT id_regalo FROM migracion.migra_poderes_regalados)
			and fecha_regalo < now() - interval '10 days' 
        )
        INSERT INTO migracion.migra_poderes_regalados SELECT * FROM new_poderes_regalados;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_poderes_regalados;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('poderes_regalados', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando poderes_regalados: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_aceptacion_condiciones;

        WITH new_aceptacion_condiciones AS (
            SELECT p.* FROM public.aceptacion_condiciones p
            WHERE p.aceptacion_id NOT IN (SELECT aceptacion_id FROM migracion.migra_aceptacion_condiciones)
			and fecha_aceptacion < now() - interval '3 days' 
        )
        INSERT INTO migracion.migra_aceptacion_condiciones SELECT * FROM new_aceptacion_condiciones;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_aceptacion_condiciones;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('aceptacion_condiciones', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando aceptacion_condiciones: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_app_versions;

        WITH new_app_versions AS (
            SELECT p.* FROM public.app_versions p
            WHERE p.id NOT IN (SELECT id FROM migracion.migra_app_versions)
			and date_added < now() - interval '3 days' 
        )
        INSERT INTO migracion.migra_app_versions SELECT * FROM new_app_versions;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_app_versions;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('app_versions', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando app_versions: %', SQLERRM;
    END;

		BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_condiciones_servicio;

        WITH new_condiciones_servicio AS (
            SELECT p.* FROM public.condiciones_servicio p
            WHERE p.contrato_id NOT IN (SELECT contrato_id FROM migracion.migra_condiciones_servicio)
        )
        INSERT INTO migracion.migra_condiciones_servicio SELECT * FROM new_condiciones_servicio;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_condiciones_servicio;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('condiciones_servicio', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando condiciones_servicio: %', SQLERRM;
    END;

		BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_dispositivos;

        WITH new_dispositivos AS (
            SELECT p.* FROM public.dispositivos p
            WHERE p.id_dispositivo NOT IN (SELECT id_dispositivo FROM migracion.migra_dispositivos)
			and fecha_inicio < now() - interval '3 days' 
			and fecha_fin is not null 
        )
        INSERT INTO migracion.migra_dispositivos SELECT * FROM new_dispositivos;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_dispositivos;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('dispositivos', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando dispositivos: %', SQLERRM;
    END;

	
	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_mensajes_a_usuarios;

        WITH new_mensajes_a_usuarios AS (
            SELECT p.* FROM public.mensajes_a_usuarios p
            WHERE p.mensaje_id NOT IN (SELECT mensaje_id FROM migracion.migra_mensajes_a_usuarios)
			and fecha_mensaje < now() - interval '120 days' 
        )
        INSERT INTO migracion.migra_mensajes_a_usuarios SELECT * FROM new_mensajes_a_usuarios;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_mensajes_a_usuarios;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('mensajes_a_usuarios', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando mensajes_a_usuarios: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_notificaciones_persona;

        WITH new_notificaciones_persona AS (
            SELECT p.* FROM public.notificaciones_persona p
            WHERE p.notificacion_id NOT IN (SELECT notificacion_id FROM migracion.migra_notificaciones_persona)
			and fecha_notificacion < now() - interval '120 days' 
        )
        INSERT INTO migracion.migra_notificaciones_persona SELECT * FROM new_notificaciones_persona;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_notificaciones_persona;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('notificaciones_persona', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando notificaciones_persona: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_numerales_contrato;

        WITH new_numerales_contrato AS (
            SELECT p.* FROM public.numerales_contrato p
            WHERE p.numeral_id NOT IN (SELECT numeral_id FROM migracion.migra_numerales_contrato)
        )
        INSERT INTO migracion.migra_numerales_contrato SELECT * FROM new_numerales_contrato;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_numerales_contrato;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('numerales_contrato', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando numerales_contrato: %', SQLERRM;
    END;

	
	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_permisos_pendientes_protegidos;

        WITH new_permisos_pendientes_protegidos AS (
            SELECT p.* FROM public.permisos_pendientes_protegidos p
            WHERE p.permiso_pendiente_id NOT IN (SELECT permiso_pendiente_id FROM migracion.migra_permisos_pendientes_protegidos)
			and p.fecha_solicitud < now() - interval '120 days' 
        )
        INSERT INTO migracion.migra_permisos_pendientes_protegidos SELECT * FROM new_permisos_pendientes_protegidos;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_permisos_pendientes_protegidos;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('permisos_pendientes_protegidos', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando permisos_pendientes_protegidos: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_poderes;

        WITH new_poderes AS (
            SELECT p.* FROM public.poderes p
            WHERE p.poder_id NOT IN (SELECT poder_id FROM migracion.migra_poderes)
        )
        INSERT INTO migracion.migra_poderes SELECT * FROM new_poderes;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_poderes;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('poderes', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando poderes: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_tiporelacion;

        WITH new_tiporelacion AS (
            SELECT p.* FROM public.tiporelacion p
            WHERE p.tiporelacion_id NOT IN (SELECT tiporelacion_id FROM migracion.migra_tiporelacion)
        )
        INSERT INTO migracion.migra_tiporelacion SELECT * FROM new_tiporelacion;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_tiporelacion;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('tiporelacion', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando tiporelacion: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_tiposubscripcion;

        WITH new_tiposubscripcion AS (
            SELECT p.* FROM public.tiposubscripcion p
            WHERE p.tipo_subscr_id NOT IN (SELECT tipo_subscr_id FROM migracion.migra_tiposubscripcion)
        )
        INSERT INTO migracion.migra_tiposubscripcion SELECT * FROM new_tiposubscripcion;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_tiposubscripcion;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('tiposubscripcion', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando tiposubscripcion: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_traducciones_contrato;

        WITH new_traducciones_contrato AS (
            SELECT p.* FROM public.traducciones_contrato p
            WHERE p.traduccion_id NOT IN (SELECT traduccion_id FROM migracion.migra_traducciones_contrato)
        )
        INSERT INTO migracion.migra_traducciones_contrato SELECT * FROM new_traducciones_contrato;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_traducciones_contrato;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('traducciones_contrato', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando traducciones_contrato: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_transacciones_personas;

        WITH new_transacciones_personas AS (
            SELECT p.* FROM public.transacciones_personas p
            WHERE p.transaccion_id NOT IN (SELECT transaccion_id FROM migracion.migra_transacciones_personas)
			and p.fecha_transaccion < now() - interval '120 days' 
        )
        INSERT INTO migracion.migra_transacciones_personas SELECT * FROM new_transacciones_personas;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_transacciones_personas;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('transacciones_personas', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando transacciones_personas: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_valorsubscripciones;

        WITH new_valorsubscripciones AS (
            SELECT p.* FROM public.valorsubscripciones p
            WHERE p.valorsubscripcion_id NOT IN (SELECT valorsubscripcion_id FROM migracion.migra_valorsubscripciones)
        )
        INSERT INTO migracion.migra_valorsubscripciones SELECT * FROM new_valorsubscripciones;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_valorsubscripciones;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('valorsubscripciones', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando valorsubscripciones: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_atencion_policiaca;

        WITH new_atencion_policiaca AS (
            SELECT ap.* FROM public.atencion_policiaca ap
            INNER JOIN public.alarmas a ON ap.alarma_id = a.alarma_id
            WHERE ap.atencion_policiaca_id NOT IN (SELECT atencion_policiaca_id FROM migracion.migra_atencion_policiaca)
              AND a.estado_alarma = 'C'  -- Solo atenciones de alarmas cerradas
        )
        INSERT INTO migracion.migra_atencion_policiaca SELECT * FROM new_atencion_policiaca;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_atencion_policiaca;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('atencion_policiaca', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando atencion_policiaca: %', SQLERRM;
    END;

	-- =====================================================================
	-- TABLAS NUEVAS (versión 2026) - agregadas 2026-04-25
	-- =====================================================================

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_alarmas_likes;

        WITH new_alarmas_likes AS (
            SELECT al.* FROM public.alarmas_likes al
            INNER JOIN public.alarmas a ON al.alarma_id = a.alarma_id
            WHERE al.like_id NOT IN (SELECT like_id FROM migracion.migra_alarmas_likes)
              AND a.estado_alarma = 'C'
        )
        INSERT INTO migracion.migra_alarmas_likes SELECT * FROM new_alarmas_likes;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_alarmas_likes;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('alarmas_likes', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando alarmas_likes: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_alarmas_reenvios;

        WITH new_alarmas_reenvios AS (
            SELECT ar.* FROM public.alarmas_reenvios ar
            INNER JOIN public.alarmas a ON ar.alarma_id = a.alarma_id
            WHERE ar.reenvio_id NOT IN (SELECT reenvio_id FROM migracion.migra_alarmas_reenvios)
              AND a.estado_alarma = 'C'
        )
        INSERT INTO migracion.migra_alarmas_reenvios SELECT * FROM new_alarmas_reenvios;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_alarmas_reenvios;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('alarmas_reenvios', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando alarmas_reenvios: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_alarmas_territorio;

        WITH new_alarmas_territorio AS (
            SELECT at.* FROM public.alarmas_territorio at
            INNER JOIN public.alarmas a ON at.alarma_id = a.alarma_id
            WHERE at.alarma_id NOT IN (SELECT alarma_id FROM migracion.migra_alarmas_territorio)
              AND a.estado_alarma = 'C'
        )
        INSERT INTO migracion.migra_alarmas_territorio SELECT * FROM new_alarmas_territorio;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_alarmas_territorio;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('alarmas_territorio', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando alarmas_territorio: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_fotos_descripciones_alarmas;

        WITH new_fotos_descripciones_alarmas AS (
            SELECT f.* FROM public.fotos_descripciones_alarmas f
            INNER JOIN public.descripcionesalarmas da ON f.iddescripcion = da.iddescripcion
            INNER JOIN public.alarmas a ON da.alarma_id = a.alarma_id
            WHERE f.foto_id NOT IN (SELECT foto_id FROM migracion.migra_fotos_descripciones_alarmas)
              AND a.estado_alarma = 'C'
        )
        INSERT INTO migracion.migra_fotos_descripciones_alarmas SELECT * FROM new_fotos_descripciones_alarmas;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_fotos_descripciones_alarmas;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('fotos_descripciones_alarmas', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando fotos_descripciones_alarmas: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_personas_seguidores;

        WITH new_personas_seguidores AS (
            SELECT p.* FROM public.personas_seguidores p
            WHERE p.seguimiento_id NOT IN (SELECT seguimiento_id FROM migracion.migra_personas_seguidores)
        )
        INSERT INTO migracion.migra_personas_seguidores SELECT * FROM new_personas_seguidores;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_personas_seguidores;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('personas_seguidores', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando personas_seguidores: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_solicitudes_cierre;

        WITH new_solicitudes_cierre AS (
            SELECT p.* FROM public.solicitudes_cierre p
            WHERE p.solicitud_id NOT IN (SELECT solicitud_id FROM migracion.migra_solicitudes_cierre)
              AND p.estado IN ('aprobada', 'denegada')
        )
        INSERT INTO migracion.migra_solicitudes_cierre SELECT * FROM new_solicitudes_cierre;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_solicitudes_cierre;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('solicitudes_cierre', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando solicitudes_cierre: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_votos_cierre;

        WITH new_votos_cierre AS (
            SELECT v.* FROM public.votos_cierre v
            INNER JOIN public.solicitudes_cierre s ON v.solicitud_id = s.solicitud_id
            WHERE v.voto_id NOT IN (SELECT voto_id FROM migracion.migra_votos_cierre)
              AND s.estado IN ('aprobada', 'denegada')
        )
        INSERT INTO migracion.migra_votos_cierre SELECT * FROM new_votos_cierre;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_votos_cierre;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('votos_cierre', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando votos_cierre: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_notificaciones_promociones;

        WITH new_notificaciones_promociones AS (
            SELECT np.* FROM public.notificaciones_promociones np
            INNER JOIN public.subscripciones s ON np.subscripcion_id = s.subscripcion_id
            WHERE np.id_notificacion_promocion NOT IN (SELECT id_notificacion_promocion FROM migracion.migra_notificaciones_promociones)
              AND s.fecha_finalizacion < now()
        )
        INSERT INTO migracion.migra_notificaciones_promociones SELECT * FROM new_notificaciones_promociones;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_notificaciones_promociones;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('notificaciones_promociones', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando notificaciones_promociones: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_configuracion_costos_promocionales;

        WITH new_configuracion_costos_promocionales AS (
            SELECT p.* FROM public.configuracion_costos_promocionales p
            WHERE p.config_id NOT IN (SELECT config_id FROM migracion.migra_configuracion_costos_promocionales)
        )
        INSERT INTO migracion.migra_configuracion_costos_promocionales SELECT * FROM new_configuracion_costos_promocionales;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_configuracion_costos_promocionales;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('configuracion_costos_promocionales', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando configuracion_costos_promocionales: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_historico_costos_promocionales;

        WITH new_historico_costos_promocionales AS (
            SELECT p.* FROM public.historico_costos_promocionales p
            WHERE p.historico_id NOT IN (SELECT historico_id FROM migracion.migra_historico_costos_promocionales)
        )
        INSERT INTO migracion.migra_historico_costos_promocionales SELECT * FROM new_historico_costos_promocionales;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_historico_costos_promocionales;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('historico_costos_promocionales', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando historico_costos_promocionales: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_historico_valorsubscripciones;

        WITH new_historico_valorsubscripciones AS (
            SELECT p.* FROM public.historico_valorsubscripciones p
            WHERE p.historico_id NOT IN (SELECT historico_id FROM migracion.migra_historico_valorsubscripciones)
        )
        INSERT INTO migracion.migra_historico_valorsubscripciones SELECT * FROM new_historico_valorsubscripciones;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_historico_valorsubscripciones;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('historico_valorsubscripciones', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando historico_valorsubscripciones: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_emprendimientos;

        WITH new_emprendimientos AS (
            SELECT p.* FROM public.emprendimientos p
            WHERE p.id_emprendimiento NOT IN (SELECT id_emprendimiento FROM migracion.migra_emprendimientos)
        )
        INSERT INTO migracion.migra_emprendimientos SELECT * FROM new_emprendimientos;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_emprendimientos;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('emprendimientos', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando emprendimientos: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_chat_publicidad;

        WITH new_chat_publicidad AS (
            SELECT p.* FROM public.chat_publicidad p
            WHERE p.chat_id NOT IN (SELECT chat_id FROM migracion.migra_chat_publicidad)
              AND p.estado IN ('closed', 'archived')
        )
        INSERT INTO migracion.migra_chat_publicidad SELECT * FROM new_chat_publicidad;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_chat_publicidad;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('chat_publicidad', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando chat_publicidad: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_mensajes_chat_publicidad;

        WITH new_mensajes_chat_publicidad AS (
            SELECT m.* FROM public.mensajes_chat_publicidad m
            INNER JOIN public.chat_publicidad c ON m.chat_id = c.chat_id
            WHERE m.mensaje_id NOT IN (SELECT mensaje_id FROM migracion.migra_mensajes_chat_publicidad)
              AND c.estado IN ('closed', 'archived')
        )
        INSERT INTO migracion.migra_mensajes_chat_publicidad SELECT * FROM new_mensajes_chat_publicidad;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_mensajes_chat_publicidad;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('mensajes_chat_publicidad', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando mensajes_chat_publicidad: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_paises;

        WITH new_paises AS (
            SELECT p.* FROM public.paises p
            WHERE p.pais_id NOT IN (SELECT pais_id FROM migracion.migra_paises)
        )
        INSERT INTO migracion.migra_paises SELECT * FROM new_paises;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_paises;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('paises', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando paises: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_categoria_alarma;

        WITH new_categoria_alarma AS (
            SELECT p.* FROM public.categoria_alarma p
            WHERE p.categoria_alarma_id NOT IN (SELECT categoria_alarma_id FROM migracion.migra_categoria_alarma)
        )
        INSERT INTO migracion.migra_categoria_alarma SELECT * FROM new_categoria_alarma;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_categoria_alarma;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('categoria_alarma', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando categoria_alarma: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_pol_aprobacion_ciudadana;

        WITH new_pol_aprobacion_ciudadana AS (
            SELECT p.* FROM public.pol_aprobacion_ciudadana p
            WHERE p.aprobacion_id NOT IN (SELECT aprobacion_id FROM migracion.migra_pol_aprobacion_ciudadana)
        )
        INSERT INTO migracion.migra_pol_aprobacion_ciudadana SELECT * FROM new_pol_aprobacion_ciudadana;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_pol_aprobacion_ciudadana;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('pol_aprobacion_ciudadana', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando pol_aprobacion_ciudadana: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_pol_territorios;

        INSERT INTO migracion.migra_pol_territorios (
            territorio_id, nivel, nombre_nivel_local, nombre, nombre_oficial,
            codigo_dane, parent_id, parent_pais_id, path, activo, created_at
        )
        SELECT
            p.territorio_id, p.nivel, p.nombre_nivel_local, p.nombre, p.nombre_oficial,
            p.codigo_dane, p.parent_id, p.parent_pais_id, p.path::text, p.activo, p.created_at
        FROM public.pol_territorios p
        WHERE p.territorio_id NOT IN (SELECT territorio_id FROM migracion.migra_pol_territorios);

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_pol_territorios;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('pol_territorios', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando pol_territorios: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_pol_cargos;

        WITH new_pol_cargos AS (
            SELECT p.* FROM public.pol_cargos p
            WHERE p.cargo_id NOT IN (SELECT cargo_id FROM migracion.migra_pol_cargos)
        )
        INSERT INTO migracion.migra_pol_cargos SELECT * FROM new_pol_cargos;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_pol_cargos;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('pol_cargos', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando pol_cargos: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_pol_politicos;

        WITH new_pol_politicos AS (
            SELECT p.* FROM public.pol_politicos p
            WHERE p.politico_id NOT IN (SELECT politico_id FROM migracion.migra_pol_politicos)
        )
        INSERT INTO migracion.migra_pol_politicos SELECT * FROM new_pol_politicos;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_pol_politicos;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('pol_politicos', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando pol_politicos: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_pol_vigencias;

        WITH new_pol_vigencias AS (
            SELECT p.* FROM public.pol_vigencias p
            WHERE p.vigencia_id NOT IN (SELECT vigencia_id FROM migracion.migra_pol_vigencias)
        )
        INSERT INTO migracion.migra_pol_vigencias SELECT * FROM new_pol_vigencias;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_pol_vigencias;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('pol_vigencias', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando pol_vigencias: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_pol_homologacion_google;

        WITH new_pol_homologacion_google AS (
            SELECT p.* FROM public.pol_homologacion_google p
            WHERE p.homologacion_id NOT IN (SELECT homologacion_id FROM migracion.migra_pol_homologacion_google)
        )
        INSERT INTO migracion.migra_pol_homologacion_google SELECT * FROM new_pol_homologacion_google;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_pol_homologacion_google;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('pol_homologacion_google', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando pol_homologacion_google: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_pol_metricas_territorio;

        WITH new_pol_metricas_territorio AS (
            SELECT p.* FROM public.pol_metricas_territorio p
            WHERE p.metrica_id NOT IN (SELECT metrica_id FROM migracion.migra_pol_metricas_territorio)
        )
        INSERT INTO migracion.migra_pol_metricas_territorio SELECT * FROM new_pol_metricas_territorio;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_pol_metricas_territorio;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('pol_metricas_territorio', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando pol_metricas_territorio: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_metricas_zona;

        WITH new_metricas_zona AS (
            SELECT p.* FROM public.metricas_zona p
            WHERE p.id NOT IN (SELECT id FROM migracion.migra_metricas_zona)
              AND p.fecha_fin_vigencia IS NOT NULL
        )
        INSERT INTO migracion.migra_metricas_zona SELECT * FROM new_metricas_zona;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_metricas_zona;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('metricas_zona', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando metricas_zona: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_mv_metricas_zona;

        -- mv_metricas_zona no tiene clave primaria propia; migrar snapshot completo cada vez
        DELETE FROM migracion.migra_mv_metricas_zona;
        INSERT INTO migracion.migra_mv_metricas_zona SELECT * FROM public.mv_metricas_zona;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_mv_metricas_zona;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('mv_metricas_zona', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando mv_metricas_zona: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_metricas_politico;

        WITH new_metricas_politico AS (
            SELECT p.* FROM public.metricas_politico p
            WHERE p.id NOT IN (SELECT id FROM migracion.migra_metricas_politico)
              AND p.fecha_fin_vigencia IS NOT NULL
        )
        INSERT INTO migracion.migra_metricas_politico SELECT * FROM new_metricas_politico;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_metricas_politico;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('metricas_politico', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando metricas_politico: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        -- mv_metricas_politico no tiene clave primaria propia; migrar snapshot completo cada vez
        DELETE FROM migracion.migra_mv_metricas_politico;
        INSERT INTO migracion.migra_mv_metricas_politico SELECT * FROM public.mv_metricas_politico;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_mv_metricas_politico;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('mv_metricas_politico', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando mv_metricas_politico: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        -- mv_metricas_politico_tipos: migrar por (politico_id, tipoalarma_id)
        DELETE FROM migracion.migra_mv_metricas_politico_tipos;
        INSERT INTO migracion.migra_mv_metricas_politico_tipos SELECT * FROM public.mv_metricas_politico_tipos;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_mv_metricas_politico_tipos;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('mv_metricas_politico_tipos', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando mv_metricas_politico_tipos: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_metricas_emprendedores;

        WITH new_metricas_emprendedores AS (
            SELECT p.* FROM public.metricas_emprendedores p
            WHERE p.id NOT IN (SELECT id FROM migracion.migra_metricas_emprendedores)
              AND p.fecha_fin_vigencia IS NOT NULL
        )
        INSERT INTO migracion.migra_metricas_emprendedores SELECT * FROM new_metricas_emprendedores;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_metricas_emprendedores;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('metricas_emprendedores', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando metricas_emprendedores: %', SQLERRM;
    END;

	BEGIN
		v_cantidad_registros:= 0;

        -- mv_metricas_emprendedores no tiene clave primaria propia; migrar snapshot completo cada vez
        DELETE FROM migracion.migra_mv_metricas_emprendedores;
        INSERT INTO migracion.migra_mv_metricas_emprendedores SELECT * FROM public.mv_metricas_emprendedores;

        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_mv_metricas_emprendedores;

        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('mv_metricas_emprendedores', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Error migrando mv_metricas_emprendedores: %', SQLERRM;
    END;

	BEGIN

		DELETE FROM public.notificaciones_persona p WHERE p.notificacion_id IN (SELECT notificacion_id FROM migracion.migra_notificaciones_persona);
		DELETE FROM public.calificadores_descripcion cd WHERE cd.calificacion_id IN (SELECT calificacion_id FROM migracion.migra_calificadores_descripcion);
		DELETE FROM public.DescripcionesAlarmas da WHERE da.IdDescripcion IN (SELECT IdDescripcion FROM migracion.migra_DescripcionesAlarmas);
		DELETE FROM public.mensajes_a_usuarios p WHERE p.mensaje_id IN (SELECT mensaje_id FROM migracion.migra_mensajes_a_usuarios);
        DELETE FROM public.atencion_policiaca p WHERE p.atencion_policiaca_id IN (SELECT atencion_policiaca_id FROM migracion.migra_atencion_policiaca);
		-- Solo eliminar alarmas que no tengan referencias en tablas que no se migran
		DELETE FROM public.alarmas a WHERE a.alarma_id IN (SELECT alarma_id FROM migracion.migra_alarmas)
		  AND a.alarma_id NOT IN (SELECT DISTINCT alarma_id FROM public.mensajes_a_usuarios WHERE alarma_id IS NOT NULL)
		  AND a.alarma_id NOT IN (SELECT DISTINCT alarma_id FROM public.chat_publicidad WHERE alarma_id IS NOT NULL)
		  AND (NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'solicitudes_cierre')
		       OR a.alarma_id NOT IN (SELECT DISTINCT alarma_id FROM public.solicitudes_cierre WHERE alarma_id IS NOT NULL))
		  AND (NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'alarmas_territorio')
		       OR a.alarma_id NOT IN (SELECT DISTINCT alarma_id FROM public.alarmas_territorio WHERE alarma_id IS NOT NULL));
		DELETE FROM public.subscripciones p WHERE p.subscripcion_id IN (SELECT subscripcion_id FROM migracion.migra_subscripciones)	;
		DELETE FROM public.ubicaciones_testing p WHERE p.ubicacion_id IN (SELECT ubicacion_id FROM migracion.migra_ubicaciones_testing);
		DELETE FROM public.poderes_regalados p WHERE p.id_regalo IN (SELECT id_regalo FROM migracion.migra_poderes_regalados);
		DELETE FROM public.dispositivos p WHERE p.id_dispositivo IN (SELECT id_dispositivo FROM migracion.migra_dispositivos);
		DELETE FROM public.permisos_pendientes_protegidos p WHERE p.permiso_pendiente_id IN (SELECT permiso_pendiente_id FROM migracion.migra_permisos_pendientes_protegidos); 
		DELETE FROM public.transacciones_personas p WHERE p.transaccion_id IN (SELECT transaccion_id FROM migracion.migra_transacciones_personas);

	END;

	--Guarda todo finalmente:
	COMMIT;

END;
$BODY$;
