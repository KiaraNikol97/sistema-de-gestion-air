// src/controllers/SesionController.js
// Issue #11 - Control de Quórum y Sesiones
// Depende de: Sesion.js (model)

const Sesion = require('../models/Sesion');
const authorize = require('../Middleware/authMiddleware');

class SesionController {

    // =====================================================
    // 1. CRUD DE SESIONES
    // =====================================================

    // Crear una nueva sesión
    static async crearSesion(req, res) {
        try {
            const { 
                id_tipo_modalidad,
                id_tipo_sesion,
                numero_sesion,
                fecha,
                hora_inicio,
                hora_fin,
                link_acta
            } = req.body;

            const id_usuario_registro = req.user?.id || 1;

            // Validar campos obligatorios
            if (!id_tipo_modalidad || !id_tipo_sesion || !numero_sesion || !fecha) {
                return res.status(400).json({
                    success: false,
                    message: 'Faltan campos obligatorios: id_tipo_modalidad, id_tipo_sesion, numero_sesion, fecha'
                });
            }

            const nuevaSesion = await Sesion.create({
                id_tipo_modalidad,
                id_tipo_sesion,
                numero_sesion,
                fecha,
                hora_inicio,
                hora_fin,
                link_acta,
                id_usuario_registro
            });

            res.status(201).json({
                success: true,
                message: 'Sesión creada exitosamente',
                data: nuevaSesion
            });

        } catch (error) {
            console.error('Error en crearSesion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al crear la sesión',
                error: error.message
            });
        }
    }

    // Listar todas las sesiones
    static async listarSesiones(req, res) {
        try {
            const { estado, fecha_desde, fecha_hasta } = req.query;

            const sesiones = await Sesion.getAll({
                estado,
                fecha_desde,
                fecha_hasta
            });

            res.json({
                success: true,
                data: sesiones,
                total: sesiones.length
            });

        } catch (error) {
            console.error('Error en listarSesiones:', error);
            res.status(500).json({
                success: false,
                message: 'Error al listar sesiones',
                error: error.message
            });
        }
    }

    // Obtener una sesión por ID
    static async obtenerSesion(req, res) {
        try {
            const { id } = req.params;

            const sesion = await Sesion.getById(id);

            if (!sesion) {
                return res.status(404).json({
                    success: false,
                    message: 'Sesión no encontrada'
                });
            }

            res.json({
                success: true,
                data: sesion
            });

        } catch (error) {
            console.error('Error en obtenerSesion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener la sesión',
                error: error.message
            });
        }
    }

    // Actualizar una sesión
    static async actualizarSesion(req, res) {
        try {
            const { id } = req.params;
            const data = req.body;

            const sesion = await Sesion.getById(id);
            if (!sesion) {
                return res.status(404).json({
                    success: false,
                    message: 'Sesión no encontrada'
                });
            }

            const sesionActualizada = await Sesion.update(id, data);

            res.json({
                success: true,
                message: 'Sesión actualizada exitosamente',
                data: sesionActualizada
            });

        } catch (error) {
            console.error('Error en actualizarSesion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al actualizar la sesión',
                error: error.message
            });
        }
    }

    // Cambiar estado de una sesión
    static async cambiarEstado(req, res) {
        try {
            const { id } = req.params;
            const { estado } = req.body;

            if (!estado) {
                return res.status(400).json({
                    success: false,
                    message: 'El campo "estado" es obligatorio'
                });
            }

            const sesion = await Sesion.getById(id);
            if (!sesion) {
                return res.status(404).json({
                    success: false,
                    message: 'Sesión no encontrada'
                });
            }

            const sesionActualizada = await Sesion.cambiarEstado(id, estado);

            res.json({
                success: true,
                message: `Estado de sesión cambiado a "${estado}"`,
                data: sesionActualizada
            });

        } catch (error) {
            console.error('Error en cambiarEstado:', error);
            res.status(500).json({
                success: false,
                message: 'Error al cambiar el estado',
                error: error.message
            });
        }
    }

    // Eliminar una sesión
    static async eliminarSesion(req, res) {
        try {
            const { id } = req.params;

            const resultado = await Sesion.delete(id);

            res.json({
                success: true,
                message: 'Sesión eliminada exitosamente',
                data: resultado
            });

        } catch (error) {
            console.error('Error en eliminarSesion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al eliminar la sesión',
                error: error.message
            });
        }
    }

    // =====================================================
    // 2. GESTIÓN DE ASISTENCIA
    // =====================================================

    // Registrar asistencia de un asambleísta
    static async registrarAsistencia(req, res) {
        try {
            const { id } = req.params; // id_sesion
            const { id_asambleista, id_estado_asistencia, observaciones } = req.body;

            if (!id_asambleista || !id_estado_asistencia) {
                return res.status(400).json({
                    success: false,
                    message: 'Faltan campos: id_asambleista, id_estado_asistencia'
                });
            }

            const asistencia = await Sesion.registrarAsistencia(
                id, id_asambleista, id_estado_asistencia, observaciones
            );

            res.json({
                success: true,
                message: 'Asistencia registrada exitosamente',
                data: asistencia
            });

        } catch (error) {
            console.error('Error en registrarAsistencia:', error);
            res.status(500).json({
                success: false,
                message: 'Error al registrar asistencia',
                error: error.message
            });
        }
    }

    // Obtener lista de asistencia de una sesión
    static async obtenerAsistencia(req, res) {
        try {
            const { id } = req.params;

            const asistencia = await Sesion.getAsistenciaBySesion(id);

            res.json({
                success: true,
                data: asistencia,
                total: asistencia.length
            });

        } catch (error) {
            console.error('Error en obtenerAsistencia:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener la asistencia',
                error: error.message
            });
        }
    }

    // Obtener resumen de asistencia de una sesión
    static async obtenerResumenAsistencia(req, res) {
        try {
            const { id } = req.params;

            const resumen = await Sesion.getResumenAsistencia(id);

            res.json({
                success: true,
                data: resumen
            });

        } catch (error) {
            console.error('Error en obtenerResumenAsistencia:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener resumen de asistencia',
                error: error.message
            });
        }
    }

    // =====================================================
    // 3. FUNCIONES DE QUÓRUM
    // =====================================================

    // Verificar quórum de una sesión
    static async verificarQuorum(req, res) {
        try {
            const { id } = req.params;

            const quorumValido = await Sesion.validarQuorum(id);
            const asistentes = await Sesion.getAsistentesParaQuorum(id);
            const requerido = await Sesion.getQuorumRequerido(id);

            res.json({
                success: true,
                data: {
                    quorum_valido: quorumValido,
                    presentes: asistentes,
                    requeridos: requerido,
                    estado: quorumValido ? 'Quórum válido' : 'Quórum insuficiente'
                }
            });

        } catch (error) {
            console.error('Error en verificarQuorum:', error);
            res.status(500).json({
                success: false,
                message: 'Error al verificar quórum',
                error: error.message
            });
        }
    }

    // =====================================================
    // 4. REPORTES
    // =====================================================

    // Obtener estado de quórum de todas las sesiones
    static async obtenerEstadoQuorumAll(req, res) {
        try {
            const reporte = await Sesion.getEstadoQuorumAll();

            res.json({
                success: true,
                data: reporte
            });

        } catch (error) {
            console.error('Error en obtenerEstadoQuorumAll:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener reporte de quórum',
                error: error.message
            });
        }
    }

    // Obtener historial de asistencia de un asambleísta
    static async obtenerHistorialAsistencia(req, res) {
        try {
            const { id_asambleista } = req.params;

            const historial = await Sesion.getHistorialAsistenciaAsambleista(id_asambleista);

            res.json({
                success: true,
                data: historial,
                total: historial.length
            });

        } catch (error) {
            console.error('Error en obtenerHistorialAsistencia:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener historial de asistencia',
                error: error.message
            });
        }
    }
}

module.exports = SesionController;