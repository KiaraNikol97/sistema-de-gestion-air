// src/controllers/AsambleistaControllers.js
const db = require('../config/db');

async function mostrarAsambleistas(req, res) {
    try {
        const result = await db.query(`
            SELECT id_asambleista, cedula, nombre, correo_institucional 
            FROM asambleista ORDER BY nombre
        `);
        res.json({ success: true, data: result.rows });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error' });
    }
}

async function registrarAsambleista(req, res) {
    try {
        const { cedula, nombre, correo_institucional } = req.body;
        
        if (!cedula || !nombre) {
            return res.status(400).json({ success: false, message: 'Cédula y nombre son obligatorios' });
        }
        
        // Verificar si ya existe
        const existe = await db.query('SELECT id_asambleista FROM asambleista WHERE cedula = $1', [cedula]);
        if (existe.rows.length > 0) {
            return res.status(409).json({ success: false, message: 'Ya existe un asambleísta con esa cédula' });
        }
        
        await db.query(
            'INSERT INTO asambleista (cedula, nombre, correo_institucional) VALUES ($1, $2, $3)',
            [cedula, nombre, correo_institucional || null]
        );
        
        res.json({ success: true, message: 'Asambleísta registrado' });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error al registrar' });
    }
}

// === FUNCIÓN DE EDICIÓN CORREGIDA ===
async function editarAsambleista(req, res) {
    try {
        const { id } = req.params;
        const { cedula, nombre, correo_institucional } = req.body;
        
        if (!cedula || !nombre) {
            return res.status(400).json({ success: false, message: 'Cédula y nombre son obligatorios' });
        }
        
        // IMPORTANTE: Buscar si existe OTRA persona con la misma cédula (excluyendo la actual)
        const existe = await db.query(
            'SELECT id_asambleista FROM asambleista WHERE cedula = $1 AND id_asambleista != $2',
            [cedula, id]
        );
        
        if (existe.rows.length > 0) {
            return res.status(409).json({ success: false, message: 'Ya existe otro asambleísta con esa cédula' });
        }
        
        // Actualizar sin validar la propia cédula
        await db.query(
            'UPDATE asambleista SET cedula = $1, nombre = $2, correo_institucional = $3 WHERE id_asambleista = $4',
            [cedula, nombre, correo_institucional || null, id]
        );
        
        res.json({ success: true, message: 'Asambleísta actualizado' });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al editar' });
    }
}

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
        res.status(500).json({ success: false, message: 'Error al buscar' });
    }
}

async function obtenerAsambleistaPorId(req, res) {
    try {
        const { id } = req.params;
        const result = await db.query(`
            SELECT id_asambleista, cedula, nombre, correo_institucional 
            FROM asambleista WHERE id_asambleista = $1
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'No encontrado' });
        }
        
        res.json({ success: true, data: result.rows[0] });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error' });
    }
}

module.exports = {
    mostrarAsambleistas,
    registrarAsambleista,
    editarAsambleista,
    buscarAsambleistas,
    obtenerAsambleistaPorId
};