-- PROCEDURE: public.actualizar_valorsubscripciones(integer, integer, integer, integer, character varying)
-- Propósito: Actualiza el precio (cantidad_poderes) y/o la duración (tiempo_subscripcion_horas)
--            de un registro en valorsubscripciones, guardando el snapshot anterior en
--            historico_valorsubscripciones antes del cambio.
--
-- Comportamiento idempotente:
--   - Si los nuevos valores son idénticos a los actuales, NO se genera ningún registro
--     histórico y NO se actualiza la tabla. Ejecutar N veces sin cambios = 0 filas nuevas.
--
-- Parámetros:
--   p_valorsubscripcion_id        : ID del registro a modificar
--   p_nueva_cantidad_poderes      : Nuevo costo en poderes (NULL = no cambiar)
--   p_nuevo_tiempo_horas          : Nueva duración en horas  (NULL = no cambiar)
--   p_nueva_cantidad_subscripcion : Nueva cantidad de suscripciones (NULL = no cambiar)
--   p_modificado_por              : Identificador del usuario o proceso que realiza el cambio
--
-- Uso típico:
--   CALL public.actualizar_valorsubscripciones(1, 5, NULL, NULL, 'LANZAMIENTO_2026');
--   CALL public.actualizar_valorsubscripciones(2, 5, NULL, NULL, 'LANZAMIENTO_2026');
--   CALL public.actualizar_valorsubscripciones(3, 2, NULL, NULL, 'LANZAMIENTO_2026');

-- DROP PROCEDURE IF EXISTS public.actualizar_valorsubscripciones(integer, integer, integer, integer, character varying);

CREATE OR REPLACE PROCEDURE public.actualizar_valorsubscripciones(
    IN p_valorsubscripcion_id        integer,
    IN p_nueva_cantidad_poderes      integer   DEFAULT NULL,
    IN p_nuevo_tiempo_horas          integer   DEFAULT NULL,
    IN p_nueva_cantidad_subscripcion integer   DEFAULT NULL,
    IN p_modificado_por              character varying DEFAULT 'ADMIN'
)
LANGUAGE plpgsql
AS $BODY$
DECLARE
    -- Variables para los valores actuales del registro
    v_tipo_subscr_id            integer;
    v_cantidad_subscripcion_act integer;
    v_cantidad_poderes_act      integer;
    v_tiempo_horas_act          integer;

    -- Variables para los valores finales que se aplicarán
    v_cantidad_poderes_final    integer;
    v_tiempo_horas_final        integer;
    v_cantidad_subscr_final     integer;

    -- Control de cambios
    v_hay_cambios               boolean := FALSE;
    v_ahora                     timestamp with time zone := NOW();

BEGIN

    -- ─── 1. Leer valores actuales ───────────────────────────────────────────
    SELECT
        tipo_subscr_id,
        cantidad_subscripcion,
        cantidad_poderes,
        tiempo_subscripcion_horas
    INTO
        v_tipo_subscr_id,
        v_cantidad_subscripcion_act,
        v_cantidad_poderes_act,
        v_tiempo_horas_act
    FROM public.valorsubscripciones
    WHERE valorsubscripcion_id = p_valorsubscripcion_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe un registro en valorsubscripciones con id = %', p_valorsubscripcion_id;
    END IF;

    -- ─── 2. Resolver valores finales (NULL = conservar el actual) ──────────
    v_cantidad_poderes_final := COALESCE(p_nueva_cantidad_poderes,      v_cantidad_poderes_act);
    v_tiempo_horas_final     := COALESCE(p_nuevo_tiempo_horas,          v_tiempo_horas_act);
    v_cantidad_subscr_final  := COALESCE(p_nueva_cantidad_subscripcion, v_cantidad_subscripcion_act);

    -- ─── 3. Detectar si hay cambios reales ─────────────────────────────────
    IF  v_cantidad_poderes_final  IS DISTINCT FROM v_cantidad_poderes_act
     OR v_tiempo_horas_final      IS DISTINCT FROM v_tiempo_horas_act
     OR v_cantidad_subscr_final   IS DISTINCT FROM v_cantidad_subscripcion_act
    THEN
        v_hay_cambios := TRUE;
    END IF;

    -- ─── 4. Si no hay cambios, salir sin hacer nada ─────────────────────────
    IF NOT v_hay_cambios THEN
        RAISE NOTICE 'actualizar_valorsubscripciones: Sin cambios en valorsubscripcion_id=%. No se generó registro histórico.', p_valorsubscripcion_id;
        RETURN;
    END IF;

    -- ─── 5. Cerrar el registro vigente en el histórico (si existe) ─────────
    UPDATE public.historico_valorsubscripciones
    SET fecha_fin_vigencia = v_ahora
    WHERE valorsubscripcion_id = p_valorsubscripcion_id
      AND fecha_fin_vigencia IS NULL;

    -- ─── 6. Insertar snapshot de los valores ANTERIORES en el histórico ────
    --        (preservamos lo que estaba antes del cambio con su vigencia)
    INSERT INTO public.historico_valorsubscripciones (
        valorsubscripcion_id,
        tipo_subscr_id,
        cantidad_subscripcion,
        cantidad_poderes,
        tiempo_subscripcion_horas,
        fecha_inicio_vigencia,
        fecha_fin_vigencia,
        modificado_por,
        fecha_modificacion
    )
    SELECT
        valorsubscripcion_id,
        tipo_subscr_id,
        cantidad_subscripcion,
        cantidad_poderes,
        tiempo_subscripcion_horas,
        -- La vigencia del snapshot anterior arranca desde el inicio del tiempo
        -- si no había registro previo; de lo contrario desde el último cambio.
        -- Usamos v_ahora como fin porque este snapshot ya quedó cerrado arriba.
        COALESCE(
            (SELECT MAX(fecha_fin_vigencia)
             FROM public.historico_valorsubscripciones h2
             WHERE h2.valorsubscripcion_id = p_valorsubscripcion_id
               AND h2.fecha_fin_vigencia = v_ahora),
            fecha_inicio_vigencia_calculada
        ),
        v_ahora,                    -- fecha_fin_vigencia = ahora (ya no vigente)
        p_modificado_por,
        v_ahora
    FROM (
        SELECT
            p_valorsubscripcion_id  AS valorsubscripcion_id,
            v_tipo_subscr_id        AS tipo_subscr_id,
            v_cantidad_subscripcion_act AS cantidad_subscripcion,
            v_cantidad_poderes_act  AS cantidad_poderes,
            v_tiempo_horas_act      AS tiempo_subscripcion_horas,
            -- Inicio de vigencia del snapshot anterior = fin del snapshot anterior previo,
            -- o '2000-01-01' si nunca hubo histórico (primer cambio)
            COALESCE(
                (SELECT MAX(h.fecha_fin_vigencia)
                 FROM public.historico_valorsubscripciones h
                 WHERE h.valorsubscripcion_id = p_valorsubscripcion_id
                   AND h.fecha_fin_vigencia < v_ahora),
                '2000-01-01 00:00:00+00'::timestamp with time zone
            ) AS fecha_inicio_vigencia_calculada
    ) sub;

    -- ─── 7. Insertar snapshot de los valores NUEVOS como vigente (fin = NULL) ─
    INSERT INTO public.historico_valorsubscripciones (
        valorsubscripcion_id,
        tipo_subscr_id,
        cantidad_subscripcion,
        cantidad_poderes,
        tiempo_subscripcion_horas,
        fecha_inicio_vigencia,
        fecha_fin_vigencia,
        modificado_por,
        fecha_modificacion
    ) VALUES (
        p_valorsubscripcion_id,
        v_tipo_subscr_id,
        v_cantidad_subscr_final,
        v_cantidad_poderes_final,
        v_tiempo_horas_final,
        v_ahora,    -- empieza a regir ahora
        NULL,       -- NULL = vigente actualmente
        p_modificado_por,
        v_ahora
    );

    -- ─── 8. Aplicar los nuevos valores en la tabla operacional ─────────────
    UPDATE public.valorsubscripciones
    SET
        cantidad_poderes        = v_cantidad_poderes_final,
        tiempo_subscripcion_horas = v_tiempo_horas_final,
        cantidad_subscripcion   = v_cantidad_subscr_final
    WHERE valorsubscripcion_id = p_valorsubscripcion_id;

    RAISE NOTICE 'actualizar_valorsubscripciones: valorsubscripcion_id=% actualizado. Poderes: % → %. Horas: % → %. Registrado por: %.',
        p_valorsubscripcion_id,
        v_cantidad_poderes_act,  v_cantidad_poderes_final,
        v_tiempo_horas_act,      v_tiempo_horas_final,
        p_modificado_por;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '%', SQLERRM;
END;
$BODY$;

COMMENT ON PROCEDURE public.actualizar_valorsubscripciones(integer, integer, integer, integer, character varying) IS
'Actualiza los valores de un registro en valorsubscripciones y registra el historial de cambios
en historico_valorsubscripciones. Es idempotente: si los nuevos valores son iguales a los
actuales, no genera ningún registro histórico ni modifica nada.

Parámetros:
  p_valorsubscripcion_id        : ID del registro a modificar
  p_nueva_cantidad_poderes      : Nuevo costo en poderes (NULL = no cambiar)
  p_nuevo_tiempo_horas          : Nueva duración en horas (NULL = no cambiar)
  p_nueva_cantidad_subscripcion : Nueva cantidad de suscripciones (NULL = no cambiar)
  p_modificado_por              : Identificador del ejecutor del cambio

Ejemplo:
  CALL public.actualizar_valorsubscripciones(1, 5, NULL, NULL, ''LANZAMIENTO_2026'');';
