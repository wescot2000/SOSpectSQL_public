-- PROCEDURE: public.upsertubicacion(character varying, numeric, numeric)

-- DROP PROCEDURE IF EXISTS public.upsertubicacion(character varying, numeric, numeric);

CREATE OR REPLACE PROCEDURE public.upsertubicacion(
	IN p_user_id_thirdparty character varying,
	IN p_latitud numeric,
	IN p_longitud numeric)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
    v_persona_id BIGINT;
    v_ubicacion_id BIGINT;
BEGIN
    SELECT 
            persona_id
        INTO 
            v_persona_id
    FROM 
        personas
    WHERE
        user_id_thirdparty=p_user_id_thirdparty;

    select 
       ubicacion_id
	INTO
		v_ubicacion_id
    FROM 
        ubicaciones
    WHERE
        persona_id=v_persona_id
	and 
		v_persona_id is not null
    and
        "Tipo"='P';

	insert 
		into 
			public.notificaciones_persona
			(
				persona_id
				,alarma_id
				,flag_enviado
				,fecha_notificacion
			)
		select 
			p.persona_id
			,v.alarma_id
			,cast(false as boolean)
			,now()
		FROM 
			personas p
		inner join 
			vw_busca_alarmas_por_zona v
		on 
			(
				v.user_id_thirdparty=p.user_id_thirdparty
			)
        left outer join notificaciones_persona np
            on (
                np.alarma_id=v.alarma_id and np.persona_id=p.persona_id
                )
		WHERE 
		    p.user_id_thirdparty =  p_user_id_thirdparty
        and 
            np.alarma_id is null;

	/*INSERT CREADO PARA TRAZABILIDAD DE CANTIDAD DE COMUNICACION POR UPSERT, BORRABLE PARA ENTRADA EN PRODUCCION*/
	insert into 
		ubicaciones_testing
			(persona_id,
			latitud,
			longitud,
			fecha_ubicacion)
			VALUES(
			v_persona_id
			,p_latitud
			,p_longitud
			,now()
			);
	/*FIN DE INSERT CREADO PARA TRAZABILIDAD DE CANTIDAD DE COMUNICACION POR UPSERT, BORRABLE PARA ENTRADA EN PRODUCCION*/

    IF v_ubicacion_id is null THEN
        INSERT INTO 
            ubicaciones 
                (
                    persona_id
                    ,latitud
                    ,longitud
                    ,"Tipo"
                )
        VALUES
                (
                    v_persona_id
                    ,p_latitud
                    ,p_longitud
                    ,'P'
                );
    ELSE
        UPDATE 
            ubicaciones
        SET 
            latitud = p_latitud
            ,longitud=p_longitud
        WHERE
            "Tipo" = 'P'
        and 
            ubicacion_id=v_ubicacion_id;
    END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION '%', sqlerrm;
END;
$BODY$;
ALTER PROCEDURE public.upsertubicacion(character varying, numeric, numeric)
    OWNER TO w4ll4c3;
