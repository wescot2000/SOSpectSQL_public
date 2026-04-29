-- PROCEDURE: public.corregirsubscripcioneshuerfanas()

-- DROP PROCEDURE IF EXISTS public.corregirsubscripcioneshuerfanas();

CREATE OR REPLACE PROCEDURE public.corregirsubscripcioneshuerfanas()
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
    v_registros_subscripciones_corregidos INTEGER := 0;
    v_registros_permisos_corregidos INTEGER := 0;
    v_fecha_ejecucion TIMESTAMP := NOW();
    v_mensaje_observaciones VARCHAR(500);
    v_tipo_subscr_id INTEGER := 3; -- Tipo de subscripción protegido
    rec RECORD;
BEGIN
    BEGIN
        -- Log de inicio
        RAISE NOTICE '=================================================================';
        RAISE NOTICE 'Iniciando corrección de subscripciones huérfanas: %', v_fecha_ejecucion;
        RAISE NOTICE '=================================================================';

        -- ======================================================================
        -- PARTE 1: Corregir registros de SUBSCRIPCIONES faltantes
        -- ======================================================================
        RAISE NOTICE '';
        RAISE NOTICE 'PARTE 1: Verificando subscripciones huérfanas...';

        FOR rec IN (
            SELECT
                rp.id_rel_protegido,
                rp.id_persona_protector,
                rp.id_persona_protegida,
                rp.tiporelacion_id,
                rp.fecha_activacion,
                rp.fecha_finalizacion,
                rp.poderes_consumidos,
                p_protector.user_id_thirdparty AS user_id_protector,
                p_protector.login AS login_protector,
                p_protegido.user_id_thirdparty AS user_id_protegido,
                p_protegido.login AS login_protegido
            FROM
                relacion_protegidos rp
            LEFT JOIN
                subscripciones s ON s.id_rel_protegido = rp.id_rel_protegido AND s.tipo_subscr_id = 3
            INNER JOIN
                personas p_protector ON p_protector.persona_id = rp.id_persona_protector
            INNER JOIN
                personas p_protegido ON p_protegido.persona_id = rp.id_persona_protegida
            WHERE
                s.id_rel_protegido IS NULL  -- No existe la subscripción
            ORDER BY
                rp.id_rel_protegido
        )
        LOOP
            -- Preparar mensaje de observaciones con timestamp
            v_mensaje_observaciones := 'Registro de corrección insertado por script en fecha: ' ||
                                       TO_CHAR(v_fecha_ejecucion, 'YYYY-MM-DD HH24:MI:SS') ||
                                       '. Relación: ' || rec.login_protector || ' -> ' || rec.login_protegido;

            -- Insertar el registro faltante en subscripciones
            INSERT INTO subscripciones
                (
                    persona_id,
                    tipo_subscr_id,
                    fecha_activacion,
                    fecha_finalizacion,
                    poderes_consumidos,
                    id_rel_protegido,
                    cantidad_protegidos_adquirida,
                    observaciones
                )
            VALUES
                (
                    rec.id_persona_protector,
                    v_tipo_subscr_id,
                    rec.fecha_activacion,
                    rec.fecha_finalizacion,
                    rec.poderes_consumidos,
                    rec.id_rel_protegido,
                    1,  -- Cantidad fija según el procedimiento original
                    v_mensaje_observaciones
                );

            -- Incrementar contador
            v_registros_subscripciones_corregidos := v_registros_subscripciones_corregidos + 1;

            -- Log detallado de cada corrección
            RAISE NOTICE '  ✓ Subscripción corregida: id_rel_protegido=%, protector=%, protegido=%',
                         rec.id_rel_protegido, rec.login_protector, rec.login_protegido;
        END LOOP;

        IF v_registros_subscripciones_corregidos = 0 THEN
            RAISE NOTICE '  ✓ No se encontraron subscripciones huérfanas.';
        END IF;

        -- ======================================================================
        -- PARTE 2: Corregir registros de PERMISOS faltantes
        -- ======================================================================
        RAISE NOTICE '';
        RAISE NOTICE 'PARTE 2: Verificando permisos pendientes huérfanos...';

        FOR rec IN (
            SELECT
                rp.id_rel_protegido,
                rp.id_persona_protector,
                rp.id_persona_protegida,
                rp.tiporelacion_id,
                rp.fecha_activacion,
                p_protector.user_id_thirdparty AS user_id_protector,
                p_protector.login AS login_protector,
                p_protegido.user_id_thirdparty AS user_id_protegido,
                p_protegido.login AS login_protegido,
                -- Calcular tiempo de subscripción en días
                EXTRACT(DAY FROM (COALESCE(rp.fecha_finalizacion, NOW()) - rp.fecha_activacion))::INTEGER AS tiempo_dias
            FROM
                relacion_protegidos rp
            INNER JOIN
                subscripciones s ON s.id_rel_protegido = rp.id_rel_protegido
            INNER JOIN
                personas p_protector ON p_protector.persona_id = rp.id_persona_protector
            INNER JOIN
                personas p_protegido ON p_protegido.persona_id = rp.id_persona_protegida
            LEFT JOIN
                permisos_pendientes_protegidos ppp ON ppp.persona_id_protector = rp.id_persona_protector
                                                   AND ppp.persona_id_protegido = rp.id_persona_protegida
                                                   AND ppp.flag_aprobado IS TRUE
                                                   AND ppp.fecha_aprobado IS NOT NULL
            WHERE
                -- Relación activa
                now() >= rp.fecha_activacion
                AND now() <= COALESCE(rp.fecha_finalizacion, now())
                -- Subscripción activa
                AND now() >= s.fecha_activacion
                AND now() <= COALESCE(s.fecha_finalizacion, now())
                -- Pero NO tiene permiso aprobado
                AND ppp.permiso_pendiente_id IS NULL
            ORDER BY
                rp.id_rel_protegido
        )
        LOOP
            -- Insertar el permiso faltante (ya aprobado)
            INSERT INTO permisos_pendientes_protegidos
                (
                    persona_id_protector,
                    persona_id_protegido,
                    tiempo_subscripcion_dias,
                    fecha_solicitud,
                    flag_aprobado,
                    fecha_aprobado,
                    tiporelacion_id
                )
            VALUES
                (
                    rec.id_persona_protector,
                    rec.id_persona_protegida,
                    rec.tiempo_dias,
                    rec.fecha_activacion,  -- Fecha de solicitud = fecha de activación
                    TRUE,                   -- Ya está aprobado
                    rec.fecha_activacion,  -- Fecha de aprobación = fecha de activación
                    rec.tiporelacion_id
                );

            -- Incrementar contador
            v_registros_permisos_corregidos := v_registros_permisos_corregidos + 1;

            -- Log detallado de cada corrección
            RAISE NOTICE '  ✓ Permiso corregido: id_rel_protegido=%, protector=%, protegido=%',
                         rec.id_rel_protegido, rec.login_protector, rec.login_protegido;
        END LOOP;

        IF v_registros_permisos_corregidos = 0 THEN
            RAISE NOTICE '  ✓ No se encontraron permisos huérfanos.';
        END IF;

        -- Log final con resumen
        RAISE NOTICE '';
        RAISE NOTICE '=================================================================';
        RAISE NOTICE 'RESUMEN DE CORRECCIONES:';
        RAISE NOTICE '  - Subscripciones corregidas: %', v_registros_subscripciones_corregidos;
        RAISE NOTICE '  - Permisos corregidos: %', v_registros_permisos_corregidos;
        RAISE NOTICE '  - Total registros corregidos: %', v_registros_subscripciones_corregidos + v_registros_permisos_corregidos;
        RAISE NOTICE 'Fecha ejecución: %', v_fecha_ejecucion;
        RAISE NOTICE '=================================================================';

        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION 'Error en corrección: % - %', SQLSTATE, sqlerrm;
    END;
END
$BODY$;
