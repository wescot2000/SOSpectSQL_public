-- PROCEDURE: public.cierrevotacionesalarmas()

-- DROP PROCEDURE IF EXISTS public.cierrevotacionesalarmas();

CREATE OR REPLACE PROCEDURE public.cierrevotacionesalarmas(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
    p_persona_id BIGINT;
BEGIN
    BEGIN
        -- Primero, obtenemos las personas que votaron incorrectamente
        WITH incorrect_voters AS (
            SELECT 
                da.persona_id
            FROM 
                descripcionesalarmas da
            INNER JOIN 
                alarmas a ON a.alarma_id = da.alarma_id
            WHERE
                (
                    (a.calificacion_alarma >= 50 AND da.veracidadalarma = FALSE)
                    OR 
                    (a.calificacion_alarma < 50 AND da.veracidadalarma = TRUE)
                )
            AND 
                a.estado_alarma IS NULL
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
			WHERE
				(
					(a.calificacion_alarma >= 50 AND da.veracidadalarma = FALSE)
					OR 
					(a.calificacion_alarma < 50 AND da.veracidadalarma = TRUE)
				)
			AND 
				a.estado_alarma IS NULL
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
		/*AND
			(
				p.fecha_ultima_marca_bloqueo IS NULL
				OR
				p.fecha_ultima_marca_bloqueo < now() - interval '1 day'
			)*/
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
        credibility_update AS (
			UPDATE 
				personas p
			SET 
				credibilidad_persona = GREATEST(0, LEAST(100, (p.credibilidad_persona + 
					(SELECT AVG(COALESCE(a.calificacion_alarma, 100.00)) 
					FROM alarmas a 
					WHERE a.estado_alarma IS NULL 
					and a.persona_id = p.persona_id 
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

        -- Ahora, obtenemos las personas que votaron correctamente
        correct_voters AS (
			SELECT 
				da.persona_id,
				COUNT(*) as correct_votes_count
			FROM 
				descripcionesalarmas da
			INNER JOIN 
				alarmas a ON a.alarma_id = da.alarma_id
			WHERE
				(
					(a.calificacion_alarma >= 50 AND da.veracidadalarma = TRUE)
					OR 
					(a.calificacion_alarma < 50 AND da.veracidadalarma = FALSE)
				)
			AND 
				a.estado_alarma IS NULL
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
            iv2.incorrect_votes_count,
            CASE 
                WHEN iv2.incorrect_votes_count = 0 THEN 1
                ELSE pbu.correct_votes_count::numeric / (pbu.correct_votes_count + iv2.incorrect_votes_count)
            END
		FROM power_balance_update pbu
        LEFT JOIN incorrect_voters2 iv2 ON pbu.persona_id = iv2.persona_id
		RETURNING 
			*
		)

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
        FROM power_balance_update;

		WITH alarmas_por_usuario AS (
			SELECT 
				al.persona_id, 
				COUNT(CASE WHEN al.calificacion_alarma < 50 THEN 1 END) as alarmas_falsas,
				COUNT(CASE WHEN al.calificacion_alarma >= 50 THEN 1 END) as alarmas_verdaderas
			FROM 
				alarmas al
			WHERE
				al.estado_alarma IS NULL
			and 
				al.calificacion_alarma is not null
			and 
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
		)

        -- Finalmente, les enviamos un mensaje a estas personas
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
		FROM update_credibilidad p;
		        
        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION '%', sqlerrm;
    END;

    BEGIN
        UPDATE 
            alarmas
        SET 
            estado_alarma='C'
        WHERE 
            fecha_alarma< now()- interval '90 minutes'
        AND 
            estado_alarma IS NULL;
        
        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION '%', sqlerrm;
    END;
        
END
$BODY$;
ALTER PROCEDURE public.cierrevotacionesalarmas()
    OWNER TO w4ll4c3;
