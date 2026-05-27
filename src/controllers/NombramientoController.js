// src/controllers/NombramientoController.js
const db = require('../config/db');

// Obtener historial de nombramientos
async function getHistorialAsambleista(req, res) {
    try {
        const { asambleista_id } = req.params;
        
        const result = await db.query(`
            SELECT 
                n.id_nombramiento,
                s.nombre as sector,
                p.nombre_puesto as puesto,
                n.fecha_inicio,
                n.fecha_fin,
                n.estado,
                CASE 
                    WHEN n.fecha_fin IS NULL AND n.estado = 'Activo' THEN 'Vigente'
                    WHEN n.fecha_fin < CURRENT_DATE THEN 'Vencido'
                    ELSE n.estado
                END as estado_real
            FROM nombramiento n
            JOIN catalogo_sector s ON n.id_sector = s.id_sector
            JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
            WHERE n.id_asambleista = $1
            ORDER BY n.fecha_inicio DESC
        `, [asambleista_id]);
        
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al obtener historial' });
    }
}

// Obtener sector vigente
async function getSectorVigente(req, res) {
    try {
        const { asambleista_id } = req.params;
        
        const result = await db.query(`
            SELECT 
                s.nombre as sector,
                p.nombre_puesto as puesto,
                n.fecha_inicio as desde,
                n.fecha_fin as hasta
            FROM nombramiento n
            JOIN catalogo_sector s ON n.id_sector = s.id_sector
            JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
            WHERE n.id_asambleista = $1 
              AND n.estado = 'Activo' 
              AND (n.fecha_fin IS NULL OR n.fecha_fin >= CURRENT_DATE)
            LIMIT 1
        `, [asambleista_id]);
        
        if (result.rows.length === 0) {
            return res.json({ success: false, data: null });
        }
        
        res.json({ success: true, data: result.rows[0] });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al obtener sector vigente' });
    }
}

// Registrar nombramiento
async function registrarNombramiento(req, res) {
    try {
        const { asambleista_id, sector_id, id_puesto, fecha_inicio, fecha_fin, observaciones } = req.body;
        
        const result = await db.query(`
            INSERT INTO nombramiento 
            (id_asambleista, id_sector, id_puesto, fecha_inicio, fecha_fin, observaciones, estado, id_usuario_registro)
            VALUES ($1, $2, $3, $4, $5, $6, 'Activo', 1)
            RETURNING id_nombramiento
        `, [asambleista_id, sector_id, id_puesto, fecha_inicio, fecha_fin || null, observaciones || null]);
        
        res.json({ success: true, message: 'Nombramiento registrado', id: result.rows[0].id_nombramiento });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al registrar nombramiento' });
    }
}

// Finalizar nombramiento
async function finalizarNombramiento(req, res) {
    try {
        const { id } = req.params;
        const { fecha_fin } = req.body;
        
        await db.query(`
            UPDATE nombramiento 
            SET fecha_fin = $1, estado = 'Finalizado'
            WHERE id_nombramiento = $2
        `, [fecha_fin, id]);
        
        res.json({ success: true, message: 'Nombramiento finalizado' });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al finalizar nombramiento' });
    }
}

module.exports = {
    getHistorialAsambleista,
    getSectorVigente,
    registrarNombramiento,
    finalizarNombramiento
};