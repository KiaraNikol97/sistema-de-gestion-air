// :::::::::::::::::::::::::::::::::::::::::::::::::
// ISSUE #15 - Modelo de Reformas y Versionamiento
// Autora: María Fernanda Vargas Guzmán
// Sprint 2 - Semana 2 
// Modelo MVC
// :::::::::::::::::::::::::::::::::::::::::::::::::

// Conectar 
const db = require("../config/db");


class Reforma {

    // Registrar una reforma normativa
    async registrarReforma(datos) {

        /*
        Inserta una reforma en reforma_aplicada.
        La lógica de vigencia/versionamiento se maneja desde la BD
        mediante el trigger tg_vigencia_normativa.
        */

        const sql = `
            INSERT INTO reforma_aplicada (
                id_resolucion,
                id_elemento_normativo,
                texto_anterior,
                texto_nuevo,
                fecha_inicio_vigencia,
                id_tipo_reforma
            )
            VALUES (?, ?, ?, ?, ?, ?)
        `;

        const valores = [
            datos.id_resolucion,
            datos.id_elemento_normativo,
            datos.texto_anterior,
            datos.texto_nuevo,
            datos.fecha_inicio_vigencia,
            datos.id_tipo_reforma
        ];

        const [resultado] = await db.query(sql, valores);

        return resultado;
    }


    // Obtener versión vigente de un elemento normativo
    async obtenerElementoVigente(id_reglamento, numero_etiqueta) {

        const sql = `
            SELECT *
            FROM elemento_normativo
            WHERE id_reglamento = ?
              AND numero_etiqueta = ?
              AND fecha_fin_vigencia IS NULL
            LIMIT 1
        `;

        const [filas] = await db.query(sql, [
            id_reglamento,
            numero_etiqueta
        ]);

        return filas[0];
    }


    // Consultar historial de versiones
    async obtenerHistorialVersiones(id_reglamento, numero_etiqueta) {

        const sql = `
            SELECT *
            FROM elemento_normativo
            WHERE id_reglamento = ?
              AND numero_etiqueta = ?
            ORDER BY fecha_inicio_vigencia DESC
        `;

        const [filas] = await db.query(sql, [
            id_reglamento,
            numero_etiqueta
        ]);

        return filas;
    }
}

module.exports = Reforma;
