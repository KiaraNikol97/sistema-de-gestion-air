
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

module.exports = router;