-- PROCEDURE: public.cierrevotacionesalarmas()

CREATE OR REPLACE PROCEDURE public.cierrevotacionesalarmas()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
    p_persona_id BIGINT;
BEGIN
    BEGIN
        -- Primero, obtenemos las personas que votaron incorrectamente EN ALARMAS ACTIVAS NO EVALUADAS
        -- EXCLUIMOS alarmas promocionales (is_advertising = TRUE) ya que no tienen votaciones
        WITH incorrect_voters AS (
            SELECT
                da.persona_id
            FROM
                descripcionesalarmas da
            INNER JOIN
                alarmas a ON a.alarma_id = da.alarma_id
            INNER JOIN
                tipoalarma ta ON a.tipoalarma_id = ta.tipoalarma_id
            WHERE
                (
                    (a.calificacion_alarma >= 50 AND da.veracidadalarma = FALSE)
                    OR
                    (a.calificacion_alarma < 50 AND da.veracidadalarma = TRUE)
                )
            AND
                a.estado_alarma IS NULL    -- Solo alarmas activas (lógica original)
            AND
                a.evaluada = FALSE         -- Solo alarmas no evaluadas
            AND
                COALESCE(ta.is_advertising, FALSE) = FALSE  -- Excluir alarmas promocionales
            AND
                (SELECT COUNT(*) FROM descripcionesalarmas da2 WHERE da2.alarma_id = da.alarma_id AND da2.veracidadalarma IS NOT NULL) > 2
        ),

        incorrect_voters2 AS (
            SELECT
                da.persona_id,
                COUNT(*) as incorrect_votes_count
            FROM
                descripcionesalarmas da
            INNER JOIN
                alarmas a ON a.alarma_id = da.alarma_id
            INNER JOIN
                tipoalarma ta ON a.tipoalarma_id = ta.tipoalarma_id
            WHERE
                (
                    (a.calificacion_alarma >= 50 AND da.veracidadalarma = FALSE)
                    OR
                    (a.calificacion_alarma < 50 AND da.veracidadalarma = TRUE)
                )
            AND
                a.estado_alarma IS NULL    -- Solo alarmas activas (lógica original)
            AND
                a.evaluada = FALSE         -- Solo alarmas no evaluadas
            AND
                COALESCE(ta.is_advertising, FALSE) = FALSE  -- Excluir alarmas promocionales
            AND
                (SELECT COUNT(*) FROM descripcionesalarmas da2 WHERE da2.alarma_id = da.alarma_id AND da2.veracidadalarma IS NOT NULL) > 2
            GROUP BY
                da.persona_id
        ),

        -- Aquí, actualizamos la marca de bloqueo de las personas que votaron incorrectamente
        blocking_mark_update AS (
            UPDATE 
                personas p
            SET 
                marca_bloqueo = p.marca_bloqueo + 1,
                fecha_ultima_marca_bloqueo = now()
            FROM 
                incorrect_voters iv
            WHERE 
                p.persona_id = iv.persona_id
            RETURNING 
                p.*
        ),
        
        -- Luego, enviamos un mensaje a estas personas sobre la marca de bloqueo
        blocking_mark_message AS (
            INSERT INTO mensajes_a_usuarios (
                persona_id,
                texto,
                fecha_mensaje,
                estado,
                asunto,
                idioma_origen
            )
            SELECT 
                persona_id,
                'Has recibido una marca negativa debido a una alarma reciente que la mayoría de la comunidad calificó contrario a lo que indicaste',
                now(),
                cast(True as boolean),
                'Ten cuidado! Recibiste marca negativa',
                'es'
            FROM blocking_mark_update
        ),

        -- Luego, reducimos la credibilidad de estas personas
        -- EXCLUIMOS alarmas promocionales del cálculo de credibilidad
        credibility_update AS (
            UPDATE
                personas p
            SET
                credibilidad_persona = GREATEST(0, LEAST(100, (p.credibilidad_persona +
                    (SELECT AVG(COALESCE(a.calificacion_alarma, 100.00))
                    FROM alarmas a
                    INNER JOIN tipoalarma ta ON a.tipoalarma_id = ta.tipoalarma_id
                    WHERE a.estado_alarma IS NULL
                    AND a.evaluada = FALSE
                    AND a.persona_id = p.persona_id
                    AND COALESCE(ta.is_advertising, FALSE) = FALSE
                    AND NOT EXISTS (SELECT 1 FROM incorrect_voters iv WHERE iv.persona_id = p.persona_id)
                    AND (SELECT COUNT(*) FROM descripcionesalarmas da3 WHERE da3.alarma_id = a.alarma_id AND da3.veracidadalarma IS NOT NULL) > 2
                    ))/2))
            FROM
                incorrect_voters iv
            WHERE
                p.persona_id = iv.persona_id
            RETURNING
                p.*
        ),

        -- Ahora, obtenemos las personas que votaron correctamente EN ALARMAS ACTIVAS NO EVALUADAS
        -- EXCLUIMOS alarmas promocionales (is_advertising = TRUE) ya que no tienen votaciones
        correct_voters AS (
            SELECT
                da.persona_id,
                COUNT(*) as correct_votes_count
            FROM
                descripcionesalarmas da
            INNER JOIN
                alarmas a ON a.alarma_id = da.alarma_id
            INNER JOIN
                tipoalarma ta ON a.tipoalarma_id = ta.tipoalarma_id
            WHERE
                (
                    (a.calificacion_alarma >= 50 AND da.veracidadalarma = TRUE)
                    OR
                    (a.calificacion_alarma < 50 AND da.veracidadalarma = FALSE)
                )
            AND
                a.estado_alarma IS NULL    -- Solo alarmas activas (lógica original)
            AND
                a.evaluada = FALSE         -- Solo alarmas no evaluadas
            AND
                COALESCE(ta.is_advertising, FALSE) = FALSE  -- Excluir alarmas promocionales
            AND
                (SELECT COUNT(*) FROM descripcionesalarmas da2 WHERE da2.alarma_id = da.alarma_id AND da2.veracidadalarma IS NOT NULL) > 2
            GROUP BY
                da.persona_id
        ),

        -- Luego, aumentamos el saldo de poderes de estas personas
        power_balance_update AS (
            UPDATE 
                personas p
            SET 
                saldo_poderes = p.saldo_poderes + cv.correct_votes_count
            FROM 
                correct_voters cv
            WHERE 
                p.persona_id = cv.persona_id
            RETURNING 
                p.*, cv.correct_votes_count
        ),

        -- Registramos los poderes regalados
        power_gifts AS (
            INSERT INTO poderes_regalados (
                persona_id,
                cantidad_poderes_regalada,
                fecha_regalo,
                calificaciones_negativas,
                promedio_veracidad
            )
            SELECT 
                pbu.persona_id,
                pbu.correct_votes_count,
                now(),
                COALESCE(iv2.incorrect_votes_count, 0),
                CASE 
                    WHEN COALESCE(iv2.incorrect_votes_count, 0) = 0 THEN 1
                    ELSE pbu.correct_votes_count::numeric / (pbu.correct_votes_count + COALESCE(iv2.incorrect_votes_count, 0))
                END
            FROM power_balance_update pbu
            LEFT JOIN incorrect_voters2 iv2 ON pbu.persona_id = iv2.persona_id
            RETURNING 
                *
        ),

        -- Mensaje de felicitación por poderes ganados
        power_message AS (
            INSERT INTO mensajes_a_usuarios (
                persona_id,
                texto,
                fecha_mensaje,
                estado,
                asunto,
                idioma_origen
            )
            SELECT 
                persona_id,
                'Por calificar correctamente alarmas recientes, has ganado poderes',
                now(),
                cast(True as boolean),
                'Felicitaciones! Ganaste poderes por tu honestidad',
                'es'
            FROM power_balance_update
        ),

        -- Análisis de alarmas por usuario (SOLO ALARMAS ACTIVAS NO EVALUADAS)
        -- EXCLUIMOS alarmas promocionales (is_advertising = TRUE) ya que no tienen votaciones
        alarmas_por_usuario AS (
            SELECT
                al.persona_id,
                COUNT(CASE WHEN al.calificacion_alarma < 50 THEN 1 END) as alarmas_falsas,
                COUNT(CASE WHEN al.calificacion_alarma >= 50 THEN 1 END) as alarmas_verdaderas
            FROM
                alarmas al
            INNER JOIN
                tipoalarma ta ON al.tipoalarma_id = ta.tipoalarma_id
            WHERE
                al.estado_alarma IS NULL    -- Solo alarmas activas (lógica original)
            AND
                al.evaluada = FALSE         -- Solo alarmas no evaluadas
            AND
                al.calificacion_alarma IS NOT NULL
            AND
                COALESCE(ta.is_advertising, FALSE) = FALSE  -- Excluir alarmas promocionales
            AND
                (
                    SELECT COUNT(*)
                    FROM descripcionesalarmas da
                    WHERE da.alarma_id = al.alarma_id
                    AND da.veracidadalarma IS NOT NULL
                ) > 2
            GROUP BY
                al.persona_id
        ),

        -- Aquí, actualizamos la credibilidad de cada usuario basándonos en las alarmas que reportaron
        update_credibilidad AS (
            UPDATE 
                personas p
            SET 
                credibilidad_persona = GREATEST(0, LEAST(100, p.credibilidad_persona - apu.alarmas_falsas + apu.alarmas_verdaderas))
            FROM 
                alarmas_por_usuario apu
            WHERE 
                p.persona_id = apu.persona_id
            RETURNING 
                p.*
        ),

        -- Mensaje de actualización de credibilidad
        credibility_message AS (
            INSERT INTO mensajes_a_usuarios (
                persona_id,
                texto,
                fecha_mensaje,
                estado,
                asunto,
                idioma_origen
            )
            SELECT 
                p.persona_id,
                CONCAT('Tu nivel de credibilidad ha sido actualizado a ', p.credibilidad_persona, ' debido al cierre de votaciones de alarmas que colocaste recientemente.'),
                now(),
                cast(True as boolean),
                'Actualización de la credibilidad',
                'es'
            FROM update_credibilidad p
        )

        -- Marcar las alarmas activas como evaluadas para evitar re-procesamiento
        -- EXCLUIMOS alarmas promocionales (is_advertising = TRUE) ya que nunca deben marcarse como evaluadas
        UPDATE
            alarmas a
        SET
            evaluada = TRUE
        FROM
            tipoalarma ta
        WHERE
            a.tipoalarma_id = ta.tipoalarma_id
        AND
            a.estado_alarma IS NULL      -- Solo alarmas activas
        AND
            a.evaluada = FALSE           -- Solo las no evaluadas
        AND
            a.calificacion_alarma IS NOT NULL
        AND
            COALESCE(ta.is_advertising, FALSE) = FALSE  -- Excluir alarmas promocionales
        AND
            (
                SELECT COUNT(*)
                FROM descripcionesalarmas da
                WHERE da.alarma_id = a.alarma_id
                AND da.veracidadalarma IS NOT NULL
            ) > 2;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION 'Error en evaluación de alarmas: %', sqlerrm;
    END;

    BEGIN
        -- Cerrar alarmas que han cumplido su tiempo de vigencia según tipo de alarma
        -- Solo para alarmas con minutos_vigencia definido (no NULL)
        UPDATE
            alarmas a
        SET
            estado_alarma = 'C'
        FROM
            tipoalarma ta
        WHERE
            a.tipoalarma_id = ta.tipoalarma_id
            AND ta.minutos_vigencia IS NOT NULL
            AND a.fecha_alarma < now() - (ta.minutos_vigencia || ' minutes')::interval
            AND a.estado_alarma IS NULL;

        -- Registrar cierre en descripcionesalarmas para alarmas de SEGURIDAD (1) y POLITICA (2)
        -- cerradas por vencimiento de minutos_vigencia, para poder calcular avg_dias_resolucion.
        -- Usa el persona_id del creador de la alarma. Sin descripción (cierre automático).
        -- NOT EXISTS evita duplicados si ya tiene un registro de cierre previo.
        -- MODIFICADO: 2026-03-10
        INSERT INTO public.descripcionesalarmas (
            persona_id,
            alarma_id,
            descripcionalarma,
            fechadescripcion,
            flag_es_cierre_alarma,
            flag_hubo_captura,
            flag_persona_encontrada,
            flag_mascota_recuperada
        )
        SELECT
            a.persona_id,
            a.alarma_id,
            '',
            now(),
            TRUE,
            FALSE,
            FALSE,
            FALSE
        FROM public.alarmas a
        JOIN public.tipoalarma ta ON ta.tipoalarma_id = a.tipoalarma_id
        WHERE a.estado_alarma = 'C'
          AND ta.minutos_vigencia IS NOT NULL
          AND a.fecha_alarma < now() - (ta.minutos_vigencia || ' minutes')::interval
          AND ta.categoria_alarma_id IN (1, 2)
          AND NOT EXISTS (
              SELECT 1 FROM public.descripcionesalarmas d
              WHERE d.alarma_id = a.alarma_id AND d.flag_es_cierre_alarma = TRUE
          );

        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION 'Error al cerrar alarmas por minutos_vigencia: %', sqlerrm;
    END;

    BEGIN
        -- Cerrar alarmas promocionales que han cumplido su fecha_finalizacion
        -- Las promociones se identifican por tiposubscripcion.descripcion_tipo = 'Anuncio publicitario de usuarios'
        -- y se cierran cuando NOW() > fecha_finalizacion de la subscripción
        UPDATE
            alarmas a
        SET
            estado_alarma = 'C'
        FROM
            subscripciones s
            INNER JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
        WHERE
            s.alarma_id = a.alarma_id
            AND s.persona_id = a.persona_id
            AND ts.descripcion_tipo = 'Anuncio publicitario de usuarios'
            AND NOW() > s.fecha_finalizacion
            AND a.estado_alarma IS NULL;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION 'Error al cerrar alarmas promocionales: %', sqlerrm;
    END;
        
END
$BODY$;
