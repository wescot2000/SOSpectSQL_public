-- Procedure: public.refrescar_metricas_emprendedores
-- Precálculo de métricas de emprendedores con ranking por país.
--
-- ARQUITECTURA:
--   1. Fuente de verdad: public.metricas_emprendedores (SCD Tipo 2)
--   2. Caché de lectura: public.mv_metricas_emprendedores (una fila por emprendimiento, para la API)
--
-- LÓGICA:
--   Por cada emprendimiento activo (fecha_fin IS NULL):
--   1. Lee métricas de calificación desde public.emprendimientos (actualizadas por trigger)
--   2. Calcula total_chats_mes_actual y promedio_tiempo_respuesta_minutos directamente
--      desde public.chat_publicidad (más preciso que confiar en el campo de emprendimientos)
--   3. Obtiene el país del propietario desde public.personas.pais
--   4. Cierra el registro anterior en metricas_emprendedores (SCD Tipo 2)
--   5. Inserta nuevo registro vigente en metricas_emprendedores
--   6. Calcula puesto_en_pais y total_emprendedores_en_pais para todos los del mismo país
--   7. Sincroniza mv_metricas_emprendedores (UPSERT)
--
-- RANKING:
--   RANK() OVER (PARTITION BY pais ORDER BY reputacion_promedio DESC, total_calificaciones DESC)
--   Un emprendimiento sin calificaciones se ubica al final.
--
-- LLAMADA MANUAL:
--   CALL public.refrescar_metricas_emprendedores();
--
-- CRON DIARIO A LAS 22:00 UTC (10 pm hora Londres):
--   SELECT cron.schedule('ranking-emprendedores', '0 22 * * *',
--     'CALL public.refrescar_metricas_emprendedores()');
--
-- Creado: 2026-04-09
-- Modificado: 2026-04-12 — total_chats_mes_actual y promedio_tiempo_respuesta_minutos
--             se calculan ahora directamente desde chat_publicidad para reflejar
--             los chats reales (el campo en emprendimientos no se actualiza automáticamente).
--

CREATE OR REPLACE PROCEDURE public.refrescar_metricas_emprendedores()
LANGUAGE plpgsql
AS $$
DECLARE
    rec_emp   RECORD;
    v_ahora   TIMESTAMPTZ := NOW();
BEGIN

    -- ══════════════════════════════════════════════════════════════════════════
    -- Paso 1: Iterar sobre emprendimientos activos y actualizar metricas_emprendedores
    -- ══════════════════════════════════════════════════════════════════════════
    FOR rec_emp IN
        SELECT
            e.id_emprendimiento,
            e.nombre_emprendimiento,
            COALESCE(e.reputacion_promedio, 0)               AS reputacion_promedio,
            COALESCE(e.total_calificaciones, 0)              AS total_calificaciones,
            -- 2026-04-12: promedio_tiempo_respuesta calculado desde chat_publicidad
            --             (minutos entre fecha_inicio y fecha_primera_respuesta_proveedor)
            (
                SELECT ROUND(AVG(
                    EXTRACT(EPOCH FROM (cp.fecha_primera_respuesta_proveedor - cp.fecha_inicio)) / 60.0
                ))::INTEGER
                FROM public.chat_publicidad cp
                JOIN public.subscripciones s ON s.subscripcion_id = cp.subscripcion_id
                WHERE s.id_emprendimiento = e.id_emprendimiento
                  AND cp.fecha_primera_respuesta_proveedor IS NOT NULL
                  AND cp.fecha_inicio >= DATE_TRUNC('month', NOW())
            )                                                AS promedio_tiempo_respuesta_minutos,
            e.porcentaje_satisfaccion,
            -- 2026-04-12: total_chats_mes_actual calculado desde chat_publicidad
            --             (chats iniciados en el mes calendario actual)
            (
                SELECT COUNT(*)::INTEGER
                FROM public.chat_publicidad cp
                JOIN public.subscripciones s ON s.subscripcion_id = cp.subscripcion_id
                WHERE s.id_emprendimiento = e.id_emprendimiento
                  AND cp.fecha_inicio >= DATE_TRUNC('month', NOW())
            )                                                AS total_chats_mes_actual,
            COALESCE(e.total_transacciones_exitosas, 0)      AS total_transacciones_exitosas,
            e.badges_ganados,
            COALESCE(p.pais, 'Desconocido')                  AS pais
        FROM public.emprendimientos e
        JOIN public.personas p ON p.persona_id = e.persona_id_modificadora
        WHERE e.fecha_fin IS NULL   -- solo emprendimientos activos
    LOOP

        -- ── Cerrar registro anterior (SCD Tipo 2) ─────────────────────────────
        UPDATE public.metricas_emprendedores
           SET fecha_fin_vigencia = v_ahora
         WHERE pais              = rec_emp.pais
           AND id_emprendimiento = rec_emp.id_emprendimiento
           AND fecha_fin_vigencia IS NULL;

        -- ── Insertar nuevo registro vigente (puesto_en_pais se calcula en Paso 2) ─
        INSERT INTO public.metricas_emprendedores (
            pais, id_emprendimiento, nombre_emprendimiento,
            reputacion_promedio, total_calificaciones,
            promedio_tiempo_respuesta_minutos, porcentaje_satisfaccion,
            total_chats_mes_actual, total_transacciones_exitosas,
            badges_ganados, puesto_en_pais,
            fecha_inicio_vigencia, fecha_fin_vigencia, fecha_calculo
        ) VALUES (
            rec_emp.pais, rec_emp.id_emprendimiento, rec_emp.nombre_emprendimiento,
            rec_emp.reputacion_promedio, rec_emp.total_calificaciones,
            rec_emp.promedio_tiempo_respuesta_minutos, rec_emp.porcentaje_satisfaccion,
            rec_emp.total_chats_mes_actual, rec_emp.total_transacciones_exitosas,
            rec_emp.badges_ganados, NULL,   -- puesto_en_pais se actualiza en Paso 2
            v_ahora, NULL, v_ahora
        );

    END LOOP;

    -- ══════════════════════════════════════════════════════════════════════════
    -- Paso 2: Calcular ranking por país sobre los registros recién insertados
    -- ══════════════════════════════════════════════════════════════════════════
    UPDATE public.metricas_emprendedores me
       SET puesto_en_pais = ranking.puesto
      FROM (
          SELECT
              id,
              RANK() OVER (
                  PARTITION BY pais
                  ORDER BY reputacion_promedio DESC, total_calificaciones DESC
              ) AS puesto
          FROM public.metricas_emprendedores
          WHERE fecha_fin_vigencia IS NULL
            AND fecha_calculo >= v_ahora - INTERVAL '1 minute'
      ) ranking
     WHERE me.id = ranking.id;

    -- ══════════════════════════════════════════════════════════════════════════
    -- Paso 3: Sincronizar mv_metricas_emprendedores (caché de lectura para la API)
    -- ══════════════════════════════════════════════════════════════════════════
    INSERT INTO public.mv_metricas_emprendedores (
        pais, id_emprendimiento, nombre_emprendimiento,
        reputacion_promedio, total_calificaciones,
        promedio_tiempo_respuesta_minutos, porcentaje_satisfaccion,
        total_chats_mes_actual, total_transacciones_exitosas,
        badges_ganados, puesto_en_pais, total_emprendedores_en_pais,
        fecha_calculo
    )
    SELECT
        me.pais, me.id_emprendimiento, me.nombre_emprendimiento,
        me.reputacion_promedio, me.total_calificaciones,
        me.promedio_tiempo_respuesta_minutos, me.porcentaje_satisfaccion,
        me.total_chats_mes_actual, me.total_transacciones_exitosas,
        me.badges_ganados, me.puesto_en_pais,
        conteo_pais.total,
        v_ahora
    FROM public.metricas_emprendedores me
    JOIN (
        SELECT pais, COUNT(*) AS total
        FROM public.metricas_emprendedores
        WHERE fecha_fin_vigencia IS NULL
        GROUP BY pais
    ) conteo_pais ON conteo_pais.pais = me.pais
    WHERE me.fecha_fin_vigencia IS NULL
    ON CONFLICT (pais, id_emprendimiento) DO UPDATE SET
        nombre_emprendimiento             = EXCLUDED.nombre_emprendimiento,
        reputacion_promedio               = EXCLUDED.reputacion_promedio,
        total_calificaciones              = EXCLUDED.total_calificaciones,
        promedio_tiempo_respuesta_minutos = EXCLUDED.promedio_tiempo_respuesta_minutos,
        porcentaje_satisfaccion           = EXCLUDED.porcentaje_satisfaccion,
        total_chats_mes_actual            = EXCLUDED.total_chats_mes_actual,
        total_transacciones_exitosas      = EXCLUDED.total_transacciones_exitosas,
        badges_ganados                    = EXCLUDED.badges_ganados,
        puesto_en_pais                    = EXCLUDED.puesto_en_pais,
        total_emprendedores_en_pais       = EXCLUDED.total_emprendedores_en_pais,
        fecha_calculo                     = EXCLUDED.fecha_calculo;

END;
$$;

COMMENT ON PROCEDURE public.refrescar_metricas_emprendedores() IS
'Precálculo de métricas de emprendedores con ranking por país. total_chats_mes_actual y promedio_tiempo_respuesta_minutos se calculan desde chat_publicidad (no desde emprendimientos). Ranking por reputacion_promedio DESC. Se ejecuta a las 22:00 UTC. Creado: 2026-04-09. Modificado: 2026-04-12.';
