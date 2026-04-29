-- FUNCTION: public.actualizar_metricas_emprendimiento_realtime()
-- Creado: 13-01-2026
-- Actualizado: 13-01-2026 - Trigger ahora en chat_publicidad (no en tabla separada)
-- Propósito: Trigger function para actualizar métricas de emprendimiento en tiempo real cuando se califica un chat

-- DROP FUNCTION IF EXISTS public.actualizar_metricas_emprendimiento_realtime() CASCADE;

CREATE OR REPLACE FUNCTION public.actualizar_metricas_emprendimiento_realtime()
RETURNS TRIGGER
LANGUAGE 'plpgsql'
COST 100
VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
    v_id_emprendimiento BIGINT;
BEGIN
    -- Solo procesar si se acaba de agregar una calificación (UPDATE con calificación nueva)
    IF TG_OP = 'UPDATE' AND NEW.calificacion_servicio IS NOT NULL AND
       (OLD.calificacion_servicio IS NULL OR OLD.calificacion_servicio != NEW.calificacion_servicio) THEN

        -- Obtener id_emprendimiento desde subscripciones
        SELECT s.id_emprendimiento INTO v_id_emprendimiento
        FROM public.subscripciones s
        WHERE s.subscripcion_id = NEW.subscripcion_id
          AND s.id_emprendimiento IS NOT NULL;

        -- Si no se encontró emprendimiento, salir (puede ser chat antiguo antes de migración)
        IF v_id_emprendimiento IS NULL THEN
            RETURN NEW;
        END IF;

        -- Actualizar métricas del emprendimiento
        UPDATE public.emprendimientos
        SET
            -- Incrementar contador de calificaciones
            total_calificaciones = total_calificaciones + 1,

            -- Recalcular promedio de reputación (promedio incremental)
            reputacion_promedio = ROUND(
                ((reputacion_promedio * total_calificaciones) + NEW.calificacion_servicio) /
                (total_calificaciones + 1.0),
                2
            ),

            -- Actualizar timestamp
            fecha_actualizacion_metricas = NOW()

        WHERE id_emprendimiento = v_id_emprendimiento;

        -- Recalcular badges del emprendimiento
        UPDATE public.emprendimientos
        SET badges_ganados = calcular_badges_proveedor(v_id_emprendimiento)
        WHERE id_emprendimiento = v_id_emprendimiento;

    END IF;

    RETURN NEW;
END;
$BODY$;


COMMENT ON FUNCTION public.actualizar_metricas_emprendimiento_realtime() IS
'Trigger function que actualiza las métricas de un emprendimiento en tiempo real cuando se califica un chat publicitario.
Actualiza: total_calificaciones, reputacion_promedio, badges_ganados, fecha_actualizacion_metricas.
Requiere que subscripciones.id_emprendimiento esté poblado correctamente.
Actualizado: 13-01-2026 - Migrado desde tabla personas a tabla emprendimientos.';

-- Crear el trigger en la tabla chat_publicidad
-- DROP TRIGGER IF EXISTS trigger_actualizar_metricas_realtime ON public.chat_publicidad;

CREATE TRIGGER trigger_actualizar_metricas_realtime
AFTER UPDATE OF calificacion_servicio
ON public.chat_publicidad
FOR EACH ROW
EXECUTE FUNCTION actualizar_metricas_emprendimiento_realtime();

COMMENT ON TRIGGER trigger_actualizar_metricas_realtime ON public.chat_publicidad IS
'Trigger que actualiza métricas del emprendimiento cuando se agrega o modifica una calificación de servicio en un chat publicitario.';
