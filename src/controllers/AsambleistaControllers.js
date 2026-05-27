// src/controllers/AsambleistaControllers.js
const db = require('../config/db');

// Mostrar listado de asambleístas
async function mostrarAsambleistas(req, res) {
    try {
        const result = await db.query(`
            SELECT id_asambleista, cedula, nombre, correo_institucional 
            FROM asambleista 
            ORDER BY nombre
        `);
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al mostrar asambleístas' });
    }
}

// Registrar nuevo asambleísta
async function registrarAsambleista(req, res) {
    try {
        const { cedula, nombre, correo_institucional } = req.body;
        
        if (!cedula || !nombre) {
            return res.status(400).json({ success: false, message: 'Cédula y nombre son obligatorios' });
        }
        
        const formatoCedula = /^[0-9]-[0-9]{4}-[0-9]{4}$/;
        if (!formatoCedula.test(cedula)) {
            return res.status(400).json({ success: false, message: 'Formato de cédula inválido' });
        }
        
        const existe = await db.query('SELECT id_asambleista FROM asambleista WHERE cedula = $1', [cedula]);
        if (existe.rows.length > 0) {
            return res.status(409).json({ success: false, message: 'Ya existe un asambleísta con esa cédula' });
        }
        
        await db.query(
            'INSERT INTO asambleista (cedula, nombre, correo_institucional) VALUES ($1, $2, $3)',
            [cedula, nombre, correo_institucional || null]
        );
        
        res.json({ success: true, message: 'Asambleísta registrado exitosamente' });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al registrar asambleísta' });
    }
}

// Buscar asambleístas
async function buscarAsambleistas(req, res) {
    try {
        const { buscar, q } = req.query;
        const termino = buscar || q;
        
        if (!termino) {
            return mostrarAsambleistas(req, res);
        }
        
        const result = await db.query(`
            SELECT id_asambleista, cedula, nombre, correo_institucional 
            FROM asambleista 
            WHERE nombre ILIKE $1 OR cedula ILIKE $1
            ORDER BY nombre
        `, [`%${termino}%`]);
        
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al buscar asambleístas' });
    }
}

// Obtener asambleísta por ID
async function obtenerAsambleistaPorId(req, res) {
    try {
        const { id } = req.params;
        const result = await db.query(`
            SELECT id_asambleista, cedula, nombre, correo_institucional 
            FROM asambleista 
            WHERE id_asambleista = $1
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Asambleísta no encontrado' });
        }
        
        res.json({ success: true, data: result.rows[0] });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al obtener asambleísta' });
    }
}

// Editar asambleísta
async function editarAsambleista(req, res) {
    try {
        const { id } = req.params;
        const { cedula, nombre, correo_institucional } = req.body;
        
        await db.query(
            'UPDATE asambleista SET cedula = $1, nombre = $2, correo_institucional = $3 WHERE id_asambleista = $4',
            [cedula, nombre, correo_institucional, id]
        );
        
        res.json({ success: true, message: 'Asambleísta actualizado' });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al editar asambleísta' });
    }
}

module.exports = {
    mostrarAsambleistas,
    registrarAsambleista,
    buscarAsambleistas,
    obtenerAsambleistaPorId,
    editarAsambleista
};