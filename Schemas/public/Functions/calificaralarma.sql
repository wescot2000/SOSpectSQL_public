-- FUNCTION: public.calificaralarma(character varying, bigint, boolean)

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
    END;

    BEGIN
        select 
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
            ) as credibpersona;
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

ALTER FUNCTION public.calificaralarma(character varying, bigint, boolean)
    OWNER TO w4ll4c3;
