-- ==========================================
-- ISSUE 13 - BITÁCORA DE AUDITORÍA
-- ==========================================

ALTER TABLE sys_log_auditoria
    ADD COLUMN IF NOT EXISTS usuario_bd TEXT DEFAULT CURRENT_USER,
    ADD COLUMN IF NOT EXISTS operacion VARCHAR(20),
    ADD COLUMN IF NOT EXISTS registro_pk TEXT,
    ADD COLUMN IF NOT EXISTS datos_antes JSONB,
    ADD COLUMN IF NOT EXISTS datos_despues JSONB,
    ADD COLUMN IF NOT EXISTS fecha_hora_servidor TIMESTAMP DEFAULT CLOCK_TIMESTAMP(),
    ADD COLUMN IF NOT EXISTS nivel_riesgo VARCHAR(20) DEFAULT 'Normal',
    ADD COLUMN IF NOT EXISTS modulo_origen VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_log_auditoria_tabla
ON sys_log_auditoria(tabla_afectada);

CREATE INDEX IF NOT EXISTS idx_log_auditoria_fecha
ON sys_log_auditoria(fecha_hora_servidor);

CREATE INDEX IF NOT EXISTS idx_log_auditoria_usuario
ON sys_log_auditoria(id_usuario);

CREATE INDEX IF NOT EXISTS idx_log_auditoria_operacion
ON sys_log_auditoria(operacion);

CREATE OR REPLACE VIEW v_auditoria_forense AS
SELECT
    id_log,
    id_usuario,
    usuario_bd,
    accion,
    operacion,
    tabla_afectada,
    registro_pk,
    modulo_origen,
    nivel_riesgo,
    ip_origen,
    fecha_hora_servidor,
    datos_antes,
    datos_despues,
    detalle
FROM sys_log_auditoria
ORDER BY fecha_hora_servidor DESC;

-- ===========================
-- FUNCIONES Y TRIGGERS
-- ===========================

CREATE OR REPLACE FUNCTION fn_auditoria_forense()
RETURNS TRIGGER AS $$
DECLARE
    v_id_usuario INTEGER;
    v_ip_origen TEXT;
    v_registro_pk TEXT;
    v_modulo TEXT;
    v_riesgo TEXT;
BEGIN
    BEGIN
        v_id_usuario := NULLIF(current_setting('app.current_user_id', TRUE), '')::INTEGER;
    EXCEPTION WHEN OTHERS THEN
        v_id_usuario := NULL;
    END;

    BEGIN
        v_ip_origen := NULLIF(current_setting('app.ip_origen', TRUE), '');
    EXCEPTION WHEN OTHERS THEN
        v_ip_origen := NULL;
    END;

    IF v_ip_origen IS NULL THEN
        v_ip_origen := INET_CLIENT_ADDR()::TEXT;
    END IF;

    IF TG_TABLE_NAME = 'asambleista' THEN
        v_registro_pk := COALESCE(NEW.id_asambleista, OLD.id_asambleista)::TEXT;
        v_modulo := 'Gestión de Asambleístas';
    ELSIF TG_TABLE_NAME = 'nombramiento' THEN
        v_registro_pk := COALESCE(NEW.id_nombramiento, OLD.id_nombramiento)::TEXT;
        v_modulo := 'Nombramientos';
    ELSIF TG_TABLE_NAME = 'propuesta' THEN
        v_registro_pk := COALESCE(NEW.id_propuesta, OLD.id_propuesta)::TEXT;
        v_modulo := 'Propuestas';
    ELSIF TG_TABLE_NAME = 'votacion' THEN
        v_registro_pk := COALESCE(NEW.id_votacion, OLD.id_votacion)::TEXT;
        v_modulo := 'Votaciones';
    ELSIF TG_TABLE_NAME = 'voto_asambleista' THEN
        v_registro_pk := COALESCE(NEW.id_voto_asambleista, OLD.id_voto_asambleista)::TEXT;
        v_modulo := 'Motor de Votaciones';
    ELSIF TG_TABLE_NAME = 'resultado_votacion' THEN
        v_registro_pk := COALESCE(NEW.id_resultado_votacion, OLD.id_resultado_votacion)::TEXT;
        v_modulo := 'Resultado de Votación';
    ELSIF TG_TABLE_NAME = 'elemento_normativo' THEN
        v_registro_pk := COALESCE(NEW.id_elemento, OLD.id_elemento)::TEXT;
        v_modulo := 'Normativa';
    ELSE
        v_registro_pk := 'N/A';
        v_modulo := 'General';
    END IF;

    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        v_riesgo := 'Alto';
    ELSE
        v_riesgo := 'Normal';
    END IF;

    INSERT INTO sys_log_auditoria (
        id_usuario,
        accion,
        operacion,
        tabla_afectada,
        registro_pk,
        detalle,
        ip_origen,
        usuario_bd,
        datos_antes,
        datos_despues,
        fecha_hora_servidor,
        nivel_riesgo,
        modulo_origen
    )
    VALUES (
        v_id_usuario,
        TG_OP,
        TG_OP,
        TG_TABLE_NAME,
        v_registro_pk,
        'Auditoría forense automática. Tabla: ' || TG_TABLE_NAME || ', operación: ' || TG_OP,
        v_ip_origen,
        CURRENT_USER,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN TO_JSONB(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN TO_JSONB(NEW) ELSE NULL END,
        CLOCK_TIMESTAMP(),
        v_riesgo,
        v_modulo
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_auditoria_forense_asambleista
AFTER INSERT OR UPDATE OR DELETE ON asambleista
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_nombramiento
AFTER INSERT OR UPDATE OR DELETE ON nombramiento
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_elemento_normativo
AFTER INSERT OR UPDATE OR DELETE ON elemento_normativo
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_propuesta
AFTER INSERT OR UPDATE OR DELETE ON propuesta
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_votacion
AFTER INSERT OR UPDATE OR DELETE ON votacion
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_voto_asambleista
AFTER INSERT OR UPDATE OR DELETE ON voto_asambleista
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_resultado_votacion
AFTER INSERT OR UPDATE OR DELETE ON resultado_votacion
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();
