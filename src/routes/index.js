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
    try {
        const result = await db.query('SELECT id_sector, nombre FROM catalogo_sector WHERE activo = TRUE');
        res.json({ success: true, data: result.rows });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error al cargar sectores' });
    }
});

router.get('/api/catalogos/puestos', async (req, res) => {
    try {
        const result = await db.query('SELECT id_puesto, nombre_puesto as nombre FROM catalogo_puestos WHERE activo = TRUE');
        res.json({ success: true, data: result.rows });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error al cargar puestos' });
    }
});

// =====================================================
// RUTAS DE NORMATIVA
// =====================================================
router.get('/api/normativa/reglamentos', normativaController.getReglamentos.bind(normativaController));
router.get('/api/normativa/arbol', normativaController.getArbol.bind(normativaController));
router.get('/api/normativa/articulo/:id', normativaController.getArticulo.bind(normativaController));
router.get('/api/normativa/compilado/:id', normativaController.getCompilado.bind(normativaController));

module.exports = router;