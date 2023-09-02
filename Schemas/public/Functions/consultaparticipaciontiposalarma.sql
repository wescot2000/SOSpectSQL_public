-- FUNCTION: public.consultaparticipaciontiposalarma(text)

-- DROP FUNCTION IF EXISTS public.consultaparticipaciontiposalarma(text);

CREATE OR REPLACE FUNCTION public.consultaparticipaciontiposalarma(
	user_id_thirdparty_in text)
    RETURNS TABLE(alarmtypeid integer, alarmtypename character varying, alarmcount bigint, participation numeric, fecha_inicio_reporte timestamp with time zone, fecha_fin_reporte timestamp with time zone) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
    WITH user_locations AS (
        SELECT DISTINCT
            u.latitud,
            u.longitud
        FROM
            ubicaciones u 
        JOIN 
            personas p ON p.persona_id = u.persona_id and u."Tipo"='P'
        WHERE 
            p.user_id_thirdparty = user_id_thirdparty_in
            AND u."Tipo"='P'
    )
    SELECT 
        ta.tipoalarma_id AS AlarmTypeId,
        ta.descripciontipoalarma AS AlarmTypeName,
        COUNT(al.alarma_id) AS AlarmCount,
        round((COUNT(al.alarma_id) * 1.0 / 
            (SELECT COUNT(*) FROM alarmas al
                CROSS JOIN user_locations ul
                WHERE 
                    (
                        al.latitud 
                        BETWEEN ul.latitud-0.013500
                        AND ul.latitud+0.013500
                    AND 
                        al.longitud 
                        BETWEEN ul.longitud-0.013500
                        AND ul.longitud+0.013500
                    )
                AND al.fecha_alarma >= now() - interval '30 days'))*1,4) AS Participation,
		now() - interval '30 days' as fecha_inicio_reporte,
		now() as fecha_fin_reporte
    FROM 
        alarmas al 
    JOIN 
        tipoalarma ta ON al.tipoalarma_id = ta.tipoalarma_id
    CROSS JOIN 
        user_locations ul
    WHERE  
        (
            al.latitud 
            BETWEEN ul.latitud-0.013500
            AND ul.latitud+0.013500
        AND 
            al.longitud 
            BETWEEN ul.longitud-0.013500
            AND ul.longitud+0.013500
        )
        AND al.fecha_alarma >= now() - interval '30 days'
    GROUP BY 
        ta.tipoalarma_id
	order by 4 desc	
		;
END; 
$BODY$;

ALTER FUNCTION public.consultaparticipaciontiposalarma(text)
    OWNER TO w4ll4c3;
