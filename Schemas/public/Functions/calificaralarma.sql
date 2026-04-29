-- FUNCTION: public.calificaralarma(character varying, bigint, boolean)
-- MODIFICADO: 2026-02-26 - Actualizar contadores denormalizados cnt_verdaderos/cnt_falsos en alarmas

-- DROP FUNCTION IF EXISTS public.calificaralarma(character varying, bigint, boolean);

CREATE OR REPLACE FUNCTION public.calificaralarma(
	p_user_id_thirdparty character varying,
	p_alarma_id bigint,
	p_veracidadalarma boolean)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

DECLARE 
    p_persona_id BIGINT;
    p_existencia_calificacion INTEGER;
    p_calificacion_alarma numeric (5,2);
    v_estado_alarma varchar(10);
    v_cantidad_personas integer;
    resultado VARCHAR(500);
BEGIN
    BEGIN
        SELECT 
            count(*)
        INTO 
            v_cantidad_personas
        FROM 
            personas
        WHERE
            user_id_thirdparty=p_user_id_thirdparty;

        IF v_cantidad_personas = 0 then
            resultado := 'Person not found';    
            RETURN resultado;
        END IF; 

        IF v_cantidad_personas > 1 then
            resultado := 'Person duplicated';    
            RETURN resultado;
        END IF;   

        SELECT 
            persona_id
        INTO 
            p_persona_id
        FROM 
            personas
        WHERE
            user_id_thirdparty=p_user_id_thirdparty;
    END;

    BEGIN
        select
            estado_alarma
        INTO
            v_estado_alarma
        from
            alarmas
        WHERE
            alarma_id=p_alarma_id;

        IF v_estado_alarma = 'C' then
            resultado := 'Denied, alarm already closed';    
            RETURN resultado;
        END IF;    

        SELECT 
            count(*)
        INTO 
            p_existencia_calificacion
        FROM 
            descripcionesalarmas
        WHERE
            persona_id=p_persona_id
        AND
            alarma_id=p_alarma_id
        AND 
            veracidadalarma is not null;
        
        IF p_existencia_calificacion>0 then
            resultado := 'The user already rated that alarm';
            RETURN resultado;
        END IF;

        INSERT INTO
            descripcionesalarmas
                (
                    persona_id
                    ,alarma_id
                    ,veracidadalarma
                    ,fechadescripcion
                )
        VALUES
            (
                p_persona_id
                ,p_alarma_id
                ,p_VeracidadAlarma
                ,now()
            );

        -- Actualizar contadores denormalizados en alarmas
        IF p_VeracidadAlarma THEN
            UPDATE alarmas SET cnt_verdaderos = cnt_verdaderos + 1 WHERE alarma_id = p_alarma_id;
        ELSE
            UPDATE alarmas SET cnt_falsos = cnt_falsos + 1 WHERE alarma_id = p_alarma_id;
        END IF;
    END;

    BEGIN
        /*select 
            cast(cast(cast(verdaderos.cantidad_verdadero*100 as decimal(18,2))/cast(total.cantidad_total as decimal(18,2)) as decimal(18,2))*credibpersona.credibilidad_reportante as numeric (5,2)) calificacion 
        INTO 
            p_calificacion_alarma
        from
            (
                select 
                    case when count(*)=0 then 1 else count(*) end cantidad_verdadero 
                from descripcionesalarmas
                where alarma_id=p_alarma_id
                and VeracidadAlarma=true
            ) as verdaderos,
            (
                select 
                    case when count(*)=0 then 1 else count(*) end cantidad_total 
                from descripcionesalarmas
                where alarma_id=p_alarma_id
                and VeracidadAlarma is not null
            ) as total,
            (
                select 
                    cast(per.credibilidad_persona/100 as decimal(18,2)) as credibilidad_reportante
                from 
                    personas per
                inner join 
                    alarmas ar
                on 
                    (
                    ar.persona_id=per.persona_id
                    )
                where 
                    ar.alarma_id=p_alarma_id
            ) as credibpersona;*/

            -- Recuperamos la calificación actual de la alarma
            SELECT 
                calificacion_alarma
            INTO 
                p_calificacion_alarma
            FROM 
                alarmas
            WHERE 
                alarma_id=p_alarma_id;

               IF NOT FOUND THEN
                    SELECT 
                        CAST(per.credibilidad_persona AS numeric(5,2)) / 100.00
                    INTO 
                        p_calificacion_alarma
                    FROM 
                        personas per
                    WHERE 
                        per.persona_id = p_persona_id
                    LIMIT 1;

                    -- Verificamos si tampoco se encontró un registro en personas, y en ese caso asignamos un valor por defecto
                    IF NOT FOUND THEN
                        p_calificacion_alarma := 100.00; -- Valor por defecto, ajusta según lo que consideres adecuado
                    END IF;
                END IF;


            -- Calculamos la nueva calificación basado en si es un voto positivo o negativo
            IF p_veracidadalarma THEN
                p_calificacion_alarma := LEAST(p_calificacion_alarma + 2.0, 100.00);
            ELSE
                p_calificacion_alarma := GREATEST(p_calificacion_alarma - 2.0, 0.00);
            END IF;
    END;
    
    BEGIN 
        UPDATE
            alarmas
        set
            calificacion_alarma=p_calificacion_alarma
        where 
            alarma_id=p_alarma_id;

        resultado := 'Success';
        RETURN resultado;
    END;
END
$BODY$;

