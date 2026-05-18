// :::::::::::::::::::::::::::::::::::::::::::::::::
// ISSUE #9 - Catálogo de Asambleístas
// Autora: María Fernanda Vargas Guzmán
// Sprint 2 - Semana 2 
// Modelo MVC
// :::::::::::::::::::::::::::::::::::::::::::::::::

// Conectarse
const db = require("../config/db");

// Crear asambleísta
async function crearAsambleista(cedula, nombre, correo) {

    const sql = `
        INSERT INTO asambleista (
            cedula,
            nombre,
            correo_institucional
        )
        VALUES (?, ?, ?)
    `;

    const [resultado] = await db.query(sql, [
        cedula,
        nombre,
        correo
    ]);

    return resultado;
}

// Buscar por cédula
async function buscarPorCedula(cedula) {

    const sql = `
        SELECT *
        FROM asambleista
        WHERE cedula = ?
    `;

    const [filas] = await db.query(sql, [cedula]);

    return filas[0];
}

// Listar asambleístas
async function listarAsambleistas() {

    const sql = `
        SELECT *
        FROM asambleista
        ORDER BY nombre ASC
    `;

    const [filas] = await db.query(sql);

    return filas;
}

module.exports = {
    crearAsambleista,
    buscarPorCedula,
    listarAsambleistas
};
