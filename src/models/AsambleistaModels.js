// :::::::::::::::::::::::::::::::::::::::::::::::::
// ISSUE #9 - Catálogo de Asambleístas
// Autora: María Fernanda Vargas Guzmán
// Sprint 2 - Semana 2 
// Modelo MVC
// :::::::::::::::::::::::::::::::::::::::::::::::::

// CORREGIDO para Supabase (ProstgreSQL)
const db = require('../config/db');

async function crearAsambleista(cedula, nombre, correo) {
    // PostgreSQL usa $1, $2, $3 en lugar de ?
    const sql = `
        INSERT INTO asambleista (cedula, nombre, correo_institucional)
        VALUES ($1, $2, $3)
        RETURNING id_asambleista
    `;
    const resultado = await db.query(sql, [cedula, nombre, correo]);
    return resultado.rows[0];
}

async function buscarPorCedula(cedula) {
    const sql = `SELECT * FROM asambleista WHERE cedula = $1`;
    const resultado = await db.query(sql, [cedula]);
    return resultado.rows[0];
}

async function listarAsambleistas() {
    const sql = `SELECT * FROM asambleista ORDER BY nombre ASC`;
    const resultado = await db.query(sql);
    return resultado.rows;
}

async function editarAsambleista(id_asambleista, cedula, nombre, correo) {
    const sql = `
        UPDATE asambleista 
        SET cedula = $1, nombre = $2, correo_institucional = $3
        WHERE id_asambleista = $4
        RETURNING *
    `;
    const resultado = await db.query(sql, [cedula, nombre, correo, id_asambleista]);
    return resultado.rows[0];
}

async function eliminarAsambleista(id_asambleista) {
    const sql = `DELETE FROM asambleista WHERE id_asambleista = $1`;
    await db.query(sql, [id_asambleista]);
}

async function obtenerBitacoraAsambleista(id_asambleista) {
    const sql = `
        SELECT * FROM bitacora_asambleistas 
        WHERE id_asambleista = $1 
        ORDER BY fecha_actualizacion DESC
    `;
    const resultado = await db.query(sql, [id_asambleista]);
    return resultado.rows;
}

async function buscarAsambleistas(textoBusqueda) {
    const sql = `
        SELECT * FROM asambleista 
        WHERE nombre ILIKE $1 OR cedula ILIKE $1
        ORDER BY nombre ASC
    `;
    const resultado = await db.query(sql, [`%${textoBusqueda}%`]);
    return resultado.rows;
}

module.exports = {
    crearAsambleista,
    buscarPorCedula,
    listarAsambleistas,
    editarAsambleista,
    eliminarAsambleista,
    obtenerBitacoraAsambleista,
    buscarAsambleistas
};
