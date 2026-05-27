// src/routes/index.js
const express = require('express');
const router = express.Router();

// Importar middleware de autenticación
const { verificarAutenticacion, verificarRol } = require('../middleware/auth');

// Importar controladores
const authController = require('../controllers/AuthController');
const asambleistaController = require('../controllers/AsambleistaControllers');
const nombramientoController = require('../controllers/NombramientoController');
const NormativaController = require('../controllers/NormativaController');

const normativaController = new NormativaController();

// =====================================================
// RUTAS DE AUTENTICACIÓN (PÚBLICAS)
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
// RUTAS DE ASAMBLEÍSTAS (PROTEGIDAS)
// =====================================================
router.get('/api/asambleistas', verificarAutenticacion, asambleistaController.mostrarAsambleistas);
router.post('/api/asambleistas/guardar', verificarAutenticacion, verificarRol(['Administrador', 'Secretaria_AIR']), asambleistaController.registrarAsambleista);
router.get('/api/asambleistas/buscar', verificarAutenticacion, asambleistaController.buscarAsambleistas);
router.get('/api/asambleistas/:id', verificarAutenticacion, asambleistaController.obtenerAsambleistaPorId);
router.post('/api/asambleistas/editar/:id', verificarAutenticacion, verificarRol(['Administrador', 'Secretaria_AIR']), asambleistaController.editarAsambleista);

// =====================================================
// RUTAS DE NOMBRAMIENTOS (PROTEGIDAS)
// =====================================================
router.get('/api/nombramientos/historial/:asambleista_id', verificarAutenticacion, nombramientoController.getHistorialAsambleista);
router.get('/api/nombramientos/vigente/:asambleista_id', verificarAutenticacion, nombramientoController.getSectorVigente);
router.post('/api/nombramientos/registrar', verificarAutenticacion, verificarRol(['Administrador', 'Secretaria_AIR']), nombramientoController.registrarNombramiento);
router.put('/api/nombramientos/:id/finalizar', verificarAutenticacion, verificarRol(['Administrador', 'Secretaria_AIR']), nombramientoController.finalizarNombramiento);

// =====================================================
// RUTAS DE CATÁLOGOS (PROTEGIDAS - SOLO LECTURA)
// =====================================================
router.get('/api/catalogos/sectores', verificarAutenticacion, async (req, res) => {
    const db = require('../config/db');
    try {
        const result = await db.query(`
            SELECT id_sector, nombre 
            FROM catalogo_sector 
            WHERE activo = TRUE OR activo IS NULL
            ORDER BY id_sector
        `);
        
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error(' Error en /api/catalogos/sectores:', error.message);
        res.json({ 
            success: true,
            data: [
                { id_sector: 1, nombre: 'Docencia' },
                { id_sector: 2, nombre: 'Administración' },
                { id_sector: 3, nombre: 'Estudiantil' }
            ]
        });
    }
});

router.get('/api/catalogos/puestos', verificarAutenticacion, async (req, res) => {
    const db = require('../config/db');
    try {
        const result = await db.query(`
            SELECT id_puesto, nombre_puesto as nombre 
            FROM catalogo_puestos 
            WHERE activo = TRUE OR activo IS NULL
            ORDER BY id_puesto
        `);
        
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error(' Error en /api/catalogos/puestos:', error.message);
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
// RUTAS DE SESIONES (PROTEGIDAS)
// =====================================================

// Listar todas las sesiones
router.get('/api/sesiones', verificarAutenticacion, async (req, res) => {
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
        res.json({ success: true, data: [] });
    }
});

// Obtener una sesión por ID
router.get('/api/sesiones/:id', verificarAutenticacion, async (req, res) => {
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

// Crear nueva sesión (solo Admin y Secretaría)
router.post('/api/sesiones/crear', verificarAutenticacion, verificarRol(['Administrador', 'Secretaria_AIR']), async (req, res) => {
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
// RUTAS DE BITÁCORA (Issue #13) - SOLO ADMIN Y SECRETARÍA
// =====================================================
router.get('/api/bitacora', verificarAutenticacion, verificarRol(['Administrador', 'Secretaria_AIR']), async (req, res) => {
    const db = require('../config/db');
    
    try {
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
        
        res.json({ 
            success: true, 
            data: result.rows || [],
            message: result.rows.length === 0 ? 'No hay registros en la bitácora' : null
        });
        
    } catch (error) {
        console.error('Error en bitácora:', error);
        res.json({ 
            success: true, 
            data: [],
            message: 'La tabla de bitácora aún no tiene registros o no existe'
        });
    }
});

// =====================================================
// RUTAS DE NORMATIVA - LECTURA (CUALQUIER AUTENTICADO)
// =====================================================
router.get('/api/normativa/reglamentos', verificarAutenticacion, normativaController.getReglamentos.bind(normativaController));
router.get('/api/normativa/arbol', verificarAutenticacion, normativaController.getArbol.bind(normativaController));
router.get('/api/normativa/articulo/:id', verificarAutenticacion, async (req, res) => {
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

router.get('/api/normativa/compilado/:id', verificarAutenticacion, async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;
    const { fecha } = req.query;
    
    let fechaConsulta = fecha ? new Date(fecha) : new Date();
    const hoy = new Date();
    if (fechaConsulta > hoy) fechaConsulta = hoy;
    const fechaStr = fechaConsulta.toISOString().split('T')[0];
    
    try {
        const reglamentoResult = await db.query(`
            SELECT id_reglamento, nombre_normativa as titulo, sigla 
            FROM reglamento 
            WHERE id_reglamento = $1 AND activo = TRUE
        `, [id]);
        
        if (reglamentoResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Reglamento no encontrado' });
        }
        
        const articulosResult = await db.query(`
            SELECT 
                e.id_elemento as id,
                e.numero_etiqueta as numero,
                e.contenido_texto as contenido,
                e.fecha_inicio_vigencia,
                e.fecha_fin_vigencia
            FROM elemento_normativo e
            WHERE e.id_reglamento = $1
              AND e.id_nivel_reglamento = 3
              AND e.fecha_inicio_vigencia <= $2
              AND (e.fecha_fin_vigencia IS NULL OR e.fecha_fin_vigencia > $2)
            ORDER BY e.orden
        `, [id, fechaStr]);
        
        const esVersionHistorica = fechaConsulta < new Date();
        
        res.json({
            success: true,
            data: {
                titulo: reglamentoResult.rows[0].titulo,
                descripcion: `Texto compilado del ${reglamentoResult.rows[0].titulo}`,
                version: esVersionHistorica ? `Vigente al ${fechaStr}` : 'Vigente',
                total_articulos: articulosResult.rows.length,
                ultima_reforma: null,
                es_version_historica: esVersionHistorica,
                fecha_consulta: fechaStr,
                articulos: articulosResult.rows
            }
        });
        
    } catch (error) {
        console.error('Error en compilador histórico:', error);
        res.status(500).json({ success: false, message: 'Error al cargar el compilado' });
    }
});

// =====================================================
// RUTAS DE NORMATIVA - ESCRITURA (SOLO ADMIN Y SECRETARÍA)
// =====================================================
router.post('/api/normativa/elemento', verificarAutenticacion, verificarRol(['Administrador', 'Secretaria_AIR']), normativaController.crearElemento);
router.post('/api/normativa/version', verificarAutenticacion, verificarRol(['Administrador', 'Secretaria_AIR']), normativaController.publicarNuevaVersion);
router.delete('/api/normativa/elemento/:id', verificarAutenticacion, verificarRol(['Administrador', 'Secretaria_AIR']), normativaController.eliminarElemento);

module.exports = router;