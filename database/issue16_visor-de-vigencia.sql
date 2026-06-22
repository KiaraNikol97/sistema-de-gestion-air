-- =====================================================
-- ISSUE 16 - VISOR DE VIGENCIA / COMPILADOR HISTÓRICO
-- =====================================================

ALTER TABLE elemento_normativo
    ADD COLUMN IF NOT EXISTS id_propuesta_origen INTEGER,
    ADD COLUMN IF NOT EXISTS id_votacion_origen INTEGER,
    ADD COLUMN IF NOT EXISTS observacion_vigencia TEXT;

ALTER TABLE elemento_normativo
    ADD CONSTRAINT fk_elemento_propuesta_origen
        FOREIGN KEY (id_propuesta_origen)
        REFERENCES propuesta(id_propuesta)
        ON DELETE SET NULL;

ALTER TABLE elemento_normativo
    ADD CONSTRAINT fk_elemento_votacion_origen
        FOREIGN KEY (id_votacion_origen)
        REFERENCES votacion(id_votacion)
        ON DELETE SET NULL;

-- Índices
CREATE INDEX IF NOT EXISTS idx_elemento_fechas_vigencia
ON elemento_normativo (
    id_reglamento,
    fecha_inicio_vigencia,
    fecha_fin_vigencia
);

CREATE INDEX IF NOT EXISTS idx_elemento_propuesta_origen
ON elemento_normativo(id_propuesta_origen);

CREATE INDEX IF NOT EXISTS idx_elemento_votacion_origen
ON elemento_normativo(id_votacion_origen);

-- ========================
-- FUNCIONES Y TRIGGERS
-- ========================

CREATE OR REPLACE FUNCTION obtener_texto_vigente_en_fecha(
    p_id_reglamento INTEGER,
    p_fecha_consulta DATE
)
RETURNS JSONB AS $$
DECLARE
    resultado JSONB;
BEGIN
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'id_elemento', e.id_elemento,
                'id_padre', e.id_elemento_padre,
                'nivel', cnr.nombre,
                'numero', e.numero_etiqueta,
                'contenido', e.contenido_texto,
                'orden', e.orden,
                'vigencia_inicio', e.fecha_inicio_vigencia,
                'vigencia_fin', e.fecha_fin_vigencia,
                'estado', cev.nombre,
                'propuesta_origen', p.numero_propuesta,
                'votacion_origen', v.numero_votacion
            )
            ORDER BY cnr.orden, e.orden, e.numero_etiqueta
        ),
        '[]'::jsonb
    )
    INTO resultado
    FROM elemento_normativo e
    JOIN catalogo_nivel_reglamento cnr
        ON e.id_nivel_reglamento = cnr.id_nivel_reglamento
    JOIN catalogo_estado_vigencia cev
        ON e.id_estado_vigencia = cev.id_estado_vigencia
    LEFT JOIN propuesta p
        ON e.id_propuesta_origen = p.id_propuesta
    LEFT JOIN votacion v
        ON e.id_votacion_origen = v.id_votacion
    WHERE e.id_reglamento = p_id_reglamento
      AND e.fecha_inicio_vigencia <= p_fecha_consulta
      AND (
            e.fecha_fin_vigencia IS NULL
            OR e.fecha_fin_vigencia > p_fecha_consulta
          )
    ORDER BY e.orden;

    RETURN resultado;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION obtener_arbol_normativo_vigente(
    p_id_reglamento INTEGER,
    p_fecha_consulta DATE
)
RETURNS TABLE (
    id_elemento INTEGER,
    id_elemento_padre INTEGER,
    nivel TEXT,
    numero_etiqueta VARCHAR,
    contenido_texto TEXT,
    profundidad INTEGER,
    ruta TEXT,
    fecha_inicio_vigencia DATE,
    fecha_fin_vigencia DATE
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE arbol AS (
        SELECT
            e.id_elemento,
            e.id_elemento_padre,
            cnr.nombre::TEXT AS nivel,
            e.numero_etiqueta,
            e.contenido_texto,
            1 AS profundidad,
            e.numero_etiqueta::TEXT AS ruta,
            e.fecha_inicio_vigencia,
            e.fecha_fin_vigencia,
            e.orden
        FROM elemento_normativo e
        JOIN catalogo_nivel_reglamento cnr
            ON e.id_nivel_reglamento = cnr.id_nivel_reglamento
        WHERE e.id_reglamento = p_id_reglamento
          AND e.id_elemento_padre IS NULL
          AND e.fecha_inicio_vigencia <= p_fecha_consulta
          AND (
                e.fecha_fin_vigencia IS NULL
                OR e.fecha_fin_vigencia > p_fecha_consulta
              )

        UNION ALL

        SELECT
            hijo.id_elemento,
            hijo.id_elemento_padre,
            cnr.nombre::TEXT AS nivel,
            hijo.numero_etiqueta,
            hijo.contenido_texto,
            padre.profundidad + 1,
            padre.ruta || ' > ' || hijo.numero_etiqueta,
            hijo.fecha_inicio_vigencia,
            hijo.fecha_fin_vigencia,
            hijo.orden
        FROM elemento_normativo hijo
        JOIN arbol padre
            ON hijo.id_elemento_padre = padre.id_elemento
        JOIN catalogo_nivel_reglamento cnr
            ON hijo.id_nivel_reglamento = cnr.id_nivel_reglamento
        WHERE hijo.fecha_inicio_vigencia <= p_fecha_consulta
          AND (
                hijo.fecha_fin_vigencia IS NULL
                OR hijo.fecha_fin_vigencia > p_fecha_consulta
              )
    )
    SELECT
        a.id_elemento,
        a.id_elemento_padre,
        a.nivel,
        a.numero_etiqueta,
        a.contenido_texto,
        a.profundidad,
        a.ruta,
        a.fecha_inicio_vigencia,
        a.fecha_fin_vigencia
    FROM arbol a
    ORDER BY a.ruta, a.orden;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION obtener_historial_elemento(
    p_id_elemento INTEGER
)
RETURNS JSONB AS $$
DECLARE
    v_reglamento INTEGER;
    v_padre INTEGER;
    v_etiqueta VARCHAR;
    resultado JSONB;
BEGIN
    SELECT id_reglamento, id_elemento_padre, numero_etiqueta
    INTO v_reglamento, v_padre, v_etiqueta
    FROM elemento_normativo
    WHERE id_elemento = p_id_elemento;

    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'id_elemento', e.id_elemento,
                'numero_etiqueta', e.numero_etiqueta,
                'contenido', e.contenido_texto,
                'fecha_inicio_vigencia', e.fecha_inicio_vigencia,
                'fecha_fin_vigencia', e.fecha_fin_vigencia,
                'estado', cev.nombre,
                'propuesta_origen', p.numero_propuesta,
                'votacion_origen', v.numero_votacion,
                'observacion', e.observacion_vigencia
            )
            ORDER BY e.fecha_inicio_vigencia
        ),
        '[]'::jsonb
    )
    INTO resultado
    FROM elemento_normativo e
    JOIN catalogo_estado_vigencia cev
        ON e.id_estado_vigencia = cev.id_estado_vigencia
    LEFT JOIN propuesta p
        ON e.id_propuesta_origen = p.id_propuesta
    LEFT JOIN votacion v
        ON e.id_votacion_origen = v.id_votacion
    WHERE e.id_reglamento = v_reglamento
      AND COALESCE(e.id_elemento_padre, 0) = COALESCE(v_padre, 0)
      AND e.numero_etiqueta = v_etiqueta;

    RETURN resultado;
END;
$$ LANGUAGE plpgsql STABLE;


-- ======================
-- VISTAS
-- ======================

CREATE OR REPLACE VIEW v_historial_vigencia_elemento AS
SELECT
    e.id_elemento,
    r.id_reglamento,
    r.nombre_normativa,
    r.sigla,
    e.id_elemento_padre,
    cnr.nombre AS nivel,
    e.numero_etiqueta,
    e.contenido_texto,
    e.orden,
    e.fecha_inicio_vigencia,
    e.fecha_fin_vigencia,
    cev.nombre AS estado_vigencia,
    p.numero_propuesta AS propuesta_origen,
    p.titulo AS titulo_propuesta,
    v.numero_votacion AS votacion_origen,
    v.resultado AS resultado_votacion,
    e.observacion_vigencia
FROM elemento_normativo e
JOIN reglamento r
    ON e.id_reglamento = r.id_reglamento
JOIN catalogo_nivel_reglamento cnr
    ON e.id_nivel_reglamento = cnr.id_nivel_reglamento
JOIN catalogo_estado_vigencia cev
    ON e.id_estado_vigencia = cev.id_estado_vigencia
LEFT JOIN propuesta p
    ON e.id_propuesta_origen = p.id_propuesta
LEFT JOIN votacion v
    ON e.id_votacion_origen = v.id_votacion;

CREATE OR REPLACE VIEW v_trazabilidad_normativa AS
SELECT
    e.id_elemento,
    r.nombre_normativa,
    e.numero_etiqueta,
    e.contenido_texto,
    e.fecha_inicio_vigencia,
    e.fecha_fin_vigencia,
    cev.nombre AS estado_vigencia,
    p.numero_propuesta,
    p.titulo AS titulo_propuesta,
    rv.resultado AS resultado_votacion,
    rv.porcentaje_aprobacion,
    s.numero_sesion,
    s.fecha AS fecha_sesion
FROM elemento_normativo e
JOIN reglamento r
    ON e.id_reglamento = r.id_reglamento
JOIN catalogo_estado_vigencia cev
    ON e.id_estado_vigencia = cev.id_estado_vigencia
LEFT JOIN propuesta p
    ON e.id_propuesta_origen = p.id_propuesta
LEFT JOIN votacion v
    ON e.id_votacion_origen = v.id_votacion
LEFT JOIN resultado_votacion rv
    ON v.id_votacion = rv.id_votacion
LEFT JOIN sesion s
    ON v.id_sesion = s.id_sesion;

CREATE OR REPLACE VIEW v_compilador_historico_fecha AS
SELECT
    e.id_elemento,
    r.id_reglamento,
    r.nombre_normativa,
    r.sigla,
    e.id_elemento_padre,
    cnr.nombre AS nivel,
    e.numero_etiqueta,
    e.contenido_texto,
    e.orden,
    e.fecha_inicio_vigencia,
    e.fecha_fin_vigencia,
    cev.nombre AS estado_vigencia,
    p.numero_propuesta AS propuesta_origen,
    v.numero_votacion AS votacion_origen
FROM elemento_normativo e
JOIN reglamento r
    ON e.id_reglamento = r.id_reglamento
JOIN catalogo_nivel_reglamento cnr
    ON e.id_nivel_reglamento = cnr.id_nivel_reglamento
JOIN catalogo_estado_vigencia cev
    ON e.id_estado_vigencia = cev.id_estado_vigencia
LEFT JOIN propuesta p
    ON e.id_propuesta_origen = p.id_propuesta
LEFT JOIN votacion v
    ON e.id_votacion_origen = v.id_votacion;
