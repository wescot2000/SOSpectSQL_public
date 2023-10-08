-- PROCEDURE: public.cierrealarma(bigint, character varying, character varying, boolean, boolean, character varying)

-- DROP PROCEDURE IF EXISTS public.cierrealarma(bigint, character varying, character varying, boolean, boolean, character varying);

CREATE OR REPLACE PROCEDURE public.cierrealarma(
	IN p_alarma_id bigint,
	IN p_user_id_thirdparty character varying,
	IN p_descripcion_cierre character varying,
	IN p_flag_es_falsaalarma boolean,
	IN p_flag_hubo_captura boolean,
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
	v_texto_prefijo VARCHAR(100);
	v_flag_es_policia boolean;
	v_texto_mensajecredib VARCHAR(100);
	v_cantidad_agentes_atendiendo integer;
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

		IF v_estado_alarma = 'C' then
			RAISE EXCEPTION 'Denied, alarm already closed';	
		END IF;	

		select count(*) 
		into v_cantidad_agentes_atendiendo 
		from atencion_policiaca ap 
		where ap.alarma_id=p_alarma_id;

		SELECT 
			p.persona_id
			,u.latitud
			,u.longitud
			,ceiling(ABS((((v_latitud_alarma-u.latitud)+(v_longitud_alarma-u.longitud)*100)/0.000900))) as distancia_en_metros
			,case when p.flag_es_policia is true then cast('Authority ID: '||coalesce(p.numeroplaca,' unspecified')||':' as varchar(100)) else cast ('' as varchar(100)) end as texto_prefijo
			,p.flag_es_policia
		INTO 
			v_persona_id
			,v_latitud_originador
			,v_longitud_originador
			,v_distancia_alarma_originador
			,v_texto_prefijo
			,v_flag_es_policia
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

		IF v_persona_id <>  v_persona_id_creador and v_flag_es_policia is false then
			RAISE EXCEPTION 'Denied, only alarm creator can close it';	
		END IF;	

		IF v_cantidad_agentes_atendiendo > 0 and v_flag_es_policia is false then
			RAISE EXCEPTION 'Access denied. An officer from the authorities is responding to the alarm.';	
		END IF;	

		IF v_flag_es_policia is true and p_flag_es_falsaalarma is true then

			update
				alarmas
			set
				calificacion_alarma=40
			where 
                estado_alarma IS NULL
			AND
				alarma_id=p_alarma_id;

		END IF;	

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
				a.alarma_id=p_alarma_id
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
				a.alarma_id=p_alarma_id
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
				a.alarma_id=p_alarma_id
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
			AND
				al.alarma_id=p_alarma_id
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
			case when v_flag_es_policia is true and p_flag_es_falsaalarma is true then
				CONCAT('Tu nivel de credibilidad ahora es ', p.credibilidad_persona, ' ya que la autoridad competente indica que tu alarma era falsa.')
			else CONCAT('Tu nivel de credibilidad ha sido actualizado a ', p.credibilidad_persona, ' debido al cierre de alarma realizado recientemente.') end
			,
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

			UPDATE alarmas 
			SET estado_alarma='C'
			WHERE alarma_id IN (SELECT alarma_id FROM CTE_Result)
			AND estado_alarma IS NULL;

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
					,flag_es_cierre_alarma
					,flag_hubo_captura
				)
		VALUES
			(
				v_persona_id
				,p_alarma_id
				,v_texto_prefijo||' '||coalesce(p_descripcion_cierre,'No closure description')
				,now()
				,v_latitud_originador
				,v_longitud_originador
				,v_distancia_alarma_originador
				,case when p_descripcion_cierre is null then cast('en' as varchar(10)) else p_idioma end
				,cast(true as boolean)
				,p_flag_hubo_captura
			);	
			
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.cierrealarma(bigint, character varying, character varying, boolean, boolean, character varying)
    OWNER TO w4ll4c3;
