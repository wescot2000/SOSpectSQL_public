-- FUNCTION: public.consulta_msgs_alarmas(character varying, bigint)
-- Rediseño 2026-02-08: Enriquecer mensajes con metadata de la alarma (tipo, descripción, foto, distancia, logo)

-- DROP FUNCTION IF EXISTS public.consulta_msgs_alarmas(character varying, bigint);

CREATE OR REPLACE FUNCTION public.consulta_msgs_alarmas(
	p_user_id_thirdparty character varying,
	p_alarma_id bigint)
    RETURNS TABLE(
        persona_id bigint,
        texto character varying,
        fecha_mensaje timestamp with time zone,
        estado boolean,
        asunto character varying,
        idioma_origen character varying,
        alarma_id bigint,
        tipoalarma_id integer,
        descripcion_alarma character varying,
        url_foto character varying,
        distancia_metros integer,
        url_logo character varying
    )
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

DECLARE
    v_tipoalarma_id integer;
    v_short_alias varchar(50);
    v_descripcion_alarma varchar(500);
    v_url_foto varchar(500);
    v_url_logo varchar(500);
BEGIN

    -- Obtener metadata de la alarma: tipo, descripción inicial, primera foto, logo
    SELECT
        al.tipoalarma_id,
        ta.short_alias,
        da.descripcionalarma,
        pf.url_foto,
        CASE WHEN al.tipoalarma_id = 13 THEN e.url_logo ELSE NULL END
    INTO
        v_tipoalarma_id,
        v_short_alias,
        v_descripcion_alarma,
        v_url_foto,
        v_url_logo
    FROM alarmas al
    JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
    LEFT JOIN LATERAL (
        SELECT da2.descripcionalarma
        FROM descripcionesalarmas da2
        WHERE da2.alarma_id = al.alarma_id
        ORDER BY da2.fechadescripcion ASC
        LIMIT 1
    ) da ON true
    LEFT JOIN LATERAL (
        SELECT f.url_foto
        FROM descripcionesalarmas da3
        JOIN fotos_descripciones_alarmas f ON f.iddescripcion = da3.iddescripcion
        WHERE da3.alarma_id = al.alarma_id
          AND f.estado = 'A'
          AND f.es_video = false
        ORDER BY da3.fechadescripcion ASC, f.orden ASC, f.fecha_subida ASC
        LIMIT 1
    ) pf ON true
    LEFT JOIN subscripciones s ON s.alarma_id = al.alarma_id AND s.tipo_subscr_id = 4
    LEFT JOIN emprendimientos e ON s.id_emprendimiento = e.id_emprendimiento AND e.fecha_fin IS NULL
    WHERE al.alarma_id = p_alarma_id;

    -- Mensajes para usuarios cercanos
    RETURN QUERY
    SELECT
        cast(deriv.persona_id as bigint) as persona_id,
        cast(
            CASE
                WHEN v_descripcion_alarma IS NOT NULL AND trim(v_descripcion_alarma) <> ''
                    THEN v_descripcion_alarma
                ELSE 'Recibiste recientemente una alerta cerca de ti, puedes verla aquí: '
            END as varchar(500)
        ) as texto,
        cast(now() as timestamp with time zone) as fecha_mensaje,
        cast(True as boolean) as estado,
        cast(
            CASE
                WHEN v_tipoalarma_id = 13
                    THEN 'Promoción: ' || LEFT(COALESCE(v_descripcion_alarma, v_short_alias), 80)
                ELSE COALESCE(v_short_alias, 'Alerta') || ' a ' || deriv.distancia_en_metros || 'm de ti'
            END as varchar(500)
        ) as asunto,
        cast('es' as varchar(10)) as idioma_origen,
        cast(deriv.alarma_id as bigint) as alarma_id,
        v_tipoalarma_id as tipoalarma_id,
        cast(v_descripcion_alarma as varchar(500)) as descripcion_alarma,
        cast(v_url_foto as varchar(500)) as url_foto,
        cast(deriv.distancia_en_metros as integer) as distancia_metros,
        cast(v_url_logo as varchar(500)) as url_logo
    FROM (
        SELECT v.persona_id,
            v.alarma_id,
            MIN(v.distancia_en_metros) as distancia_en_metros
        FROM vw_notificacion_alarmas v
        LEFT OUTER JOIN mensajes_a_usuarios m
            ON (v.persona_id = m.persona_id AND v.alarma_id = m.alarma_id)
        WHERE v.user_id_thirdparty = p_user_id_thirdparty
            AND v.user_id_thirdparty = v.user_id_creador_alarma
            AND m.mensaje_id IS NULL
            AND v.alarma_id = p_alarma_id
        GROUP BY v.persona_id, v.alarma_id
    ) as deriv

    UNION

    -- Mensajes para protegidos
    SELECT
        cast(deriv.persona_id as bigint) as persona_id,
        cast(
            CASE
                WHEN v_descripcion_alarma IS NOT NULL AND trim(v_descripcion_alarma) <> ''
                    THEN 'URGENTE: Tu protegido colocó una alerta: ' || v_descripcion_alarma
                ELSE 'URGENTE: Tu protegido colocó una alerta, puedes verla aquí: '
            END as varchar(500)
        ) as texto,
        cast(now() as timestamp with time zone) as fecha_mensaje,
        cast(True as boolean) as estado,
        cast('URGENTE: Tu protegido lanzó alarma de ' || COALESCE(v_short_alias, 'Alerta') as varchar(500)) as asunto,
        cast('es' as varchar(10)) as idioma_origen,
        cast(deriv.alarma_id as bigint) as alarma_id,
        v_tipoalarma_id as tipoalarma_id,
        cast(v_descripcion_alarma as varchar(500)) as descripcion_alarma,
        cast(v_url_foto as varchar(500)) as url_foto,
        cast(deriv.distancia_en_metros as integer) as distancia_metros,
        cast(v_url_logo as varchar(500)) as url_logo
    FROM (
        SELECT rp.id_persona_protector as persona_id,
            v.alarma_id,
            MIN(v.distancia_en_metros) as distancia_en_metros
        FROM vw_notificacion_alarmas v
        INNER JOIN personas p
            ON (p.user_id_thirdparty = v.user_id_creador_alarma)
        INNER JOIN relacion_protegidos rp
            ON (rp.id_persona_protegida = p.persona_id AND now() BETWEEN fecha_activacion AND fecha_finalizacion)
        LEFT OUTER JOIN mensajes_a_usuarios m
            ON (v.persona_id = m.persona_id AND v.alarma_id = m.alarma_id)
        LEFT OUTER JOIN mensajes_a_usuarios m2
            ON (rp.id_persona_protector = m2.persona_id AND v.alarma_id = m2.alarma_id)
        WHERE v.user_id_creador_alarma = p_user_id_thirdparty
            AND v.user_id_thirdparty <> v.user_id_creador_alarma
            AND m.mensaje_id IS NULL
            AND m2.mensaje_id IS NULL
            AND v.alarma_id = p_alarma_id
        GROUP BY rp.id_persona_protector, v.alarma_id
    ) as deriv
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12;
END;
$BODY$;

