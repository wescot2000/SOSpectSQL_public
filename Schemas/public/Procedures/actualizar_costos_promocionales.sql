-- PROCEDURE: public.actualizar_costos_promocionales(integer, integer, integer, integer, integer, integer, integer, integer, character varying)
-- Propósito: Actualiza uno o más costos en configuracion_costos_promocionales,
--            guardando el snapshot completo anterior en historico_costos_promocionales.
--
-- Comportamiento idempotente:
--   - Si todos los nuevos valores son idénticos a los actuales, NO se genera ningún
--     registro histórico y NO se actualiza la tabla.
--   - Ejecutar N veces sin cambios = 0 filas nuevas en el histórico.
--
-- Parámetros (todos opcionales excepto p_modificado_por; NULL = no cambiar ese campo):
--   p_costo_base_promocion       : Nuevo costo base
--   p_costo_logo                 : Nuevo costo de logo
--   p_costo_contacto             : Nuevo costo de chat/contacto
--   p_costo_domicilio            : Nuevo costo de domicilio
--   p_costo_por_500m_extra       : Nuevo costo por cada 500m adicionales
--   p_costo_por_dia_extra        : Nuevo costo por cada día adicional
--   p_costo_por_media_extra      : Nuevo costo por cada foto/video adicional
--   p_costo_por_50_usuarios_push : Nuevo costo por cada 50 usuarios push
--   p_modificado_por             : Identificador del usuario o proceso que realiza el cambio
--
-- Uso típico (bajar precios para lanzamiento):
--   CALL public.actualizar_costos_promocionales(10, 2, 1, 1, 5, 2, 5, 5, 'LANZAMIENTO_2026');
--
-- Uso parcial (cambiar solo el costo base):
--   CALL public.actualizar_costos_promocionales(p_costo_base_promocion := 15, p_modificado_por := 'ADMIN');

-- DROP PROCEDURE IF EXISTS public.actualizar_costos_promocionales(integer, integer, integer, integer, integer, integer, integer, integer, character varying);

CREATE OR REPLACE PROCEDURE public.actualizar_costos_promocionales(
    IN p_costo_base_promocion       integer   DEFAULT NULL,
    IN p_costo_logo                 integer   DEFAULT NULL,
    IN p_costo_contacto             integer   DEFAULT NULL,
    IN p_costo_domicilio            integer   DEFAULT NULL,
    IN p_costo_por_500m_extra       integer   DEFAULT NULL,
    IN p_costo_por_dia_extra        integer   DEFAULT NULL,
    IN p_costo_por_media_extra      integer   DEFAULT NULL,
    IN p_costo_por_50_usuarios_push integer   DEFAULT NULL,
    IN p_modificado_por             character varying DEFAULT 'ADMIN'
)
LANGUAGE plpgsql
AS $BODY$
DECLARE
    -- Variables para los valores actuales
    v_base_act          integer;
    v_logo_act          integer;
    v_contacto_act      integer;
    v_domicilio_act     integer;
    v_500m_act          integer;
    v_dia_act           integer;
    v_media_act         integer;
    v_push_act          integer;

    -- Variables para los valores finales que se aplicarán
    v_base_final        integer;
    v_logo_final        integer;
    v_contacto_final    integer;
    v_domicilio_final   integer;
    v_500m_final        integer;
    v_dia_final         integer;
    v_media_final       integer;
    v_push_final        integer;

    -- Control de cambios
    v_hay_cambios       boolean := FALSE;
    v_ahora             timestamp with time zone := NOW();

BEGIN

    -- ─── 1. Leer valores actuales (único registro, config_id = 1) ──────────
    SELECT
        costo_base_promocion,
        costo_logo,
        costo_contacto,
        costo_domicilio,
        costo_por_500m_extra,
        costo_por_dia_extra,
        costo_por_media_extra,
        costo_por_50_usuarios_push
    INTO
        v_base_act,
        v_logo_act,
        v_contacto_act,
        v_domicilio_act,
        v_500m_act,
        v_dia_act,
        v_media_act,
        v_push_act
    FROM public.configuracion_costos_promocionales
    WHERE config_id = 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el registro de configuracion_costos_promocionales (config_id = 1). Ejecute primero el INSERT inicial.';
    END IF;

    -- ─── 2. Resolver valores finales (NULL = conservar el actual) ──────────
    v_base_final     := COALESCE(p_costo_base_promocion,       v_base_act);
    v_logo_final     := COALESCE(p_costo_logo,                 v_logo_act);
    v_contacto_final := COALESCE(p_costo_contacto,             v_contacto_act);
    v_domicilio_final:= COALESCE(p_costo_domicilio,            v_domicilio_act);
    v_500m_final     := COALESCE(p_costo_por_500m_extra,       v_500m_act);
    v_dia_final      := COALESCE(p_costo_por_dia_extra,        v_dia_act);
    v_media_final    := COALESCE(p_costo_por_media_extra,      v_media_act);
    v_push_final     := COALESCE(p_costo_por_50_usuarios_push, v_push_act);

    -- ─── 3. Detectar si hay cambios reales ─────────────────────────────────
    IF  v_base_final      IS DISTINCT FROM v_base_act
     OR v_logo_final      IS DISTINCT FROM v_logo_act
     OR v_contacto_final  IS DISTINCT FROM v_contacto_act
     OR v_domicilio_final IS DISTINCT FROM v_domicilio_act
     OR v_500m_final      IS DISTINCT FROM v_500m_act
     OR v_dia_final       IS DISTINCT FROM v_dia_act
     OR v_media_final     IS DISTINCT FROM v_media_act
     OR v_push_final      IS DISTINCT FROM v_push_act
    THEN
        v_hay_cambios := TRUE;
    END IF;

    -- ─── 4. Si no hay cambios, salir sin hacer nada ─────────────────────────
    IF NOT v_hay_cambios THEN
        RAISE NOTICE 'actualizar_costos_promocionales: Sin cambios detectados. No se generó registro histórico.';
        RETURN;
    END IF;

    -- ─── 5. Cerrar el registro vigente en el histórico (si existe) ─────────
    UPDATE public.historico_costos_promocionales
    SET fecha_fin_vigencia = v_ahora
    WHERE fecha_fin_vigencia IS NULL;

    -- ─── 6. Insertar snapshot de los valores ANTERIORES en el histórico ────
    INSERT INTO public.historico_costos_promocionales (
        costo_base_promocion,
        costo_logo,
        costo_contacto,
        costo_domicilio,
        costo_por_500m_extra,
        costo_por_dia_extra,
        costo_por_media_extra,
        costo_por_50_usuarios_push,
        fecha_inicio_vigencia,
        fecha_fin_vigencia,
        modificado_por,
        fecha_modificacion
    ) VALUES (
        v_base_act,
        v_logo_act,
        v_contacto_act,
        v_domicilio_act,
        v_500m_act,
        v_dia_act,
        v_media_act,
        v_push_act,
        -- Inicio de vigencia = fin del snapshot anterior, o '2000-01-01' si es el primer cambio
        COALESCE(
            (SELECT MAX(fecha_fin_vigencia)
             FROM public.historico_costos_promocionales
             WHERE fecha_fin_vigencia < v_ahora),
            '2000-01-01 00:00:00+00'::timestamp with time zone
        ),
        v_ahora,            -- fecha_fin_vigencia = ahora (ya no vigente)
        p_modificado_por,
        v_ahora
    );

    -- ─── 7. Insertar snapshot de los valores NUEVOS como vigente (fin = NULL) ─
    INSERT INTO public.historico_costos_promocionales (
        costo_base_promocion,
        costo_logo,
        costo_contacto,
        costo_domicilio,
        costo_por_500m_extra,
        costo_por_dia_extra,
        costo_por_media_extra,
        costo_por_50_usuarios_push,
        fecha_inicio_vigencia,
        fecha_fin_vigencia,
        modificado_por,
        fecha_modificacion
    ) VALUES (
        v_base_final,
        v_logo_final,
        v_contacto_final,
        v_domicilio_final,
        v_500m_final,
        v_dia_final,
        v_media_final,
        v_push_final,
        v_ahora,    -- empieza a regir ahora
        NULL,       -- NULL = vigente actualmente
        p_modificado_por,
        v_ahora
    );

    -- ─── 8. Aplicar los nuevos valores en la tabla operacional ─────────────
    UPDATE public.configuracion_costos_promocionales
    SET
        costo_base_promocion        = v_base_final,
        costo_logo                  = v_logo_final,
        costo_contacto              = v_contacto_final,
        costo_domicilio             = v_domicilio_final,
        costo_por_500m_extra        = v_500m_final,
        costo_por_dia_extra         = v_dia_final,
        costo_por_media_extra       = v_media_final,
        costo_por_50_usuarios_push  = v_push_final,
        actualizado_por             = p_modificado_por,
        fecha_actualizacion         = v_ahora
    WHERE config_id = 1;

    RAISE NOTICE 'actualizar_costos_promocionales: Configuración actualizada por %. Base: %→%. Logo: %→%. Contacto: %→%. Domicilio: %→%. 500m: %→%. Día: %→%. Media: %→%. Push: %→%.',
        p_modificado_por,
        v_base_act,     v_base_final,
        v_logo_act,     v_logo_final,
        v_contacto_act, v_contacto_final,
        v_domicilio_act,v_domicilio_final,
        v_500m_act,     v_500m_final,
        v_dia_act,      v_dia_final,
        v_media_act,    v_media_final,
        v_push_act,     v_push_final;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '%', SQLERRM;
END;
$BODY$;

COMMENT ON PROCEDURE public.actualizar_costos_promocionales(integer, integer, integer, integer, integer, integer, integer, integer, character varying) IS
'Actualiza los costos de la tabla configuracion_costos_promocionales y registra el historial
de cambios en historico_costos_promocionales. Es idempotente: si todos los valores nuevos
son iguales a los actuales, no genera ningún registro histórico ni modifica nada.

Todos los parámetros de costo son opcionales (DEFAULT NULL = no cambiar ese campo).

Ejemplo completo (bajar precios para lanzamiento):
  CALL public.actualizar_costos_promocionales(10, 2, 1, 1, 5, 2, 5, 5, ''LANZAMIENTO_2026'');

Ejemplo parcial (cambiar solo el costo base):
  CALL public.actualizar_costos_promocionales(p_costo_base_promocion := 15, p_modificado_por := ''ADMIN'');';
