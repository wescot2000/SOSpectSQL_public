-- FUNCTION: public.listar_usuarios_red_confianza(character varying)
-- Modificado: 2026-04-02 — Se agrega nickname al resultado para que el líder pueda identificar a sus miembros.

-- DROP FUNCTION IF EXISTS public.listar_usuarios_red_confianza(character varying);

CREATE OR REPLACE FUNCTION public.listar_usuarios_red_confianza(
    p_user_id_thirdparty_lider character varying)
RETURNS TABLE(national_id character varying, nombres character varying, apellidos character varying, numero_movil character varying, email character varying, pais character varying, nickname character varying)
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE

AS $BODY$
DECLARE
    v_lider_id bigint;
BEGIN
    -- Obtener el persona_id del líder
    SELECT persona_id INTO v_lider_id
    FROM public.personas
    WHERE user_id_thirdparty = p_user_id_thirdparty_lider;
    
    -- Retornar los datos de los usuarios hijos
    RETURN QUERY
    SELECT
        p.national_id,
        p.nombres,
        p.apellidos,
        p.numero_movil,
        p.email,
        p.pais,
        p.nickname
    FROM
        public.personas p
    WHERE
        p.persona_lider_redconf_id = v_lider_id
    AND
        p.flag_red_confianza is true
    ORDER BY
        p.nombres ASC;
END;
$BODY$;

