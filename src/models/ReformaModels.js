// :::::::::::::::::::::::::::::::::::::::::::::::::
// ISSUE #15 - Modelo de Reformas y Versionamiento
// Autora: María Fernanda Vargas Guzmán
// Sprint 2 - Semana 2 
// Modelo MVC
// CORREGIDO para PostgreSQL/Supabase
// :::::::::::::::::::::::::::::::::::::::::::::::::

const db = require('../config/db');

class ReformaModels {

    async registrarReforma(datos) {
        const sql = `
            INSERT INTO reforma_aplicada (
                id_resolucion,
                id_elemento_normativo,
                texto_anterior,
                texto_nuevo,
                fecha_inicio_vigencia,
                id_tipo_reforma,
                id_usuario_registro
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id_reforma
        `;

        const valores = [
            datos.id_resolucion || null,
            datos.id_elemento_normativo,
            datos.texto_anterior,
            datos.texto_nuevo,
            datos.fecha_inicio_vigencia,
            datos.id_tipo_reforma,
            datos.id_usuario_registro || 1
        ];

        const resultado = await db.query(sql, valores);
        return resultado.rows[0];
    }

    async obtenerElementoVigente(id_reglamento, numero_etiqueta) {
        const sql = `
            SELECT *
            FROM elemento_normativo
            WHERE id_reglamento = $1
              AND numero_etiqueta = $2
              AND fecha_fin_vigencia IS NULL
            LIMIT 1
        `;

        const resultado = await db.query(sql, [id_reglamento, numero_etiqueta]);
        return resultado.rows[0];
    }

    async obtenerHistorialVersiones(id_reglamento, numero_etiqueta) {
        const sql = `
            SELECT *
            FROM elemento_normativo
            WHERE id_reglamento = $1
              AND numero_etiqueta = $2
            ORDER BY fecha_inicio_vigencia DESC
        `;

        const resultado = await db.query(sql, [id_reglamento, numero_etiqueta]);
        return resultado.rows;
    }
}

module.exports = ReformaModels;
