-- FUNCTION: public.funcinsertaalarmaynotifica(character varying, integer, numeric, numeric, character varying, bigint)

-- DROP FUNCTION IF EXISTS public.funcinsertaalarmaynotifica(character varying, integer, numeric, numeric, character varying, bigint);

CREATE OR REPLACE FUNCTION public.funcinsertaalarmaynotifica(
	p_user_id_thirdparty character varying,
	p_tipoalarma_id integer,
	p_latitud numeric,
	p_longitud numeric,
	p_ipusuario character varying,
	p_alarma_id bigint)
    RETURNS TABLE(user_id_thirdparty character varying, persona_id bigint, alarma_id bigint, latitud_alarma numeric, longitud_alarma numeric, txt_notif character varying, idioma_destino character varying) 
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
            );

    -- Insertar mensajes para usuarios basados en la función public.consulta_msgs_alarmas
   FOR v_row IN (
        SELECT 
            v.user_id_thirdparty,
            v.persona_id,
            v.alarma_id,
            v.latitud_alarma,
            v.longitud_alarma,
            v.txt_notif,
            v.idioma_destino 
        FROM vw_notificacion_alarmas v
        WHERE v.latitud_alarma=p_latitud
        AND v.longitud_alarma=p_longitud				
        AND v.user_id_creador_alarma = p_user_id_thirdparty
        AND v.tipoalarma_id=p_tipoalarma_id
    ) 
    LOOP

	user_id_thirdparty := v_row.user_id_thirdparty;
	persona_id := v_row.persona_id;
	alarma_id := v_row.alarma_id;
	latitud_alarma := v_row.latitud_alarma;
	longitud_alarma := v_row.longitud_alarma;
	txt_notif := v_row.txt_notif;
	idioma_destino := v_row.idioma_destino;

	RETURN NEXT; -- Esto retornará la fila al resultado de la función
        
        -- Insertar mensajes en mensajes_a_usuarios usando la función consulta_msgs_alarmas
        INSERT INTO mensajes_a_usuarios (persona_id,texto,fecha_mensaje,estado,asunto,idioma_origen,alarma_id)
        SELECT * 
        FROM public.consulta_msgs_alarmas(p_user_id_thirdparty, v_row.alarma_id);
    END LOOP;

END;
$BODY$;

ALTER FUNCTION public.funcinsertaalarmaynotifica(character varying, integer, numeric, numeric, character varying, bigint)
    OWNER TO w4ll4c3;
