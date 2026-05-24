-- ==========================================
-- ISSUE 13 - BITÁCORA DE AUDITORÍA
-- ==========================================

ALTER TABLE sys_log_auditoria
ADD COLUMN IF NOT EXISTS registro_id BIGINT;

ALTER TABLE sys_log_auditoria
ADD COLUMN IF NOT EXISTS ip_origen VARCHAR(45);

CREATE OR REPLACE FUNCTION registrar_auditoria()
RETURNS TRIGGER AS $$
DECLARE
    v_id_usuario INTEGER;
    v_registro_id BIGINT;
    v_ip_origen VARCHAR(45);
    v_detalle TEXT;
BEGIN
    v_id_usuario := NULLIF(current_setting('app.current_user_id', true), '')::INTEGER;
    v_ip_origen := NULLIF(current_setting('app.ip_origen', true), '');

    IF TG_TABLE_NAME = 'asambleista' THEN
        IF TG_OP = 'DELETE' THEN
            v_registro_id := OLD.id_asambleista;
        ELSE
            v_registro_id := NEW.id_asambleista;
        END IF;

    ELSIF TG_TABLE_NAME = 'elemento_normativo' THEN
        IF TG_OP = 'DELETE' THEN
            v_registro_id := OLD.id_elemento;
        ELSE
            v_registro_id := NEW.id_elemento;
        END IF;

    ELSIF TG_TABLE_NAME = 'nombramiento' THEN
        IF TG_OP = 'DELETE' THEN
            v_registro_id := OLD.id_nombramiento;
        ELSE
            v_registro_id := NEW.id_nombramiento;
        END IF;
    END IF;

    v_detalle := 'Operación ' || TG_OP || ' en la tabla ' || TG_TABLE_NAME || '. ID: ' || COALESCE(v_registro_id::TEXT, 'N/A');

    INSERT INTO sys_log_auditoria (
        id_usuario,
        accion,
        tabla_afectada,
        registro_id,
        detalle,
        ip_origen
    )
    VALUES (
        v_id_usuario,
        TG_OP,
        TG_TABLE_NAME,
        v_registro_id,
        v_detalle,
        v_ip_origen
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_auditoria_asambleista ON asambleista;
CREATE TRIGGER tg_auditoria_asambleista
AFTER INSERT OR UPDATE OR DELETE ON asambleista
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();

DROP TRIGGER IF EXISTS tg_auditoria_normativa ON elemento_normativo;
CREATE TRIGGER tg_auditoria_normativa
AFTER INSERT OR UPDATE OR DELETE ON elemento_normativo
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();

DROP TRIGGER IF EXISTS tg_auditoria_nombramientos ON nombramiento;
CREATE TRIGGER tg_auditoria_nombramientos
AFTER INSERT OR UPDATE OR DELETE ON nombramiento
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();

CREATE OR REPLACE FUNCTION registrar_login_auditoria(
    p_id_usuario INTEGER,
    p_exitoso BOOLEAN,
    p_ip_origen VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO sys_log_auditoria (
        id_usuario,
        accion,
        tabla_afectada,
        registro_id,
        detalle,
        ip_origen
    )
    VALUES (
        p_id_usuario,
        CASE 
            WHEN p_exitoso THEN 'LOGIN'
            ELSE 'LOGIN_FALLIDO'
        END,
        'sys_usuario',
        p_id_usuario,
        CASE 
            WHEN p_exitoso THEN 'Inicio de sesión exitoso'
            ELSE 'Intento de inicio de sesión fallido'
        END,
        p_ip_origen
    );
END;
$$ LANGUAGE plpgsql;
