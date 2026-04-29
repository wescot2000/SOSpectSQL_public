-- PROCEDURE: public.procesarsolicitudescierrevencidas()
-- Convertido de FUNCTION a PROCEDURE: 2026-04-08
-- Motivo: se ejecuta exclusivamente vía pg_cron (CALL); nadie consume el resultado de retorno.
--         El API tampoco hace referencia a esta función.
--
-- Propósito: procesa solicitudes de cierre comunitario cuyo período de votación (24h) ha expirado.
--   - Mayoría a favor o nadie votó → aprueba y cierra la alarma (estado_alarma = 'C')
--   - Mayoría en contra → deniega
--   - Registra el cierre en descripcionesalarmas para calcular avg_dias_resolucion.
--   - Solo registra descripción para alarmas de categoría SEGURIDAD (1) y POLITICA (2).
--
-- Diferencia con cierrevotacionesalarmas:
--   - cierrevotacionesalarmas: evalúa votaciones de VERACIDAD, cierra por minutos_vigencia
--     y cierra alarmas promocionales.
--   - Este procedure: resuelve solicitudes de cierre COMUNITARIO (tabla solicitudes_cierre)
--     propuestas por usuarios, con período de votación de 24h.
--
-- CRON: ejecutar cada 5 minutos o con la frecuencia deseada.
--   CALL public.procesarsolicitudescierrevencidas();

CREATE OR REPLACE PROCEDURE public.procesarsolicitudescierrevencidas()
LANGUAGE plpgsql
AS $$
DECLARE
    rec             RECORD;
    v_total         INTEGER;
    v_resultado     VARCHAR(20);
BEGIN
    -- Procesar todas las solicitudes activas cuya fecha límite ya pasó
    FOR rec IN
        SELECT
            sc.solicitud_id,
            sc.alarma_id,
            sc.persona_id,
            sc.votos_si,
            sc.votos_no,
            al.latitud,
            al.longitud
        FROM solicitudes_cierre sc
        JOIN alarmas al ON al.alarma_id = sc.alarma_id
        WHERE sc.estado = 'activa'
          AND sc.fecha_limite_votacion <= now()
        FOR UPDATE OF sc
    LOOP
        v_total := rec.votos_si + rec.votos_no;

        -- Determinar resultado
        IF v_total = 0 OR rec.votos_si >= rec.votos_no THEN
            -- Nadie votó o mayoría a favor (o empate): se aprueba
            v_resultado := 'aprobada';
        ELSE
            -- Mayoría en contra: se deniega
            v_resultado := 'denegada';
        END IF;

        -- Actualizar estado de la solicitud
        UPDATE solicitudes_cierre
           SET estado = v_resultado
         WHERE solicitudes_cierre.solicitud_id = rec.solicitud_id;

        -- Si aprobada, cerrar la alarma y registrar el cierre
        IF v_resultado = 'aprobada' THEN

            UPDATE alarmas
               SET estado_alarma = 'C'
             WHERE alarmas.alarma_id = rec.alarma_id
               AND estado_alarma IS NULL;

            -- Registrar cierre en descripcionesalarmas para avg_dias_resolucion.
            -- Solo categorías SEGURIDAD (1) y POLITICA (2).
            -- NOT EXISTS evita duplicados si ya existe un cierre manual previo.
            INSERT INTO public.descripcionesalarmas (
                persona_id,
                alarma_id,
                descripcionalarma,
                fechadescripcion,
                flag_es_cierre_alarma,
                flag_hubo_captura,
                flag_persona_encontrada,
                flag_mascota_recuperada
            )
            SELECT
                rec.persona_id,
                rec.alarma_id,
                'Cierre aprobado por votación comunitaria (' ||
                    rec.votos_si || ' a favor, ' || rec.votos_no || ' en contra)',
                now(),
                TRUE,
                FALSE,
                FALSE,
                FALSE
            WHERE EXISTS (
                SELECT 1 FROM public.alarmas al
                JOIN public.tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
                WHERE al.alarma_id = rec.alarma_id
                  AND ta.categoria_alarma_id IN (1, 2)
            )
            AND NOT EXISTS (
                SELECT 1 FROM public.descripcionesalarmas
                WHERE alarma_id = rec.alarma_id AND flag_es_cierre_alarma = TRUE
            );

        END IF;

    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error en procesarsolicitudescierrevencidas: %', SQLERRM;
END;
$$;

COMMENT ON PROCEDURE public.procesarsolicitudescierrevencidas() IS
'Procesa solicitudes de cierre comunitario (tabla solicitudes_cierre) cuyo período de votación (24h) ha expirado. Si mayoría a favor o nadie votó: aprueba y cierra alarma (estado_alarma=C). Si mayoría en contra: deniega. Registra descripción de cierre para categorías SEGURIDAD y POLITICA. Convertido de FUNCTION a PROCEDURE el 2026-04-08 para permitir CALL desde pg_cron.';
