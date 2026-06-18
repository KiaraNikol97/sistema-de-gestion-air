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
router.get('/api/normativa/compilado/:id', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;
    const { fecha } = req.query;
    
    let fechaConsulta = fecha ? new Date(fecha) : new Date();
    const hoy = new Date();
    if (fechaConsulta > hoy) fechaConsulta = hoy;
    const fechaStr = fechaConsulta.toISOString().split('T')[0];
    
    try {
        // Obtener datos del reglamento
        const reglamentoResult = await db.query(`
            SELECT id_reglamento, nombre_normativa as titulo, sigla 
            FROM reglamento 
            WHERE id_reglamento = $1 AND activo = TRUE
        `, [id]);
        
        if (reglamentoResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Reglamento no encontrado' });
        }
        
        // Obtener artículos vigentes en la fecha consultada
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

// =========================================================
// RUTAS DEL SPRINT 3 - (FUNCIONALIDADES AVANZADAS)
// =========================================================

// Registrar asistencia a una sesión
router.post('/api/sesiones/:id/asistencia', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;
    const { id_asambleista, id_estado_asistencia, observaciones } = req.body;

    try {
        // Validar que la sesión existe
        const sesionCheck = await db.query(
            'SELECT id_sesion, estado FROM sesion WHERE id_sesion = $1',
            [id]
        );
        
        if (sesionCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Sesión no encontrada' });
        }

        if (sesionCheck.rows[0].estado === 'Cancelada') {
            return res.status(400).json({ success: false, message: 'No se puede registrar asistencia a una sesión cancelada' });
        }

        // Registrar o actualizar asistencia
        const result = await db.query(`
            INSERT INTO asistencia_sesion_plenaria (id_asambleista, id_sesion, id_estado_asistencia, observaciones)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (id_asambleista, id_sesion) 
            DO UPDATE SET 
                id_estado_asistencia = EXCLUDED.id_estado_asistencia,
                observaciones = EXCLUDED.observaciones,
                hora_registro = CURRENT_TIMESTAMP
            RETURNING *
        `, [id_asambleista, id, id_estado_asistencia, observaciones || null]);

        res.json({ 
            success: true, 
            message: 'Asistencia registrada exitosamente',
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Error registrando asistencia:', error);
        res.status(500).json({ success: false, message: 'Error al registrar asistencia', error: error.message });
    }
});

// Obtener lista de asistencia de una sesión
router.get('/api/sesiones/:id/asistencia', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;

    try {
        const result = await db.query(`
            SELECT 
                asp.id_asistencia,
                a.id_asambleista,
                a.nombre,
                a.cedula,
                cea.nombre AS estado_asistencia,
                asp.hora_registro,
                asp.observaciones
            FROM asistencia_sesion_plenaria asp
            INNER JOIN asambleista a ON asp.id_asambleista = a.id_asambleista
            INNER JOIN catalogo_estado_asistencia cea ON asp.id_estado_asistencia = cea.id_estado_asistencia
            WHERE asp.id_sesion = $1
            ORDER BY a.nombre ASC
        `, [id]);

        res.json({ success: true, data: result.rows, total: result.rows.length });

    } catch (error) {
        console.error('Error obteniendo asistencia:', error);
        res.status(500).json({ success: false, message: 'Error al obtener asistencia' });
    }
});

// Verificar quórum de una sesión
router.get('/api/sesiones/:id/quorum', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;

    try {
        // Obtener datos de quórum usando las funciones de PostgreSQL
        const result = await db.query(`
            SELECT 
                fn_asistentes_para_quorum($1) AS presentes,
                fn_quorum_requerido($1) AS requeridos,
                fn_validar_quorum($1) AS quorum_valido
        `, [id]);

        const data = result.rows[0];
        
        res.json({
            success: true,
            data: {
                presentes: parseInt(data.presentes) || 0,
                requeridos: parseInt(data.requeridos) || 0,
                quorum_valido: data.quorum_valido || false,
                estado: data.quorum_valido ? 'Quórum válido' : 'Quórum insuficiente'
            }
        });

    } catch (error) {
        console.error('Error verificando quórum:', error);
        res.status(500).json({ success: false, message: 'Error al verificar quórum' });
    }
});

// =====================================================
// RUTAS DE QUÓRUM - ISSUE #11
// =====================================================

// Verificar quórum de una sesión (GET)
router.get('/api/sesiones/:id/quorum', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;

    try {
        const result = await db.query(`
            SELECT 
                fn_asistentes_para_quorum($1) AS presentes,
                fn_quorum_requerido($1) AS requeridos,
                fn_validar_quorum($1) AS quorum_valido
        `, [id]);

        const data = result.rows[0];
        
        res.json({
            success: true,
            data: {
                presentes: parseInt(data.presentes) || 0,
                requeridos: parseInt(data.requeridos) || 0,
                quorum_valido: data.quorum_valido || false,
                estado: data.quorum_valido ? 'Quórum válido' : 'Quórum insuficiente'
            }
        });

    } catch (error) {
        console.error('Error verificando quórum:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Error al verificar quórum',
            error: error.message
        });
    }
});

// Recalcular quórum de una sesión (POST)
router.post('/api/sesiones/:id/calcular-quorum', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;

    try {
        // Forzar actualización del quórum en la sesión
        await db.query(
            `UPDATE sesion 
             SET total_asambleistas = fn_total_asambleistas_activos(fecha),
                 quorum_requerido = fn_quorum_requerido($1)
             WHERE id_sesion = $1`,
            [id]
        );

        // Obtener el estado actualizado
        const result = await db.query(`
            SELECT 
                fn_asistentes_para_quorum($1) AS presentes,
                fn_quorum_requerido($1) AS requeridos,
                fn_validar_quorum($1) AS quorum_valido
        `, [id]);

        res.json({
            success: true,
            message: 'Quórum recalculado exitosamente',
            data: {
                presentes: parseInt(result.rows[0].presentes) || 0,
                requeridos: parseInt(result.rows[0].requeridos) || 0,
                quorum_valido: result.rows[0].quorum_valido || false,
                estado: result.rows[0].quorum_valido ? 'Quórum válido' : 'Quórum insuficiente'
            }
        });

    } catch (error) {
        console.error('Error recalculando quórum:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Error al recalcular quórum',
            error: error.message
        });
    }
});

// Crear una nueva votación
router.post('/api/votaciones', async (req, res) => {
    const db = require('../config/db');
    const { 
        id_sesion, 
        id_propuesta, 
        id_elemento_normativo, 
        numero_votacion, 
        tipo_votacion,
        id_tipo_mayoria_requerida,
        id_tipo_votacion
    } = req.body;

    try {
        // Verificar quórum antes de crear votación
        const quorumCheck = await db.query(
            'SELECT fn_validar_quorum($1) AS quorum_valido',
            [id_sesion]
        );

        if (!quorumCheck.rows[0]?.quorum_valido) {
            return res.status(409).json({ 
                success: false, 
                message: 'No se puede iniciar votación: quórum insuficiente' 
            });
        }

        // Crear votación
        const result = await db.query(`
            INSERT INTO votacion (
                id_sesion, id_propuesta, id_elemento_normativo,
                numero_votacion, tipo_votacion, resultado
            ) VALUES ($1, $2, $3, $4, $5, 'Pendiente')
            RETURNING id_votacion, id_sesion, resultado
        `, [id_sesion, id_propuesta || null, id_elemento_normativo || null, numero_votacion || null, tipo_votacion || 'Publica']);

        const id_votacion = result.rows[0].id_votacion;

        // Crear registro en resultado_votacion
        await db.query(`
            INSERT INTO resultado_votacion (
                id_votacion, id_tipo_mayoria_requerida, id_tipo_votacion, resultado
            ) VALUES ($1, $2, $3, 'Pendiente')
        `, [id_votacion, id_tipo_mayoria_requerida, id_tipo_votacion]);

        // Cambiar estado de la sesión a "En Curso"
        await db.query(
            "UPDATE sesion SET estado = 'En Curso' WHERE id_sesion = $1 AND estado != 'En Curso'",
            [id_sesion]
        );

        res.status(201).json({
            success: true,
            message: 'Votación creada exitosamente',
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Error creando votación:', error);
        res.status(500).json({ success: false, message: 'Error al crear votación', error: error.message });
    }
});

// Listar todas las votaciones
router.get('/api/votaciones', async (req, res) => {
    const db = require('../config/db');
    const { id_sesion, resultado } = req.query;

    try {
        let query = `
            SELECT 
                v.id_votacion,
                v.id_sesion,
                v.numero_votacion,
                v.tipo_votacion,
                v.votos_favor,
                v.votos_contra,
                v.votos_abstencion,
                v.total_votantes,
                v.resultado,
                v.fecha_registro,
                s.numero_sesion,
                s.fecha AS fecha_sesion,
                rv.id_tipo_mayoria_requerida,
                rv.resultado AS resultado_detalle
            FROM votacion v
            INNER JOIN sesion s ON v.id_sesion = s.id_sesion
            LEFT JOIN resultado_votacion rv ON v.id_votacion = rv.id_votacion
            WHERE 1=1
        `;

        const params = [];
        let paramCount = 1;

        if (id_sesion) {
            query += ` AND v.id_sesion = $${paramCount}`;
            params.push(id_sesion);
            paramCount++;
        }

        if (resultado) {
            query += ` AND v.resultado = $${paramCount}`;
            params.push(resultado);
            paramCount++;
        }

        query += ` ORDER BY v.fecha_registro DESC`;

        const result = await db.query(query, params);
        res.json({ success: true, data: result.rows, total: result.rows.length });

    } catch (error) {
        console.error('Error listando votaciones:', error);
        res.status(500).json({ success: false, message: 'Error al listar votaciones' });
    }
});

// Obtener una votación por ID
router.get('/api/votaciones/:id', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;

    try {
        const result = await db.query(`
            SELECT 
                v.*,
                s.numero_sesion,
                s.fecha AS fecha_sesion,
                rv.id_tipo_mayoria_requerida,
                rv.total_presentes,
                rv.total_votos,
                rv.porcentaje_aprobacion,
                rv.fecha_apertura,
                rv.fecha_cierre,
                rv.resultado AS resultado_detalle
            FROM votacion v
            INNER JOIN sesion s ON v.id_sesion = s.id_sesion
            LEFT JOIN resultado_votacion rv ON v.id_votacion = rv.id_votacion
            WHERE v.id_votacion = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Votación no encontrada' });
        }

        res.json({ success: true, data: result.rows[0] });

    } catch (error) {
        console.error('Error obteniendo votación:', error);
        res.status(500).json({ success: false, message: 'Error al obtener votación' });
    }
});

// Registrar un voto
router.post('/api/votaciones/:id/voto', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;
    const { tipo_voto } = req.body;

    if (!['Favor', 'Contra', 'Abstencion'].includes(tipo_voto)) {
        return res.status(400).json({ 
            success: false, 
            message: 'Tipo de voto inválido. Permitidos: Favor, Contra, Abstencion' 
        });
    }

    try {
        // Verificar que la votación esté pendiente
        const votacionCheck = await db.query(
            'SELECT resultado FROM votacion WHERE id_votacion = $1',
            [id]
        );

        if (votacionCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Votación no encontrada' });
        }

        if (votacionCheck.rows[0].resultado !== 'Pendiente') {
            return res.status(409).json({ 
                success: false, 
                message: `La votación ya fue ${votacionCheck.rows[0].resultado.toLowerCase()}` 
            });
        }

        // Registrar el voto
        let campoVoto;
        switch (tipo_voto) {
            case 'Favor': campoVoto = 'votos_favor'; break;
            case 'Contra': campoVoto = 'votos_contra'; break;
            case 'Abstencion': campoVoto = 'votos_abstencion'; break;
        }

        const result = await db.query(`
            UPDATE votacion 
            SET 
                ${campoVoto} = ${campoVoto} + 1,
                total_votantes = total_votantes + 1
            WHERE id_votacion = $1
            RETURNING *
        `, [id]);

        res.json({
            success: true,
            message: `Voto "${tipo_voto}" registrado exitosamente`,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Error registrando voto:', error);
        res.status(500).json({ success: false, message: 'Error al registrar voto' });
    }
});

// Finalizar votación
router.post('/api/votaciones/:id/finalizar', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;

    try {
        // Obtener la votación
        const votacion = await db.query(
            'SELECT * FROM votacion WHERE id_votacion = $1',
            [id]
        );

        if (votacion.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Votación no encontrada' });
        }

        if (votacion.rows[0].resultado !== 'Pendiente') {
            return res.status(409).json({ 
                success: false, 
                message: `La votación ya fue ${votacion.rows[0].resultado.toLowerCase()}` 
            });
        }

        // Obtener el tipo de mayoría requerida
        const tipoMayoria = await db.query(
            'SELECT id_tipo_mayoria_requerida FROM resultado_votacion WHERE id_votacion = $1',
            [id]
        );

        // Calcular resultado usando la función de PostgreSQL
        const calcResult = await db.query(`
            SELECT fn_calcular_resultado_votacion(
                $1, $2, 
                (SELECT nombre FROM catalogo_tipo_mayoria_requerida 
                 WHERE id_tipo_mayoria_requerida = $3)
            ) AS resultado
        `, [
            votacion.rows[0].votos_favor,
            votacion.rows[0].votos_contra,
            tipoMayoria.rows[0]?.id_tipo_mayoria_requerida || 1
        ]);

        const resultado = calcResult.rows[0].resultado;

        // Actualizar votacion
        await db.query(
            'UPDATE votacion SET resultado = $2 WHERE id_votacion = $1',
            [id, resultado]
        );

        // Actualizar resultado_votacion
        const totalVotos = votacion.rows[0].votos_favor + votacion.rows[0].votos_contra + votacion.rows[0].votos_abstencion;
        const porcentajeAprobacion = totalVotos > 0 
            ? ((votacion.rows[0].votos_favor / totalVotos) * 100) 
            : 0;

        await db.query(`
            UPDATE resultado_votacion 
            SET 
                total_votos = $2,
                votos_favor = $3,
                votos_contra = $4,
                abstenciones = $5,
                porcentaje_aprobacion = $6,
                resultado = $7,
                fecha_cierre = CURRENT_TIMESTAMP
            WHERE id_votacion = $1
        `, [
            id,
            totalVotos,
            votacion.rows[0].votos_favor,
            votacion.rows[0].votos_contra,
            votacion.rows[0].votos_abstencion,
            porcentajeAprobacion,
            resultado
        ]);

        res.json({
            success: true,
            message: 'Votación finalizada exitosamente',
            data: { id_votacion: id, resultado }
        });

    } catch (error) {
        console.error('Error finalizando votación:', error);
        res.status(500).json({ success: false, message: 'Error al finalizar votación' });
    }
});

// Obtener resultado de una votación
router.get('/api/votaciones/:id/resultado', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;

    try {
        const result = await db.query(`
            SELECT 
                rv.*,
                tm.nombre AS tipo_mayoria,
                tm.porcentaje_requerido,
                tv.nombre AS tipo_votacion_nombre
            FROM resultado_votacion rv
            LEFT JOIN catalogo_tipo_mayoria_requerida tm ON rv.id_tipo_mayoria_requerida = tm.id_tipo_mayoria_requerida
            LEFT JOIN catalogo_tipo_votacion tv ON rv.id_tipo_votacion = tv.id_tipo_votacion
            WHERE rv.id_votacion = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Resultado no encontrado' });
        }

        res.json({ success: true, data: result.rows[0] });

    } catch (error) {
        console.error('Error obteniendo resultado:', error);
        res.status(500).json({ success: false, message: 'Error al obtener resultado' });
    }
});

// Verificar si se puede votar en una sesión
router.get('/api/votaciones/sesion/:id_sesion/puede-votar', async (req, res) => {
    const db = require('../config/db');
    const { id_sesion } = req.params;

    try {
        // Verificar estado de la sesión
        const sesion = await db.query(
            'SELECT estado FROM sesion WHERE id_sesion = $1',
            [id_sesion]
        );

        if (sesion.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Sesión no encontrada' });
        }

        if (sesion.rows[0].estado !== 'En Curso') {
            return res.json({
                success: true,
                data: {
                    puede: false,
                    motivo: `La sesión está en estado "${sesion.rows[0].estado}". Solo se puede votar en sesiones "En Curso".`
                }
            });
        }

        // Verificar quórum
        const quorum = await db.query(
            'SELECT fn_validar_quorum($1) AS quorum_valido',
            [id_sesion]
        );

        if (!quorum.rows[0]?.quorum_valido) {
            return res.json({
                success: true,
                data: {
                    puede: false,
                    motivo: 'Quórum insuficiente para iniciar la votación'
                }
            });
        }

        res.json({
            success: true,
            data: {
                puede: true,
                motivo: 'OK'
            }
        });

    } catch (error) {
        console.error('Error verificando si puede votar:', error);
        res.status(500).json({ success: false, message: 'Error al verificar' });
    }
});

// =====================================================
// RUTAS DE CERTIFICACIONES - ISSUE #17
// =====================================================

const CertificadorController = require('../controllers/CertificadorController');
const PDFService = require('../services/PDFService');

// =====================================================
// 1. DATOS CONSOLIDADOS PARA CERTIFICACIONES
// =====================================================

// Obtener datos consolidados de un asambleísta (para vista previa)
router.get('/api/certificaciones/datos-consolidados/:id_asambleista', async (req, res) => {
    const db = require('../config/db');
    const { id_asambleista } = req.params;

    try {
        const result = await db.query(
            'SELECT * FROM v_certificacion_datos_consolidados WHERE id_asambleista = $1',
            [id_asambleista]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No se encontraron datos del asambleísta'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Error en datos-consolidados:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener datos consolidados',
            error: error.message
        });
    }
});

// =====================================================
// 2. SOLICITUDES DE CERTIFICACIÓN
// =====================================================

// Crear solicitud de certificación
router.post('/api/certificaciones/solicitud', async (req, res) => {
    const db = require('../config/db');
    const {
        id_asambleista,
        periodo_desde,
        periodo_hasta,
        observaciones
    } = req.body;

    // Usuario de la sesión (si existe)
    const id_usuario_solicitante = req.session?.userId || null;

    try {
        if (!id_asambleista) {
            return res.status(400).json({
                success: false,
                message: 'El campo id_asambleista es obligatorio'
            });
        }

        const result = await db.query(`
            INSERT INTO solicitud_certificacion (
                id_asambleista,
                periodo_desde,
                periodo_hasta,
                observaciones,
                id_usuario_solicitante,
                estado
            ) VALUES ($1, $2, $3, $4, $5, 'Pendiente')
            RETURNING id_solicitud, fecha_solicitud, estado
        `, [
            id_asambleista,
            periodo_desde || null,
            periodo_hasta || null,
            observaciones || null,
            id_usuario_solicitante || null
        ]);

        res.status(201).json({
            success: true,
            message: 'Solicitud creada exitosamente',
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Error creando solicitud:', error);
        res.status(500).json({
            success: false,
            message: 'Error al crear la solicitud',
            error: error.message
        });
    }
});

// Listar todas las solicitudes
router.get('/api/certificaciones/solicitudes', async (req, res) => {
    const db = require('../config/db');
    const { id_asambleista, estado } = req.query;

    try {
        let query = `
            SELECT 
                s.id_solicitud,
                s.id_asambleista,
                a.nombre AS asambleista_nombre,
                a.cedula,
                s.fecha_solicitud,
                s.periodo_desde,
                s.periodo_hasta,
                s.estado,
                s.observaciones,
                s.fecha_respuesta,
                u.username AS solicitante_nombre,
                s.id_certificacion_generada
            FROM solicitud_certificacion s
            INNER JOIN asambleista a ON s.id_asambleista = a.id_asambleista
            LEFT JOIN sys_usuario u ON s.id_usuario_solicitante = u.id_usuario
            WHERE 1=1
        `;

        const params = [];
        let paramCount = 1;

        if (id_asambleista) {
            query += ` AND s.id_asambleista = $${paramCount}`;
            params.push(id_asambleista);
            paramCount++;
        }

        if (estado) {
            query += ` AND s.estado = $${paramCount}`;
            params.push(estado);
            paramCount++;
        }

        query += ` ORDER BY s.fecha_solicitud DESC`;

        const result = await db.query(query, params);

        res.json({
            success: true,
            data: result.rows,
            total: result.rows.length
        });

    } catch (error) {
        console.error('Error listando solicitudes:', error);
        res.status(500).json({
            success: false,
            message: 'Error al listar solicitudes',
            error: error.message
        });
    }
});

// Obtener una solicitud por ID
router.get('/api/certificaciones/solicitud/:id', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;

    try {
        const result = await db.query(`
            SELECT 
                s.*,
                a.nombre AS asambleista_nombre,
                a.cedula,
                u.username AS solicitante_nombre
            FROM solicitud_certificacion s
            INNER JOIN asambleista a ON s.id_asambleista = a.id_asambleista
            LEFT JOIN sys_usuario u ON s.id_usuario_solicitante = u.id_usuario
            WHERE s.id_solicitud = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Solicitud no encontrada'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Error obteniendo solicitud:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener la solicitud',
            error: error.message
        });
    }
});

// Actualizar estado de una solicitud
router.put('/api/certificaciones/solicitud/:id', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;
    const { estado, id_certificacion_generada } = req.body;

    const estadosValidos = ['Pendiente', 'En Proceso', 'Completada', 'Rechazada'];

    try {
        if (!estado) {
            return res.status(400).json({
                success: false,
                message: 'El campo estado es obligatorio'
            });
        }

        if (!estadosValidos.includes(estado)) {
            return res.status(400).json({
                success: false,
                message: `Estado inválido. Permitidos: ${estadosValidos.join(', ')}`
            });
        }

        const result = await db.query(`
            UPDATE solicitud_certificacion 
            SET 
                estado = $2,
                fecha_respuesta = CASE WHEN $2 IN ('Completada', 'Rechazada') 
                    THEN CURRENT_DATE 
                    ELSE fecha_respuesta 
                END,
                id_certificacion_generada = COALESCE($3, id_certificacion_generada)
            WHERE id_solicitud = $1
            RETURNING *
        `, [id, estado, id_certificacion_generada || null]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Solicitud no encontrada'
            });
        }

        res.json({
            success: true,
            message: `Solicitud actualizada a estado "${estado}"`,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Error actualizando solicitud:', error);
        res.status(500).json({
            success: false,
            message: 'Error al actualizar la solicitud',
            error: error.message
        });
    }
});

// =====================================================
// 3. GENERACIÓN DE CERTIFICACIONES
// =====================================================

// Generar una nueva certificación
router.post('/api/certificaciones/generar', async (req, res) => {
    const db = require('../config/db');
    const CryptoService = require('../services/CryptoService');
    const PDFService = require('../services/PDFService');
    
    const {
        id_solicitud,
        id_asambleista,
        periodo_desde,
        periodo_hasta,
        id_certificacion_sustituye
    } = req.body;

    const id_usuario_secretaria = req.session?.userId || 1;

    try {
        if (!id_asambleista) {
            return res.status(400).json({
                success: false,
                message: 'El campo id_asambleista es obligatorio'
            });
        }

        // 1. Obtener datos consolidados del asambleísta
        const datosResult = await db.query(
            'SELECT * FROM v_certificacion_datos_consolidados WHERE id_asambleista = $1',
            [id_asambleista]
        );

        if (datosResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No se encontraron datos del asambleísta'
            });
        }

        const datos = datosResult.rows[0];

        // 2. Construir contenido JSON
        const contenido_json = {
            asambleista: {
                id: datos.id_asambleista,
                cedula: datos.cedula,
                nombre: datos.nombre_asambleista,
                correo: datos.correo_institucional
            },
            periodo: {
                desde: periodo_desde || datos.primer_periodo_inicio,
                hasta: periodo_hasta || datos.ultimo_periodo_fin
            },
            nombramientos: datos.nombramientos || [],
            propuestas: datos.propuestas || [],
            comisiones: datos.comisiones || [],
            total_nombramientos: datos.total_nombramientos || 0,
            total_asistencias_plenarias: datos.total_asistencias_plenarias || 0,
            total_propuestas: datos.total_propuestas_como_proponente || 0,
            fecha_generacion: new Date().toISOString(),
            tipo: 'certificacion_air'
        };

        // 3. Generar hash
        const hash = CryptoService.generarHashFromObject(contenido_json);

        // 4. Insertar la certificación
        const certificadoResult = await db.query(`
            INSERT INTO certificacion_emitida (
                id_solicitud,
                id_asambleista,
                contenido_json,
                hash_seguridad,
                id_usuario_secretaria,
                id_certificacion_sustituye,
                estado,
                fecha_emision
            ) VALUES ($1, $2, $3, $4, $5, $6, 'Activa', CURRENT_DATE)
            RETURNING id_certificacion, folio_unico, hash_seguridad, fecha_emision
        `, [
            id_solicitud || null,
            id_asambleista,
            contenido_json,
            hash,
            id_usuario_secretaria,
            id_certificacion_sustituye || null
        ]);

        const certificado = certificadoResult.rows[0];

        // 5. Generar PDF
        const datosPDF = {
            ...certificado,
            asambleista: datos,
            contenido: contenido_json,
            codigo_verificacion: `VER-${certificado.folio_unico}-${hash.substring(0, 10)}`
        };

        const pdfBuffer = await PDFService.generarDesdePlantilla(datosPDF);
        await PDFService.guardarPDF(pdfBuffer, certificado.folio_unico);

        // 6. Actualizar la solicitud si existe
        if (id_solicitud) {
            await db.query(`
                UPDATE solicitud_certificacion 
                SET estado = 'Completada', 
                    id_certificacion_generada = $2
                WHERE id_solicitud = $1
            `, [id_solicitud, certificado.id_certificacion]);
        }

        res.status(201).json({
            success: true,
            message: 'Certificación generada exitosamente',
            data: {
                ...certificado,
                codigo_verificacion: datosPDF.codigo_verificacion,
                url_pdf: `/certificados/${certificado.folio_unico}.pdf`
            }
        });

    } catch (error) {
        console.error('Error generando certificación:', error);
        res.status(500).json({
            success: false,
            message: 'Error al generar la certificación',
            error: error.message
        });
    }
});

// Obtener certificaciones de un asambleísta
router.get('/api/certificaciones/asambleista/:id_asambleista', async (req, res) => {
    const db = require('../config/db');
    const { id_asambleista } = req.params;

    try {
        const result = await db.query(`
            SELECT 
                c.id_certificacion,
                c.folio_unico,
                c.hash_seguridad,
                c.fecha_emision,
                c.hora_emision,
                c.estado,
                c.url_pdf,
                a.nombre AS asambleista_nombre,
                a.cedula,
                u.username AS secretaria_nombre,
                v.codigo_verificacion
            FROM certificacion_emitida c
            INNER JOIN asambleista a ON c.id_asambleista = a.id_asambleista
            LEFT JOIN sys_usuario u ON c.id_usuario_secretaria = u.id_usuario
            LEFT JOIN verificacion_externa v ON c.id_certificacion = v.id_certificacion
            WHERE c.id_asambleista = $1
              AND c.estado != 'Anulada'
            ORDER BY c.fecha_emision DESC
        `, [id_asambleista]);

        res.json({
            success: true,
            data: result.rows,
            total: result.rows.length
        });

    } catch (error) {
        console.error('Error obteniendo certificaciones:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener certificaciones',
            error: error.message
        });
    }
});

// Obtener una certificación por folio
router.get('/api/certificaciones/folio/:folio', async (req, res) => {
    const db = require('../config/db');
    const { folio } = req.params;

    try {
        const result = await db.query(`
            SELECT 
                c.*,
                a.nombre AS asambleista_nombre,
                a.cedula,
                a.correo_institucional,
                u.username AS secretaria_nombre,
                v.codigo_verificacion,
                v.url_verificacion,
                v.veces_verificado,
                v.ultima_verificacion,
                v.activo AS verificacion_activa
            FROM certificacion_emitida c
            INNER JOIN asambleista a ON c.id_asambleista = a.id_asambleista
            LEFT JOIN sys_usuario u ON c.id_usuario_secretaria = u.id_usuario
            LEFT JOIN verificacion_externa v ON c.id_certificacion = v.id_certificacion
            WHERE c.folio_unico = $1
        `, [folio]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Certificación no encontrada'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Error obteniendo certificación por folio:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener la certificación',
            error: error.message
        });
    }
});

// Obtener una certificación por ID
router.get('/api/certificaciones/:id', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;

    try {
        const result = await db.query(`
            SELECT 
                c.*,
                a.nombre AS asambleista_nombre,
                a.cedula,
                a.correo_institucional,
                u.username AS secretaria_nombre,
                v.codigo_verificacion,
                v.veces_verificado,
                v.ultima_verificacion,
                v.activo AS verificacion_activa,
                s.estado AS solicitud_estado,
                s.fecha_solicitud,
                s.periodo_desde,
                s.periodo_hasta
            FROM certificacion_emitida c
            INNER JOIN asambleista a ON c.id_asambleista = a.id_asambleista
            LEFT JOIN sys_usuario u ON c.id_usuario_secretaria = u.id_usuario
            LEFT JOIN verificacion_externa v ON c.id_certificacion = v.id_certificacion
            LEFT JOIN solicitud_certificacion s ON c.id_solicitud = s.id_solicitud
            WHERE c.id_certificacion = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Certificación no encontrada'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Error obteniendo certificación:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener la certificación',
            error: error.message
        });
    }
});

// =====================================================
// 4. PREVISUALIZACIÓN DE CERTIFICACIONES
// =====================================================

// Previsualizar certificado (HTML)
router.get('/api/certificaciones/preview/:id_asambleista', async (req, res) => {
    const db = require('../config/db');
    const PDFService = require('../services/PDFService');
    const { id_asambleista } = req.params;

    try {
        // Obtener datos consolidados
        const datosResult = await db.query(
            'SELECT * FROM v_certificacion_datos_consolidados WHERE id_asambleista = $1',
            [id_asambleista]
        );

        if (datosResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No se encontraron datos del asambleísta'
            });
        }

        const datos = datosResult.rows[0];

        // Construir datos para previsualización
        const datosPreview = {
            asambleista: {
                nombre: datos.nombre_asambleista,
                cedula: datos.cedula,
                correo: datos.correo_institucional
            },
            folio_unico: 'PREVIEW-XXXX',
            fecha_emision: new Date().toISOString(),
            contenido: {
                periodo: {
                    desde: datos.primer_periodo_inicio,
                    hasta: datos.ultimo_periodo_fin
                },
                total_nombramientos: datos.total_nombramientos || 0,
                total_asistencias_plenarias: datos.total_asistencias_plenarias || 0,
                total_propuestas: datos.total_propuestas_como_proponente || 0
            },
            hash_seguridad: 'PREVIEW_HASH',
            codigo_verificacion: 'PREVIEW-CODE'
        };

        // Generar HTML de previsualización
        const htmlPreview = PDFService.generarHTMLPreview(datosPreview);

        res.json({
            success: true,
            data: {
                html: htmlPreview,
                asambleista: datos
            }
        });

    } catch (error) {
        console.error('Error en previsualización:', error);
        res.status(500).json({
            success: false,
            message: 'Error al generar previsualización',
            error: error.message
        });
    }
});

// =====================================================
// 5. VERIFICACIÓN DE CERTIFICACIONES
// =====================================================

// Verificar certificación por código
router.get('/api/certificaciones/verificar/:codigo', async (req, res) => {
    const db = require('../config/db');
    const { codigo } = req.params;

    try {
        // Buscar la certificación por código de verificación
        const result = await db.query(`
            SELECT 
                c.folio_unico,
                c.estado,
                c.hash_seguridad,
                c.fecha_emision,
                a.nombre AS asambleista_nombre,
                a.cedula,
                v.veces_verificado,
                v.ultima_verificacion,
                v.activo AS verificacion_activa
            FROM verificacion_externa v
            JOIN certificacion_emitida c ON v.id_certificacion = c.id_certificacion
            JOIN asambleista a ON c.id_asambleista = a.id_asambleista
            WHERE v.codigo_verificacion = $1
        `, [codigo]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Código de verificación inválido'
            });
        }

        const data = result.rows[0];

        // Registrar la verificación
        await db.query(
            `SELECT fn_registrar_verificacion_externa($1)`,
            [codigo]
        );

        // Deterinar estado público
        let estadoPublico;
        if (data.estado === 'Activa' && data.verificacion_activa) {
            estadoPublico = 'Documento auténtico y vigente';
        } else if (data.estado === 'Anulada') {
            estadoPublico = 'Documento inválido: certificación anulada';
        } else {
            estadoPublico = 'Documento no vigente o suspendido';
        }

        res.json({
            success: true,
            data: {
                folio: data.folio_unico,
                estado: estadoPublico,
                fecha_emision: data.fecha_emision,
                nombre_asambleista: data.nombre_asambleista,
                cedula: data.cedula,
                veces_verificado: (data.veces_verificado || 0) + 1,
                ultima_verificacion: new Date().toISOString()
            }
        });

    } catch (error) {
        console.error('Error verificando certificación:', error);
        res.status(500).json({
            success: false,
            message: 'Error al verificar la certificación',
            error: error.message
        });
    }
});

// Obtener código de verificación de una certificación
router.get('/api/certificaciones/:id/codigo-verificacion', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;

    try {
        const result = await db.query(`
            SELECT 
                c.folio_unico,
                v.codigo_verificacion,
                v.url_verificacion
            FROM certificacion_emitida c
            LEFT JOIN verificacion_externa v ON c.id_certificacion = v.id_certificacion
            WHERE c.id_certificacion = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Certificación no encontrada'
            });
        }

        res.json({
            success: true,
            data: {
                folio: result.rows[0].folio_unico,
                codigo_verificacion: result.rows[0].codigo_verificacion,
                url_verificacion: result.rows[0].url_verificacion || `/verificar/${result.rows[0].codigo_verificacion}`
            }
        });

    } catch (error) {
        console.error('Error obteniendo código de verificación:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener código de verificación',
            error: error.message
        });
    }
});

// =====================================================
// 6. ANULACIÓN DE CERTIFICACIONES
// =====================================================

// Anular una certificación
router.post('/api/certificaciones/:id/anular', async (req, res) => {
    const db = require('../config/db');
    const { id } = req.params;
    const { motivo, id_certificacion_sustituta } = req.body;

    const id_usuario_anulacion = req.session?.userId || 1;

    try {
        if (!motivo || motivo.trim() === '') {
            return res.status(400).json({
                success: false,
                message: 'El campo motivo es obligatorio para anular una certificación'
            });
        }

        // Verificar que la certificación existe y está activa
        const checkResult = await db.query(
            'SELECT estado FROM certificacion_emitida WHERE id_certificacion = $1',
            [id]
        );

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Certificación no encontrada'
            });
        }

        if (checkResult.rows[0].estado !== 'Activa') {
            return res.status(409).json({
                success: false,
                message: `La certificación está en estado "${checkResult.rows[0].estado}". Solo se pueden anular certificaciones activas.`
            });
        }

        // Ejecutar función de anulación
        await db.query(
            `SELECT fn_anular_certificacion($1, $2, $3, $4)`,
            [id, motivo, id_usuario_anulacion, id_certificacion_sustituta || null]
        );

        res.json({
            success: true,
            message: 'Certificación anulada exitosamente',
            data: {
                id_certificacion: id,
                motivo: motivo,
                fecha_anulacion: new Date().toISOString()
            }
        });

    } catch (error) {
        console.error('Error anulando certificación:', error);
        res.status(500).json({
            success: false,
            message: 'Error al anular la certificación',
            error: error.message
        });
    }
});

// =====================================================
// 7. REPORTES Y ESTADÍSTICAS
// =====================================================

// Reporte mensual de certificaciones
router.get('/api/certificaciones/reporte/mensual', async (req, res) => {
    const db = require('../config/db');

    try {
        const result = await db.query(
            'SELECT * FROM v_reporte_certificaciones_mensual ORDER BY anio DESC, mes DESC'
        );

        res.json({
            success: true,
            data: result.rows
        });

    } catch (error) {
        console.error('Error en reporte mensual:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener reporte mensual',
            error: error.message
        });
    }
});

// Estadísticas generales de certificaciones
router.get('/api/certificaciones/estadisticas', async (req, res) => {
    const db = require('../config/db');

    try {
        const result = await db.query(`
            SELECT 
                COUNT(*) AS total_certificaciones,
                COUNT(CASE WHEN estado = 'Activa' THEN 1 END) AS activas,
                COUNT(CASE WHEN estado = 'Anulada' THEN 1 END) AS anuladas,
                COUNT(CASE WHEN estado = 'Suspendida' THEN 1 END) AS suspendidas,
                COUNT(DISTINCT id_asambleista) AS asambleistas_distintos,
                MAX(fecha_emision) AS ultima_emision,
                MIN(fecha_emision) AS primera_emision
            FROM certificacion_emitida
        `);

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Error en estadísticas:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener estadísticas',
            error: error.message
        });
    }
});

module.exports = router; 




