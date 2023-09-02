-- PROCEDURE: public.insertacontratotraducido(character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.insertacontratotraducido(character varying, character varying);

CREATE OR REPLACE PROCEDURE public.insertacontratotraducido(
	IN p_texto_contrato_traducido character varying,
	IN p_idioma_dispositivo character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	v_contrato_id INTEGER;
	v_traduccion_existente INTEGER;
BEGIN
	BEGIN

		SELECT 
				contrato_id
			INTO 
				v_contrato_id
		FROM 
			condiciones_servicio cs
		WHERE
			cast(now() as timestamp with time zone) between cs.fecha_inicio_version and coalesce(cs.fecha_fin_version,cast(now() as timestamp with time zone));

		
		if 
			p_texto_contrato_traducido is null
		then	
			RAISE EXCEPTION 'El texto de contrato llego vacío tras la traduccion. No se puede insertar un valor nulo de texto de contrato, se debe mostrar en ingles';
		END IF;

		select 
			count(*)
		INTO
			v_traduccion_existente
		from 
			condiciones_servicio cs
		inner join 
			traducciones_contrato tc
		on 
			(tc.contrato_id=cs.contrato_id 
			and tc.fecha_traduccion 
				between cs.fecha_inicio_version 
				and coalesce(cs.fecha_fin_version,cast(now() as timestamp with time zone)) 
			and tc.idioma=p_idioma_dispositivo);

		if 
			v_traduccion_existente>0
		then	
			RAISE EXCEPTION 'El texto de contrato ya esta traducido al idioma seleccionado, verificar que puede estar causando el error';
		END IF;

		INSERT INTO
			traducciones_contrato
				(
					contrato_id
					,texto_traducido
					,idioma
					,fecha_traduccion
				)
			VALUES
				(
					v_contrato_id
					,p_texto_contrato_traducido
					,p_idioma_dispositivo
					,now()
				);
			
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.insertacontratotraducido(character varying, character varying)
    OWNER TO w4ll4c3;
