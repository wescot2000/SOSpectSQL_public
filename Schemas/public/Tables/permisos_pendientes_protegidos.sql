-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.permisos_pendientes_protegidos

-- DROP TABLE IF EXISTS public.permisos_pendientes_protegidos;

CREATE TABLE IF NOT EXISTS public.permisos_pendientes_protegidos
(
    permiso_pendiente_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id_protector bigint NOT NULL,
    persona_id_protegido bigint NOT NULL,
    tiempo_subscripcion_dias integer,
    fecha_solicitud timestamp with time zone,
    flag_aprobado boolean DEFAULT false,
    fecha_aprobado timestamp with time zone,
    tiporelacion_id integer,
    CONSTRAINT pk_permisos_pendientes_protegidos PRIMARY KEY (permiso_pendiente_id),
    CONSTRAINT fk_permisos_pendientes_protegidos_reference_personas FOREIGN KEY (persona_id_protector)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_permisos_pendientes_protegidos_reference_personas2 FOREIGN KEY (persona_id_protegido)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_permisos_pendientes_protegidos_reference_tiporelacion FOREIGN KEY (tiporelacion_id)
        REFERENCES public.tiporelacion (tiporelacion_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;


