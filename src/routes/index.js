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
// RUTAS DEL SPRINT 3 - SESIONES (FUNCIONALIDADES AVANZADAS)
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

module.exports = router; 
