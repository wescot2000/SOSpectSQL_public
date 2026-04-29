-- FUNCTION: public.funcinsertaalarmaynotifica(character varying, integer, numeric, numeric, character varying, bigint)

-- DROP FUNCTION IF EXISTS public.funcinsertaalarmaynotifica(character varying, integer, numeric, numeric, character varying, bigint);

CREATE OR REPLACE FUNCTION public.funcinsertaalarmaynotifica(
    p_user_id_thirdparty character varying,
    p_tipoalarma_id integer,
    p_latitud numeric,
    p_longitud numeric,
    p_ipusuario character varying,
    p_alarma_id bigint,
    p_DescripcionInicial character varying,
    p_idioma character varying,
    p_fotos_json jsonb DEFAULT NULL)
    RETURNS TABLE(user_id_thirdparty character varying, persona_id bigint, alarma_id bigint, latitud_alarma numeric, longitud_alarma numeric, txt_notif character varying, idioma_destino character varying, registrationid character varying, url_logo_emprendimiento character varying, url_primera_foto_promo character varying)
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
    p_persona_id BIGINT;
    v_latitud_originador numeric(9,6);
    v_longitud_originador numeric(9,6);
    v_distancia_alarma_originador numeric(9,2);
    v_credibilidad_persona numeric(5,2);
    v_row RECORD;
    v_alarma_id BIGINT;
    v_iddescripcion BIGINT;
BEGIN
    -- Insertar Alarma
    SELECT 
        p.persona_id, 
        u.latitud, 
        u.longitud, 
        ceiling(ABS((((p_latitud-u.latitud)+(p_longitud-u.longitud)*100)/0.000900))) as distancia_en_metros, 
        credibilidad_persona
    INTO 
        p_persona_id,
        v_latitud_originador,
        v_longitud_originador,
        v_distancia_alarma_originador,
        v_credibilidad_persona
    FROM 
        personas p
    LEFT OUTER JOIN 
        ubicaciones u ON (p.persona_id=u.persona_id AND u."Tipo"='P')
    WHERE 
        p.user_id_thirdparty=p_user_id_thirdparty;

    INSERT INTO 
        alarmas 
            (
                persona_id, 
                tipoalarma_id, 
                fecha_alarma, 
                latitud, 
                longitud,
                latitud_originador,
                longitud_originador,
                ip_usuario_originador,
                distancia_alarma_originador,
                alarma_id_padre,
                calificacion_alarma 
            ) 
            VALUES 
            (
                p_persona_id,
                p_tipoalarma_id, 
                now(),
                p_latitud,
                p_longitud,
                v_latitud_originador,
                v_longitud_originador,
                p_IpUsuario,
                v_distancia_alarma_originador,
                p_alarma_id,
                v_credibilidad_persona
            )
        RETURNING alarmas.alarma_id INTO v_alarma_id; 

    IF p_DescripcionInicial IS NOT NULL AND trim(p_DescripcionInicial) <> '' THEN
        INSERT INTO
            descripcionesalarmas
                (
                    persona_id,
                    alarma_id,
                    DescripcionAlarma,
                    fechadescripcion,
                    latitud_originador,
                    longitud_originador,
                    ip_usuario_originador,
                    distancia_alarma_originador,
                    idioma_origen,
                    flag_es_cierre_alarma
                )
        VALUES
            (
                p_persona_id,
                v_alarma_id,
                LEFT(p_DescripcionInicial, 450),
                now(),
                v_latitud_originador,
                v_longitud_originador,
                p_IpUsuario,
                v_distancia_alarma_originador,
                p_idioma,
                cast(false as boolean)
            )
        RETURNING iddescripcion INTO v_iddescripcion;

        -- Insertar fotos si existen
        IF p_fotos_json IS NOT NULL THEN
            INSERT INTO fotos_descripciones_alarmas (
                iddescripcion,
                url_foto,
                nombre_archivo_original,
                tipo_mime,
                tamano_bytes,
                es_video,
                orden,
                bucket_s3
            )
            SELECT
                v_iddescripcion,
                (foto->>'url_foto')::varchar,
                (foto->>'nombre_archivo_original')::varchar,
                (foto->>'tipo_mime')::varchar,
                (foto->>'tamano_bytes')::bigint,
                (foto->>'es_video')::boolean,
                (foto->>'orden')::integer,
                'sospect-s3-data-bucket-prod'
            FROM jsonb_array_elements(p_fotos_json) AS foto;
        END IF;
    END IF;

    -- Insertar mensajes para usuarios basados en la función public.consulta_msgs_alarmas
    FOR v_row IN (
        SELECT
            v.user_id_thirdparty,
            v.persona_id,
            v.alarma_id,
            v.latitud_alarma,
            v.longitud_alarma,
            v.txt_notif,
            v.idioma_destino,
            v.registrationid,  -- Incluir el registrationid del dispositivo
            v.url_logo_emprendimiento,  -- Logo emprendimiento (alarmas promocionales) - 18-01-2026
            v.url_primera_foto_promo    -- Primera foto (alarmas promocionales o normales) - 18-01-2026
        FROM vw_notificacion_alarmas v
        WHERE v.latitud_alarma = p_latitud
        AND v.longitud_alarma = p_longitud
        AND v.user_id_creador_alarma = p_user_id_thirdparty
        AND v.tipoalarma_id = p_tipoalarma_id
    ) 
    LOOP
        user_id_thirdparty := v_row.user_id_thirdparty;
        persona_id := v_row.persona_id;
        alarma_id := v_row.alarma_id;
        latitud_alarma := v_row.latitud_alarma;
        longitud_alarma := v_row.longitud_alarma;
        txt_notif := v_row.txt_notif;
        idioma_destino := v_row.idioma_destino;
        registrationid := v_row.registrationid;
        url_logo_emprendimiento := v_row.url_logo_emprendimiento;
        url_primera_foto_promo := v_row.url_primera_foto_promo;

        RETURN NEXT; -- Esto retornará la fila al resultado de la función
        
        -- Insertar mensajes en mensajes_a_usuarios usando la función consulta_msgs_alarmas
        -- Rediseño 2026-02-08: Incluir metadata de la alarma (tipo, descripción, foto, distancia, logo)
        INSERT INTO mensajes_a_usuarios (persona_id, texto, fecha_mensaje, estado, asunto, idioma_origen, alarma_id, tipoalarma_id, descripcion_alarma, url_foto, distancia_metros, url_logo)
        SELECT *
        FROM public.consulta_msgs_alarmas(p_user_id_thirdparty, v_row.alarma_id);

        -- Insertar en notificaciones_persona para anti-duplicado con flujo de arribo
        -- Esto evita que vw_cantidad_alarmas_zona cuente esta alarma como "no notificada"
        -- cuando el usuario actualice su ubicacion despues
        INSERT INTO notificaciones_persona (persona_id, alarma_id, flag_enviado, fecha_notificacion, ultima_notificacion_enviada)
        VALUES (v_row.persona_id, v_row.alarma_id, true, now(), now());
    END LOOP;

END;
$BODY$;
