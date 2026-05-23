
// Centralización de todas las rutas API del sistema

const express = require('express');
const router = express.Router();

// Importar controladores
const authController = require('../controllers/AuthController');
const asambleistaController = require('../controllers/AsambleistaControllers');
const nombramientoController = require('../controllers/NombramientoController');
const normativaController = require('../controllers/NormativaController');


// RUTAS DE AUTENTICACIÓN (Issue #0)
router.post('/api/auth/login', authController.login);
router.post('/api/auth/logout', (req, res) => {
    req.session.destroy();
    res.json({ success: true });
});
router.get('/api/auth/verificar', (req, res) => {
    if (req.session.userId) {
        res.json({ success: true, data: { userId: req.session.userId, rol: req.session.rol } });
    } else {
        res.json({ success: false });
    }
});


// RUTAS DE ASAMBLEÍSTAS (Issue #9)
router.get('/api/asambleistas', asambleistaController.mostrarAsambleistas);
router.post('/api/asambleistas/guardar', asambleistaController.registrarAsambleista);
router.get('/api/asambleistas/buscar', asambleistaController.buscarAsambleistas);
router.get('/api/asambleistas/:id', asambleistaController.obtenerAsambleistaPorId);


// RUTAS DE NOMBRAMIENTOS (Issue #14)
router.get('/api/catalogos/sectores', async (req, res) => {
    const db = require('../models/db');
    const [rows] = await db.query('SELECT id_sector, nombre FROM catalogo_sector WHERE activo = TRUE');
    res.json({ success: true, data: rows });
});
router.get('/api/catalogos/puestos', async (req, res) => {
    const db = require('../models/db');
    const [rows] = await db.query('SELECT id_puesto, nombre_puesto as nombre FROM catalogo_puestos WHERE activo = TRUE');
    res.json({ success: true, data: rows });
});
router.get('/api/nombramientos/historial/:asambleista_id', nombramientoController.getHistorialAsambleista);
router.get('/api/nombramientos/vigente/:asambleista_id', nombramientoController.getSectorVigente);
router.post('/api/nombramientos/registrar', nombramientoController.registrarNombramiento);
router.put('/api/nombramientos/:id/finalizar', nombramientoController.finalizarNombramiento);


// RUTAS DE BITÁCORA (Issue #13) 

router.get('/api/bitacora', async (req, res) => {
    const db = require('../models/db');
    const { limite, tabla, usuario } = req.query;
    
    let query = `
        SELECT l.id_log, l.accion, l.tabla_afectada, l.detalle, 
               l.ip_origen, l.fecha_hora, u.username
        FROM sys_log_auditoria l
        LEFT JOIN sys_usuario u ON l.id_usuario = u.id_usuario
        WHERE 1=1
    `;
    const params = [];
    
    if (tabla) {
        query += ` AND l.tabla_afectada = ?`;
        params.push(tabla);
    }
    if (usuario) {
        query += ` AND u.username LIKE ?`;
        params.push(`%${usuario}%`);
    }
    
    query += ` ORDER BY l.fecha_hora DESC LIMIT ${limite || 100}`;
    
    try {
        const [rows] = await db.query(query, params);
        res.json({ success: true, data: rows });
    } catch (error) {
        console.error('Error en bitácora:', error);
        res.status(500).json({ success: false, message: 'Error al obtener bitácora' });
    }
});

// RUTAS DE NORMATIVA (Issue #10)

router.get('/api/normativa/reglamentos', async (req, res) => {
    const db = require('../models/db');
    try {
        const [rows] = await db.query('SELECT id_reglamento, nombre_normativa, sigla FROM reglamento WHERE activo = TRUE');
        res.json({ success: true, data: rows });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error al cargar reglamentos' });
    }
});
router.get('/api/normativa/arbol', async (req, res) => {
    const db = require('../models/db');
    try {
        const [rows] = await db.query(`
            SELECT e.id_elemento as id, e.numero_etiqueta as numero, 
                   e.contenido_texto as titulo, e.id_elemento_padre as padre,
                   ev.nombre as estado
            FROM elemento_normativo e
            JOIN catalogo_estado_vigencia ev ON e.id_estado_vigencia = ev.id_estado_vigencia
            WHERE ev.nombre = 'Vigente'
            ORDER BY e.orden
        `);
        
        // Función para construir árbol
        function buildTree(items, parentId = null) {
            const result = [];
            for (const item of items) {
                if ((item.padre === parentId) || (parentId === null && item.padre === null)) {
                    result.push({
                        id: item.id,
                        numero: item.numero,
                        titulo: item.titulo.substring(0, 100),
                        resumen: item.titulo.substring(0, 80) + '...',
                        estado: item.estado,
                        hijos: buildTree(items, item.id)
                    });
                }
            }
            return result;
        }
        
        const arbol = buildTree(rows);
        res.json({ success: true, data: arbol });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error al cargar árbol' });
    }
});
router.get('/api/normativa/articulo/:id', async (req, res) => {
    const db = require('../models/db');
    try {
        const [rows] = await db.query(`
            SELECT e.id_elemento, e.numero_etiqueta, e.contenido_texto,
                   e.fecha_inicio_vigencia, e.fecha_fin_vigencia, ev.nombre as estado
            FROM elemento_normativo e
            JOIN catalogo_estado_vigencia ev ON e.id_estado_vigencia = ev.id_estado_vigencia
            WHERE e.id_elemento = ?
        `, [req.params.id]);
        
        if (rows.length === 0) {
            return res.status(404).json({ success: false, message: 'No encontrado' });
        }
        
        res.json({ success: true, data: rows[0] });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error al cargar artículo' });
    }
});
// =====================================================
// RUTAS DE NORMATIVA - COMPILADOR HISTÓRICO (Issue #16)
// =====================================================

// Endpoint para obtener reglamento compilado en una fecha específica
router.get('/api/normativa/compilado/:id', async (req, res) => {
    const db = require('../models/db');
    const { id } = req.params;
    const { fecha } = req.query;
    
    // Determinar fecha de consulta
    let fechaConsulta = fecha ? new Date(fecha) : new Date();
    
    // Validar que la fecha no sea futura
    const hoy = new Date();
    if (fechaConsulta > hoy) {
        fechaConsulta = hoy;
    }
    
    const fechaStr = fechaConsulta.toISOString().split('T')[0];
    
    try {
        // Obtener datos del reglamento
        const [reglamento] = await db.query(
            'SELECT id_reglamento, nombre_normativa, sigla FROM reglamento WHERE id_reglamento = ? AND activo = TRUE',
            [id]
        );
        
        if (reglamento.length === 0) {
            return res.status(404).json({ success: false, message: 'Reglamento no encontrado' });
        }
        
        // Obtener elementos vigentes en esa fecha
        const [elementos] = await db.query(
            `SELECT 
                e.id_elemento,
                e.numero_etiqueta,
                e.contenido_texto,
                e.fecha_inicio_vigencia,
                e.fecha_fin_vigencia,
                e.id_elemento_padre,
                e.orden,
                (SELECT nombre FROM catalogo_nivel_reglamento WHERE id_nivel_reglamento = e.id_nivel_reglamento) as nivel,
                (SELECT nombre FROM catalogo_estado_vigencia WHERE id_estado_vigencia = e.id_estado_vigencia) as estado
             FROM elemento_normativo e
             WHERE e.id_reglamento = ?
               AND e.fecha_inicio_vigencia <= ?
               AND (e.fecha_fin_vigencia IS NULL OR e.fecha_fin_vigencia > ?)
             ORDER BY e.orden`,
            [id, fechaStr, fechaStr]
        );
        
        // Construir árbol jerárquico
        function buildTree(items, parentId = null) {
            const result = [];
            for (const item of items) {
                if ((item.id_elemento_padre === parentId) || (parentId === null && item.id_elemento_padre === null)) {
                    result.push({
                        id: item.id_elemento,
                        numero: item.numero_etiqueta,
                        contenido: item.contenido_texto,
                        nivel: item.nivel,
                        estado: item.estado,
                        hijos: buildTree(items, item.id_elemento)
                    });
                }
            }
            return result;
        }
        
        const arbol = buildTree(elementos);
        
        // Información adicional
        const [stats] = await db.query(
            `SELECT 
                COUNT(*) as total_articulos,
                MAX(fecha_inicio_vigencia) as ultima_reforma
             FROM elemento_normativo
             WHERE id_reglamento = ?
               AND fecha_inicio_vigencia <= ?
               AND (fecha_fin_vigencia IS NULL OR fecha_fin_vigencia > ?)
               AND id_nivel_reglamento >= 3`,
            [id, fechaStr, fechaStr]
        );
        
        const esVersionHistorica = fechaConsulta < new Date();
        
        res.json({
            success: true,
            data: {
                reglamento: reglamento[0],
                fecha_consulta: fechaStr,
                es_version_historica: esVersionHistorica,
                total_articulos: stats[0]?.total_articulos || 0,
                ultima_reforma: stats[0]?.ultima_reforma || null,
                arbol: arbol
            }
        });
        
    } catch (error) {
        console.error('Error en compilador histórico:', error);
        res.status(500).json({ success: false, message: 'Error al cargar el compilado' });
    }
});

// Endpoint para obtener historial de versiones de un artículo
router.get('/api/normativa/versiones/:id', async (req, res) => {
    const db = require('../models/db');
    const { id } = req.params;
    
    try {
        const [versiones] = await db.query(
            `SELECT 
                e.id_elemento,
                e.numero_etiqueta,
                e.contenido_texto,
                e.fecha_inicio_vigencia,
                e.fecha_fin_vigencia,
                ev.nombre as estado,
                u.username as registrado_por,
                e.fecha_registro
             FROM elemento_normativo e
             JOIN catalogo_estado_vigencia ev ON e.id_estado_vigencia = ev.id_estado_vigencia
             LEFT JOIN sys_usuario u ON e.id_usuario_registro = u.id_usuario
             WHERE e.numero_etiqueta = (SELECT numero_etiqueta FROM elemento_normativo WHERE id_elemento = ?)
               AND e.id_reglamento = (SELECT id_reglamento FROM elemento_normativo WHERE id_elemento = ?)
             ORDER BY e.fecha_inicio_vigencia DESC`,
            [id, id]
        );
        
        res.json({ success: true, data: versiones });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al obtener historial' });
    }
});

module.exports = router;