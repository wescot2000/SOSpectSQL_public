-- PROCEDURE: migracion.migrar_datos()

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
            WHERE fecha_alarma < now() - interval '32 days' AND alarma_id NOT IN (SELECT alarma_id FROM migracion.migra_alarmas)
        )
        INSERT INTO migracion.migra_alarmas SELECT * FROM new_alarmas;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_alarmas;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('alarmas', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Error migrando alarmas: %', SQLERRM;
		ROLLBACK;
    END;

	-- Migra DescripcionesAlarmas

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_DescripcionesAlarmas;

        WITH new_DescripcionesAlarmas AS (
            SELECT da.* FROM public.DescripcionesAlarmas da
            INNER JOIN public.alarmas al
            ON (al.alarma_id=da.alarma_id)
            WHERE al.fecha_alarma < now() - interval '32 days' AND da.IdDescripcion NOT IN (SELECT IdDescripcion FROM migracion.migra_DescripcionesAlarmas)
        )
        INSERT INTO migracion.migra_DescripcionesAlarmas SELECT * FROM new_DescripcionesAlarmas;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_DescripcionesAlarmas;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('DescripcionesAlarmas', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Error migrando DescripcionesAlarmas: %', SQLERRM;
		ROLLBACK;
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
            WHERE al.fecha_alarma < now() - interval '32 days' AND cd.calificacion_id NOT IN (SELECT calificacion_id FROM migracion.migra_calificadores_descripcion)
        )
        INSERT INTO migracion.migra_calificadores_descripcion SELECT * FROM new_calificadores_descripcion;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_calificadores_descripcion;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('calificadores_descripcion', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Error migrando calificadores_descripcion: %', SQLERRM;
		ROLLBACK;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_personas;

        WITH new_personas AS (
            SELECT p.* FROM public.personas p
            WHERE p.persona_id NOT IN (SELECT persona_id FROM migracion.migra_personas)
			and (fechacreacion>now() - interval '10 days' or fecha_ultima_marca_bloqueo>now() - interval '10 days')
        )
        INSERT INTO migracion.migra_personas SELECT * FROM new_personas;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_personas;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('personas', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Error migrando personas: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando radio_alarmas: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando relacion_protegidos: %', SQLERRM;
		ROLLBACK;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_subscripciones;

        WITH new_subscripciones AS (
            SELECT p.* FROM public.subscripciones p
            WHERE p.subscripcion_id NOT IN (SELECT subscripcion_id FROM migracion.migra_subscripciones)
			and ((p.fecha_finalizacion between now() - interval '5 days' and now()) or now() BETWEEN p.fecha_activacion and coalesce(p.fecha_finalizacion,now()))
        )
        INSERT INTO migracion.migra_subscripciones SELECT * FROM new_subscripciones;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_subscripciones;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('subscripciones', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Error migrando subscripciones: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando tipoalarma: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando ubicaciones: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando ubicaciones_testing: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando poderes_regalados: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando aceptacion_condiciones: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando app_versions: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando condiciones_servicio: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando dispositivos: %', SQLERRM;
		ROLLBACK;
    END;

	
	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_mensajes_a_usuarios;

        WITH new_mensajes_a_usuarios AS (
            SELECT p.* FROM public.mensajes_a_usuarios p
            WHERE p.mensaje_id NOT IN (SELECT mensaje_id FROM migracion.migra_mensajes_a_usuarios)
			and fecha_mensaje < now() - interval '32 days' 
        )
        INSERT INTO migracion.migra_mensajes_a_usuarios SELECT * FROM new_mensajes_a_usuarios;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_mensajes_a_usuarios;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('mensajes_a_usuarios', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Error migrando mensajes_a_usuarios: %', SQLERRM;
		ROLLBACK;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_notificaciones_persona;

        WITH new_notificaciones_persona AS (
            SELECT p.* FROM public.notificaciones_persona p
            WHERE p.notificacion_id NOT IN (SELECT notificacion_id FROM migracion.migra_notificaciones_persona)
			and fecha_notificacion < now() - interval '32 days' 
        )
        INSERT INTO migracion.migra_notificaciones_persona SELECT * FROM new_notificaciones_persona;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_notificaciones_persona;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('notificaciones_persona', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Error migrando notificaciones_persona: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando numerales_contrato: %', SQLERRM;
		ROLLBACK;
    END;

	
	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_permisos_pendientes_protegidos;

        WITH new_permisos_pendientes_protegidos AS (
            SELECT p.* FROM public.permisos_pendientes_protegidos p
            WHERE p.permiso_pendiente_id NOT IN (SELECT permiso_pendiente_id FROM migracion.migra_permisos_pendientes_protegidos)
			and p.fecha_solicitud < now() - interval '32 days' 
        )
        INSERT INTO migracion.migra_permisos_pendientes_protegidos SELECT * FROM new_permisos_pendientes_protegidos;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_permisos_pendientes_protegidos;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('permisos_pendientes_protegidos', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Error migrando permisos_pendientes_protegidos: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando poderes: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando tiporelacion: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando tiposubscripcion: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando traducciones_contrato: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando traducciones_contrato: %', SQLERRM;
		ROLLBACK;
    END;

	BEGIN
		v_cantidad_registros:= 0;
		
        SELECT COUNT(*) INTO v_cantidad_registros FROM migracion.migra_transacciones_personas;

        WITH new_transacciones_personas AS (
            SELECT p.* FROM public.transacciones_personas p
            WHERE p.transaccion_id NOT IN (SELECT transaccion_id FROM migracion.migra_transacciones_personas)
			and p.fecha_transaccion < now() - interval '32 days' 
        )
        INSERT INTO migracion.migra_transacciones_personas SELECT * FROM new_transacciones_personas;

        SELECT COUNT(*) - v_cantidad_registros INTO v_cantidad_registros FROM migracion.migra_transacciones_personas;

        -- Registro de log de migraciones
        INSERT INTO migracion.migra_log (nombre_tabla, registros_copiados, fecha_migracion)
        VALUES ('transacciones_personas', v_cantidad_registros, now());

    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Error migrando transacciones_personas: %', SQLERRM;
		ROLLBACK;
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
        RAISE WARNING 'Error migrando valorsubscripciones: %', SQLERRM;
		ROLLBACK;
    END;

	BEGIN

		DELETE FROM public.notificaciones_persona p WHERE p.notificacion_id IN (SELECT notificacion_id FROM migracion.migra_notificaciones_persona);
		DELETE FROM public.calificadores_descripcion cd WHERE cd.calificacion_id IN (SELECT calificacion_id FROM migracion.migra_calificadores_descripcion);
		DELETE FROM public.DescripcionesAlarmas da WHERE da.IdDescripcion IN (SELECT IdDescripcion FROM migracion.migra_DescripcionesAlarmas);
		DELETE FROM public.mensajes_a_usuarios p WHERE p.mensaje_id IN (SELECT mensaje_id FROM migracion.migra_mensajes_a_usuarios);
		DELETE FROM public.alarmas WHERE  alarma_id IN (SELECT alarma_id FROM migracion.migra_alarmas);
		DELETE FROM public.subscripciones p WHERE p.subscripcion_id IN (SELECT subscripcion_id FROM migracion.migra_subscripciones)	;
		DELETE FROM public.ubicaciones_testing p WHERE p.ubicacion_id IN (SELECT ubicacion_id FROM migracion.migra_ubicaciones_testing);
		DELETE FROM public.poderes_regalados p WHERE p.id_regalo IN (SELECT id_regalo FROM migracion.migra_poderes_regalados);
		DELETE FROM public.aceptacion_condiciones p WHERE p.aceptacion_id IN (SELECT aceptacion_id FROM migracion.migra_aceptacion_condiciones);
		DELETE FROM public.dispositivos p WHERE p.id_dispositivo IN (SELECT id_dispositivo FROM migracion.migra_dispositivos);
		DELETE FROM public.permisos_pendientes_protegidos p WHERE p.permiso_pendiente_id IN (SELECT permiso_pendiente_id FROM migracion.migra_permisos_pendientes_protegidos); 
		DELETE FROM public.transacciones_personas p WHERE p.transaccion_id IN (SELECT transaccion_id FROM migracion.migra_transacciones_personas);

	END;

	--Guarda todo finalmente:
	COMMIT;

END;
$BODY$;
ALTER PROCEDURE migracion.migrar_datos()
    OWNER TO w4ll4c3;
