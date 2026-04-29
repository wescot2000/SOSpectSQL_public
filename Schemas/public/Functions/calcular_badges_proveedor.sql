-- FUNCTION: public.calcular_badges_proveedor(bigint)
-- Creado: 13-01-2026
-- Propósito: Calcular badges ganados por un emprendimiento basándose en sus métricas

-- DROP FUNCTION IF EXISTS public.calcular_badges_proveedor(bigint);

CREATE OR REPLACE FUNCTION public.calcular_badges_proveedor(
    p_id_emprendimiento bigint
)
RETURNS jsonb
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    badges jsonb := '[]'::jsonb;
    v_emprendimiento public.emprendimientos%ROWTYPE;
BEGIN
    -- Obtener métricas del emprendimiento (NO de personas)
    SELECT * INTO v_emprendimiento
    FROM public.emprendimientos
    WHERE id_emprendimiento = p_id_emprendimiento
      AND fecha_fin IS NULL;  -- Solo emprendimientos activos

    IF NOT FOUND THEN
        RETURN '[]'::jsonb;
    END IF;

    -- Badge: Respuesta Rápida (<10 min average response)
    IF v_emprendimiento.promedio_tiempo_respuesta_minutos < 10 AND
       v_emprendimiento.promedio_tiempo_respuesta_minutos > 0 THEN
        badges := badges || jsonb_build_object(
            'id', 'respuesta_rapida',
            'nombre', 'Respuesta Rápida',
            'icono', '🥇',
            'descripcion', 'Responde en menos de 10 minutos'
        );
    END IF;

    -- Badge: Entrega Express (<1 hour average delivery)
    IF v_emprendimiento.promedio_tiempo_entrega_horas < 1 AND
       v_emprendimiento.promedio_tiempo_entrega_horas > 0 THEN
        badges := badges || jsonb_build_object(
            'id', 'entrega_express',
            'nombre', 'Entrega Express',
            'icono', '🥈',
            'descripcion', 'Entrega en menos de 1 hora'
        );
    END IF;

    -- Badge: 5 Estrellas (>= 4.5 reputation)
    IF v_emprendimiento.reputacion_promedio >= 4.5 AND
       v_emprendimiento.total_calificaciones >= 5 THEN
        badges := badges || jsonb_build_object(
            'id', 'cinco_estrellas',
            'nombre', '5 Estrellas',
            'icono', '⭐',
            'descripcion', 'Reputación excelente (4.5+)'
        );
    END IF;

    -- Badge: Confiable (>= 100 successful transactions)
    IF v_emprendimiento.total_transacciones_exitosas >= 100 THEN
        badges := badges || jsonb_build_object(
            'id', 'confiable',
            'nombre', 'Confiable',
            'icono', '💎',
            'descripcion', 'Más de 100 transacciones exitosas'
        );
    END IF;

    -- Badge: Nuevo Vendedor (< 10 transactions)
    IF v_emprendimiento.total_transacciones_exitosas < 10 THEN
        badges := badges || jsonb_build_object(
            'id', 'nuevo_vendedor',
            'nombre', 'Nuevo Vendedor',
            'icono', '🌱',
            'descripcion', 'Emprendimiento nuevo en la plataforma'
        );
    END IF;

    -- Badge: Delivery Pro (>90% satisfaction)
    IF v_emprendimiento.porcentaje_satisfaccion > 90.0 AND
       v_emprendimiento.total_calificaciones >= 10 THEN
        badges := badges || jsonb_build_object(
            'id', 'delivery_pro',
            'nombre', 'Delivery Pro',
            'icono', '🚚',
            'descripcion', 'Más del 90% de satisfacción'
        );
    END IF;

    -- Badge: Estrella en Ascenso (10-50 transacciones)
    IF v_emprendimiento.total_transacciones_exitosas BETWEEN 10 AND 49 THEN
        badges := badges || jsonb_build_object(
            'id', 'estrella_ascenso',
            'nombre', 'Estrella en Ascenso',
            'icono', '🌟',
            'descripcion', 'Emprendimiento en crecimiento'
        );
    END IF;

    -- Badge: Top Vendedor (>= 500 transacciones)
    IF v_emprendimiento.total_transacciones_exitosas >= 500 THEN
        badges := badges || jsonb_build_object(
            'id', 'top_vendedor',
            'nombre', 'Top Vendedor',
            'icono', '👑',
            'descripcion', 'Más de 500 transacciones exitosas'
        );
    END IF;

    -- Badge: Cliente Frecuente (>50 chats mes actual)
    IF v_emprendimiento.total_chats_mes_actual > 50 THEN
        badges := badges || jsonb_build_object(
            'id', 'cliente_frecuente',
            'nombre', 'Alta Demanda',
            'icono', '🔥',
            'descripcion', 'Más de 50 chats este mes'
        );
    END IF;

    RETURN badges;
END;
$BODY$;


COMMENT ON FUNCTION public.calcular_badges_proveedor(bigint) IS
'Calcula los badges (logros) ganados por un emprendimiento basándose en sus métricas de gamificación.
Recibe id_emprendimiento y retorna un array JSON con los badges ganados.
Solo considera emprendimientos activos (fecha_fin IS NULL).
Actualizado: 13-01-2026 - Migrado desde tabla personas a tabla emprendimientos.';

-- Ejemplo de uso:
-- SELECT calcular_badges_proveedor(1);
-- Retorna: [{"id": "nuevo_vendedor", "nombre": "Nuevo Vendedor", "icono": "🌱", "descripcion": "..."}]
