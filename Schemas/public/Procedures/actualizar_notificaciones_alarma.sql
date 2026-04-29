-- PROCEDURE: public.actualizar_notificaciones_alarma()

-- DROP PROCEDURE IF EXISTS public.actualizar_notificaciones_alarma();

CREATE OR REPLACE PROCEDURE public.actualizar_notificaciones_alarma(
	)
LANGUAGE 'plpgsql'
AS $BODY$

BEGIN
    UPDATE personas
    SET notif_alarma_policia_habilitada = true, 
        fecha_act_configuracion_notif = null,
        dias_notif_policia_apagada = null
    WHERE now() > fecha_act_configuracion_notif + make_interval(days => dias_notif_policia_apagada) 
    AND notif_alarma_policia_habilitada IS false;
END;
$BODY$;
