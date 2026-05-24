-- ==========================================
-- ISSUE 13 - BITÁCORA DE AUDITORÍA
-- ==========================================

CREATE TABLE IF NOT EXISTS sys_log_auditoria (
    id_log BIGSERIAL PRIMARY KEY,
    id_usuario BIGINT,
    accion VARCHAR(20) NOT NULL,
    tabla_afectada VARCHAR(100) NOT NULL,
    registro_id BIGINT,
    detalle TEXT,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION registrar_auditoria()
RETURNS TRIGGER AS $$
DECLARE
    v_id_usuario BIGINT;
    v_registro_id BIGINT;
    v_detalle TEXT;
BEGIN
    v_id_usuario := NULLIF(current_setting('app.current_user_id', true), '')::BIGINT;

    IF TG_OP = 'INSERT' THEN
        v_registro_id := COALESCE(NEW.asambleista_id, NEW.id_elemento, NEW.id_nombramiento);
        v_detalle := 'Registro creado';
    ELSIF TG_OP = 'UPDATE' THEN
        v_registro_id := COALESCE(NEW.asambleista_id, NEW.id_elemento, NEW.id_nombramiento);
        v_detalle := 'Registro actualizado';
    ELSIF TG_OP = 'DELETE' THEN
        v_registro_id := COALESCE(OLD.asambleista_id, OLD.id_elemento, OLD.id_nombramiento);
        v_detalle := 'Registro eliminado';
    END IF;

    INSERT INTO sys_log_auditoria (
        id_usuario,
        accion,
        tabla_afectada,
        registro_id,
        detalle
    )
    VALUES (
        v_id_usuario,
        TG_OP,
        TG_TABLE_NAME,
        v_registro_id,
        v_detalle
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

DROP TRIGGER IF EXISTS tg_auditoria_elemento_normativo ON elemento_normativo;

CREATE TRIGGER tg_auditoria_elemento_normativo
AFTER INSERT OR UPDATE OR DELETE ON elemento_normativo
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();

DROP TRIGGER IF EXISTS tg_auditoria_nombramiento ON nombramiento;

CREATE TRIGGER tg_auditoria_nombramiento
AFTER INSERT OR UPDATE OR DELETE ON nombramiento
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();
