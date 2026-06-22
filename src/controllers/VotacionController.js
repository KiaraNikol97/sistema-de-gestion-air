// src/controllers/VotacionController.js
// Issue #12 - Motor de Votaciones
// Depende de: Votacion.js (model)

const Votacion = require('../models/Votacion');
const Sesion = require('../models/Sesion');

class VotacionController {

    // =====================================================
    // 1. CRUD DE VOTACIONES
    // =====================================================

    // Crear una nueva votación
    static async crearVotacion(req, res) {
        try {
            const {
                id_sesion,
                id_propuesta,
                id_elemento_normativo,
                numero_votacion,
                tipo_votacion,
                id_tipo_mayoria_requerida,
                id_tipo_votacion
            } = req.body;

            // Validar campos obligatorios
            if (!id_sesion || !id_tipo_mayoria_requerida || !id_tipo_votacion) {
                return res.status(400).json({
                    success: false,
                    message: 'Faltan campos: id_sesion, id_tipo_mayoria_requerida, id_tipo_votacion'
                });
            }

            // Verificar que la sesión permita votar
            const puedeVotar = await Votacion.puedeVotar(id_sesion);
            if (!puedeVotar.puede) {
                return res.status(409).json({
                    success: false,
                    message: puedeVotar.motivo
                });
            }

            const nuevaVotacion = await Votacion.create({
                id_sesion,
                id_propuesta,
                id_elemento_normativo,
                numero_votacion,
                tipo_votacion: tipo_votacion || 'Publica',
                id_tipo_mayoria_requerida,
                id_tipo_votacion
            });

            // Actualizar estado de la sesión a "En Curso" si no lo está
            const sesion = await Sesion.getById(id_sesion);
            if (sesion && sesion.estado !== 'En Curso') {
                await Sesion.cambiarEstado(id_sesion, 'En Curso');
            }

            res.status(201).json({
                success: true,
                message: 'Votación creada exitosamente',
                data: nuevaVotacion
            });

        } catch (error) {
            console.error('Error en crearVotacion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al crear la votación',
                error: error.message
            });
        }
    }

    // Listar todas las votaciones
    static async listarVotaciones(req, res) {
        try {
            const { id_sesion, resultado } = req.query;

            const votaciones = await Votacion.getAll({
                id_sesion,
                resultado
            });

            res.json({
                success: true,
                data: votaciones,
                total: votaciones.length
            });

        } catch (error) {
            console.error('Error en listarVotaciones:', error);
            res.status(500).json({
                success: false,
                message: 'Error al listar votaciones',
                error: error.message
            });
        }
    }

    // Obtener una votación por ID
    static async obtenerVotacion(req, res) {
        try {
            const { id } = req.params;

            const votacion = await Votacion.getById(id);

            if (!votacion) {
                return res.status(404).json({
                    success: false,
                    message: 'Votación no encontrada'
                });
            }

            res.json({
                success: true,
                data: votacion
            });

        } catch (error) {
            console.error('Error en obtenerVotacion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener la votación',
                error: error.message
            });
        }
    }

    // =====================================================
    // 2. PROCESAMIENTO DE VOTOS
    // =====================================================

    // Registrar un voto
    static async registrarVoto(req, res) {
        try {
            const { id } = req.params; // id_votacion
            const { tipo_voto } = req.body;

            if (!tipo_voto) {
                return res.status(400).json({
                    success: false,
                    message: 'El campo "tipo_voto" es obligatorio (Favor, Contra, Abstencion)'
                });
            }

            const votacionActualizada = await Votacion.registrarVoto(id, tipo_voto);

            res.json({
                success: true,
                message: `Voto "${tipo_voto}" registrado exitosamente`,
                data: votacionActualizada
            });

        } catch (error) {
            console.error('Error en registrarVoto:', error);
            res.status(500).json({
                success: false,
                message: 'Error al registrar el voto',
                error: error.message
            });
        }
    }

    // Finalizar votación
    static async finalizarVotacion(req, res) {
        try {
            const { id } = req.params;

            const votacion = await Votacion.getById(id);
            if (!votacion) {
                return res.status(404).json({
                    success: false,
                    message: 'Votación no encontrada'
                });
            }

            if (votacion.resultado !== 'Pendiente') {
                return res.status(409).json({
                    success: false,
                    message: `La votación ya fue ${votacion.resultado.toLowerCase()}`
                });
            }

            const resultado = await Votacion.finalizarVotacion(id);

            // Obtener el resultado detallado
            const resultadoDetalle = await Votacion.getResultadoVotacion(id);

            res.json({
                success: true,
                message: 'Votación finalizada exitosamente',
                data: {
                    votacion: resultado,
                    resultado: resultadoDetalle
                }
            });

        } catch (error) {
            console.error('Error en finalizarVotacion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al finalizar la votación',
                error: error.message
            });
        }
    }

    // =====================================================
    // 3. CONSULTAS DE RESULTADOS
    // =====================================================

    // Obtener resultado de una votación
    static async obtenerResultado(req, res) {
        try {
            const { id } = req.params;

            const resultado = await Votacion.getResultadoVotacion(id);

            if (!resultado) {
                return res.status(404).json({
                    success: false,
                    message: 'Resultado de votación no encontrado'
                });
            }

            res.json({
                success: true,
                data: resultado
            });

        } catch (error) {
            console.error('Error en obtenerResultado:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener el resultado',
                error: error.message
            });
        }
    }

    // Verificar si se puede votar en una sesión
    static async verificarPuedeVotar(req, res) {
        try {
            const { id_sesion } = req.params;

            const resultado = await Votacion.puedeVotar(id_sesion);

            res.json({
                success: true,
                data: resultado
            });

        } catch (error) {
            console.error('Error en verificarPuedeVotar:', error);
            res.status(500).json({
                success: false,
                message: 'Error al verificar si se puede votar',
                error: error.message
            });
        }
    }

    // =====================================================
    // 4. REPORTES Y ESTADÍSTICAS
    // =====================================================

    // Obtener estadísticas de votaciones por sesión
    static async obtenerEstadisticasSesion(req, res) {
        try {
            const { id_sesion } = req.params;

            const estadisticas = await Votacion.getEstadisticasBySesion(id_sesion);

            res.json({
                success: true,
                data: estadisticas
            });

        } catch (error) {
            console.error('Error en obtenerEstadisticasSesion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener estadísticas',
                error: error.message
            });
        }
    }

    // Obtener reporte por tipo de mayoría
    static async obtenerReportePorTipoMayoria(req, res) {
        try {
            const reporte = await Votacion.getReportePorTipoMayoria();

            res.json({
                success: true,
                data: reporte
            });

        } catch (error) {
            console.error('Error en obtenerReportePorTipoMayoria:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener reporte',
                error: error.message
            });
        }
    }

    // =====================================================
    // 5. ELIMINAR VOTACIÓN
    // =====================================================

    static async eliminarVotacion(req, res) {
        try {
            const { id } = req.params;

            const resultado = await Votacion.delete(id);

            res.json({
                success: true,
                message: 'Votación eliminada exitosamente',
                data: resultado
            });

        } catch (error) {
            console.error('Error en eliminarVotacion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al eliminar la votación',
                error: error.message
            });
        }
    }
}

module.exports = VotacionController;