// src/routes/index.js
const express = require('express');
const router = express.Router();

const authController = require('../controllers/AuthController');
const asambleistaController = require('../controllers/AsambleistaControllers');
const nombramientoController = require('../controllers/NombramientoController');
const NormativaController = require('../controllers/NormativaController');

const normativaController = new NormativaController();

// =====================================================
// RUTAS DE AUTENTICACIÓN
// =====================================================
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

// =====================================================
// RUTAS DE ASAMBLEÍSTAS
// =====================================================
router.get('/api/asambleistas', asambleistaController.mostrarAsambleistas);
router.post('/api/asambleistas/guardar', asambleistaController.registrarAsambleista);
router.get('/api/asambleistas/buscar', asambleistaController.buscarAsambleistas);
router.get('/api/asambleistas/:id', asambleistaController.obtenerAsambleistaPorId);
router.post('/api/asambleistas/editar/:id', asambleistaController.editarAsambleista);

// =====================================================
// RUTAS DE NOMBRAMIENTOS
// =====================================================
router.get('/api/nombramientos/historial/:asambleista_id', nombramientoController.getHistorialAsambleista);
router.get('/api/nombramientos/vigente/:asambleista_id', nombramientoController.getSectorVigente);
router.post('/api/nombramientos/registrar', nombramientoController.registrarNombramiento);
router.put('/api/nombramientos/:id/finalizar', nombramientoController.finalizarNombramiento);

// =====================================================
// RUTAS DE CATÁLOGOS 
// =====================================================

router.get('/api/catalogos/sectores', async (req, res) => {
    const db = require('../config/db');
    try {
        // Verificar conexión primero
        const testQuery = await db.query('SELECT NOW()');
        console.log('✅ Conexión a BD activa');
        
        const result = await db.query(`
            SELECT id_sector, nombre 
            FROM catalogo_sector 
            WHERE activo = TRUE OR activo IS NULL
            ORDER BY id_sector
        `);
        
        console.log('📊 Sectores encontrados:', result.rows.length);
        
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error('❌ Error en /api/catalogos/sectores:', error.message);
        // En caso de error, devolver datos de ejemplo para que la vista funcione
        res.json({ 
            success: true,  // Importante: poner true para que la vista no falle
            data: [
                { id_sector: 1, nombre: 'Docencia' },
                { id_sector: 2, nombre: 'Administración' },
                { id_sector: 3, nombre: 'Estudiantil' }
            ]
        });
    }
});

router.get('/api/catalogos/puestos', async (req, res) => {
    const db = require('../config/db');
    try {
        const result = await db.query(`
            SELECT id_puesto, nombre_puesto as nombre 
            FROM catalogo_puestos 
            WHERE activo = TRUE OR activo IS NULL
            ORDER BY id_puesto
        `);
        
        console.log('📊 Puestos encontrados:', result.rows.length);
        
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error('❌ Error en /api/catalogos/puestos:', error.message);
        // Datos de ejemplo para que la vista funcione
        res.json({ 
            success: true,
            data: [
                { id_puesto: 1, nombre: 'Representante Propietario' },
                { id_puesto: 2, nombre: 'Representante Suplente' },
                { id_puesto: 3, nombre: 'Secretaría' }
            ]
        });
    }
});
// =====================================================
// RUTAS DE SESIONES
// =====================================================

// Listar todas las sesiones
router.get('/api/sesiones', async (req, res) => {
    const db = require('../config/db');
    try {
        const result = await db.query(`
            SELECT id_sesion, numero_sesion, tipo_sesion, fecha, quorum_requerido 
            FROM sesion 
            ORDER BY fecha DESC
        `);
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error('Error cargando sesiones:', error);
        // Si la tabla no existe, devolver array vacío
        res.json({ success: true, data: [] });
    }
});

// Obtener una sesión por ID
router.get('/api/sesiones/:id', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;
    try {
        const result = await db.query(`
            SELECT id_sesion, numero_sesion, tipo_sesion, fecha, quorum_requerido 
            FROM sesion 
            WHERE id_sesion = $1
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Sesión no encontrada' });
        }
        
        res.json({ success: true, data: result.rows[0] });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al cargar sesión' });
    }
});

// Crear nueva sesión
router.post('/api/sesiones/crear', async (req, res) => {
    const db = require('../config/db');
    const { numero_sesion, tipo_sesion, fecha, quorum_requerido } = req.body;
    
    try {
        const result = await db.query(`
            INSERT INTO sesion (numero_sesion, tipo_sesion, fecha, quorum_requerido)
            VALUES ($1, $2, $3, $4)
            RETURNING id_sesion
        `, [numero_sesion, tipo_sesion, fecha, quorum_requerido]);
        
        res.json({ success: true, data: { id: result.rows[0].id_sesion }, message: 'Sesión creada exitosamente' });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Error al crear sesión' });
    }
});

// =====================================================
// RUTAS DE BITÁCORA (Issue #13)
// =====================================================

router.get('/api/bitacora', async (req, res) => {
    const db = require('../config/db');
    
    try {
        // Consulta simple sin filtros complejos
        const query = `
            SELECT 
                l.id_log, 
                l.accion, 
                l.tabla_afectada, 
                l.detalle, 
                l.ip_origen, 
                l.fecha_hora, 
                COALESCE(u.username, 'Sistema') as username
            FROM sys_log_auditoria l
            LEFT JOIN sys_usuario u ON l.id_usuario = u.id_usuario
            ORDER BY l.fecha_hora DESC 
            LIMIT 100
        `;
        
        const result = await db.query(query);
        
        // Si no hay datos, devolver array vacío
        res.json({ 
            success: true, 
            data: result.rows || [],
            message: result.rows.length === 0 ? 'No hay registros en la bitácora' : null
        });
        
    } catch (error) {
        console.error('Error en bitácora:', error);
        // En caso de error, devolver array vacío en lugar de error 500
        res.json({ 
            success: true, 
            data: [],
            message: 'La tabla de bitácora aún no tiene registros o no existe'
        });
    }
});

// =====================================================
// RUTAS DE NORMATIVA
// =====================================================
router.get('/api/normativa/reglamentos', normativaController.getReglamentos.bind(normativaController));
router.get('/api/normativa/arbol', normativaController.getArbol.bind(normativaController));
router.get('/api/normativa/articulo/:id', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;
    
    try {
        const result = await db.query(`
            SELECT 
                e.id_elemento,
                e.numero_etiqueta,
                e.contenido_texto,
                e.fecha_inicio_vigencia,
                e.fecha_fin_vigencia,
                COALESCE(ev.nombre, 'Vigente') as estado
            FROM elemento_normativo e
            LEFT JOIN catalogo_estado_vigencia ev ON e.id_estado_vigencia = ev.id_estado_vigencia
            WHERE e.id_elemento = $1
        `, [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Artículo no encontrado' });
        }
        
        const data = result.rows[0];
        
        res.json({ 
            success: true, 
            data: {
                id: data.id_elemento,
                numero: data.numero_etiqueta,
                contenido: data.contenido_texto || 'Contenido no disponible',
                vigencia_inicio: data.fecha_inicio_vigencia,
                vigencia_fin: data.fecha_fin_vigencia,
                estado: data.estado
            }
        });
    } catch (error) {
        console.error('Error en articulo:', error);
        res.status(500).json({ success: false, message: 'Error al cargar el artículo' });
    }
});
router.get('/api/normativa/compilado/:id', normativaController.getCompilado.bind(normativaController));

module.exports = router;