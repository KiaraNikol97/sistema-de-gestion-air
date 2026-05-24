-- =====================================================
-- ISSUE 16 - VISOR DE VIGENCIA / COMPILADOR HISTÓRICO
-- =====================================================


CREATE OR REPLACE FUNCTION obtener_texto_vigente_en_fecha(
    p_id_reglamento BIGINT,
    p_fecha_consulta DATE
)
RETURNS JSONB AS $$
DECLARE
    resultado JSONB;
BEGIN
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'id', e.id_elemento,
                'numero', e.numero_etiqueta,
                'contenido', e.contenido_texto,
                'vigencia_inicio', e.fecha_inicio_vigencia,
                'vigencia_fin', e.fecha_fin_vigencia,
                'nivel', cnr.nombre
            )
            ORDER BY e.orden
        ),
        '[]'::jsonb
    )
    INTO resultado
    FROM elemento_normativo e
    JOIN catalogo_nivel_reglamento cnr
        ON e.id_nivel_reglamento = cnr.id_nivel_reglamento
    WHERE e.id_reglamento = p_id_reglamento
      AND e.fecha_inicio_vigencia <= p_fecha_consulta
      AND (
            e.fecha_fin_vigencia IS NULL
            OR e.fecha_fin_vigencia > p_fecha_consulta
          );

    RETURN resultado;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE INDEX IF NOT EXISTS idx_elemento_fechas_vigencia
ON elemento_normativo (
    id_reglamento,
    fecha_inicio_vigencia,
    fecha_fin_vigencia
);
