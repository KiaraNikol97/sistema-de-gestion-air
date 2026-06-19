// src/controllers/CertificadorController.js
// Issue #17 - Motor de Certificaciones
// Depende de: Certificado.js (model)

const Certificado = require('../models/Certificado');
const CryptoService = require('../services/CryptoService');

class CertificadorController {

    // =====================================================
    // 1. SOLICITUDES DE CERTIFICACIÓN
    // =====================================================

    // Crear una nueva solicitud
    static async crearSolicitud(req, res) {
        try {
            const {
                id_asambleista,
                periodo_desde,
                periodo_hasta,
                observaciones
            } = req.body;

            const id_usuario_solicitante = req.user?.id || null;

            if (!id_asambleista) {
                return res.status(400).json({
                    success: false,
                    message: 'El campo id_asambleista es obligatorio'
                });
            }

            const solicitud = await Certificado.crearSolicitud({
                id_asambleista,
                periodo_desde,
                periodo_hasta,
                observaciones,
                id_usuario_solicitante
            });

            res.status(201).json({
                success: true,
                message: 'Solicitud creada exitosamente',
                data: solicitud
            });

        } catch (error) {
            console.error('Error en crearSolicitud:', error);
            res.status(500).json({
                success: false,
                message: 'Error al crear la solicitud',
                error: error.message
            });
        }
    }

    // Listar todas las solicitudes
    static async listarSolicitudes(req, res) {
        try {
            const { id_asambleista, estado } = req.query;

            const solicitudes = await Certificado.getSolicitudes({
                id_asambleista,
                estado
            });

            res.json({
                success: true,
                data: solicitudes,
                total: solicitudes.length
            });

        } catch (error) {
            console.error('Error en listarSolicitudes:', error);
            res.status(500).json({
                success: false,
                message: 'Error al listar solicitudes',
                error: error.message
            });
        }
    }

    // Obtener una solicitud por ID
    static async obtenerSolicitud(req, res) {
        try {
            const { id } = req.params;

            const solicitud = await Certificado.getSolicitudById(id);

            if (!solicitud) {
                return res.status(404).json({
                    success: false,
                    message: 'Solicitud no encontrada'
                });
            }

            res.json({
                success: true,
                data: solicitud
            });

        } catch (error) {
            console.error('Error en obtenerSolicitud:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener la solicitud',
                error: error.message
            });
        }
    }

    // Actualizar estado de una solicitud
    static async actualizarSolicitud(req, res) {
        try {
            const { id } = req.params;
            const { estado, id_certificacion_generada } = req.body;

            if (!estado) {
                return res.status(400).json({
                    success: false,
                    message: 'El campo estado es obligatorio'
                });
            }

            const solicitud = await Certificado.getSolicitudById(id);
            if (!solicitud) {
                return res.status(404).json({
                    success: false,
                    message: 'Solicitud no encontrada'
                });
            }

            const solicitudActualizada = await Certificado.actualizarSolicitud(
                id, estado, id_certificacion_generada || null
            );

            res.json({
                success: true,
                message: `Solicitud actualizada a estado "${estado}"`,
                data: solicitudActualizada
            });

        } catch (error) {
            console.error('Error en actualizarSolicitud:', error);
            res.status(500).json({
                success: false,
                message: 'Error al actualizar la solicitud',
                error: error.message
            });
        }
    }

    // =====================================================
    // 2. GENERACIÓN DE CERTIFICACIONES
    // =====================================================

    // Generar una nueva certificación
    static async generarCertificacion(req, res) {
        try {
            const {
                id_solicitud,
                id_asambleista,
                periodo_desde,
                periodo_hasta,
                id_certificacion_sustituye
            } = req.body;

            const id_usuario_secretaria = req.user?.id || 1;

            if (!id_asambleista) {
                return res.status(400).json({
                    success: false,
                    message: 'El campo id_asambleista es obligatorio'
                });
            }

            // Obtener datos consolidados del asambleísta
            const datos = await Certificado.getDatosConsolidados(id_asambleista);

            if (!datos) {
                return res.status(404).json({
                    success: false,
                    message: 'No se encontraron datos del asambleísta para generar la certificación'
                });
            }

            // Construir el contenido JSON de la certificación
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

            // Generar la certificación
            const certificacion = await Certificado.generarCertificacion({
                id_solicitud: id_solicitud || null,
                id_asambleista,
                contenido_json,
                id_usuario_secretaria,
                id_certificacion_sustituye: id_certificacion_sustituye || null
            });

            res.status(201).json({
                success: true,
                message: 'Certificación generada exitosamente',
                data: {
                    ...certificacion,
                    contenido: contenido_json
                }
            });

        } catch (error) {
            console.error('Error en generarCertificacion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al generar la certificación',
                error: error.message
            });
        }
    }

    // Obtener certificaciones de un asambleísta
    static async obtenerCertificacionesAsambleista(req, res) {
        try {
            const { id_asambleista } = req.params;

            const certificaciones = await Certificado.getByAsambleista(id_asambleista);

            res.json({
                success: true,
                data: certificaciones,
                total: certificaciones.length
            });

        } catch (error) {
            console.error('Error en obtenerCertificacionesAsambleista:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener certificaciones',
                error: error.message
            });
        }
    }

    // Obtener una certificación por folio
    static async obtenerCertificacionPorFolio(req, res) {
        try {
            const { folio } = req.params;

            const certificacion = await Certificado.getByFolio(folio);

            if (!certificacion) {
                return res.status(404).json({
                    success: false,
                    message: 'Certificación no encontrada'
                });
            }

            res.json({
                success: true,
                data: certificacion
            });

        } catch (error) {
            console.error('Error en obtenerCertificacionPorFolio:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener la certificación',
                error: error.message
            });
        }
    }

    // Obtener una certificación por ID
    static async obtenerCertificacion(req, res) {
        try {
            const { id } = req.params;

            const certificacion = await Certificado.getDetalleCompleto(id);

            if (!certificacion) {
                return res.status(404).json({
                    success: false,
                    message: 'Certificación no encontrada'
                });
            }

            res.json({
                success: true,
                data: certificacion
            });

        } catch (error) {
            console.error('Error en obtenerCertificacion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener la certificación',
                error: error.message
            });
        }
    }

    // =====================================================
    // 3. VERIFICACIÓN DE CERTIFICACIONES
    // =====================================================

    // Verificar certificación por código
    static async verificarCertificacion(req, res) {
        try {
            const { codigo } = req.params;

            const resultado = await Certificado.verificarPorCodigo(codigo);

            res.json({
                success: true,
                data: resultado
            });

        } catch (error) {
            console.error('Error en verificarCertificacion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al verificar la certificación',
                error: error.message
            });
        }
    }

    // Obtener código de verificación de una certificación
    static async obtenerCodigoVerificacion(req, res) {
        try {
            const { id } = req.params;

            const certificacion = await Certificado.getById(id);

            if (!certificacion) {
                return res.status(404).json({
                    success: false,
                    message: 'Certificación no encontrada'
                });
            }

            res.json({
                success: true,
                data: {
                    codigo_verificacion: certificacion.codigo_verificacion,
                    url_verificacion: certificacion.url_verificacion || `/verificar/${certificacion.codigo_verificacion}`,
                    qr_code: certificacion.codigo_verificacion
                }
            });

        } catch (error) {
            console.error('Error en obtenerCodigoVerificacion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener código de verificación',
                error: error.message
            });
        }
    }

    // =====================================================
    // 4. ANULACIÓN DE CERTIFICACIONES
    // =====================================================

    // Anular una certificación
    static async anularCertificacion(req, res) {
        try {
            const { id } = req.params;
            const { motivo, id_certificacion_sustituta } = req.body;

            const id_usuario_anulacion = req.user?.id || 1;

            if (!motivo) {
                return res.status(400).json({
                    success: false,
                    message: 'El campo motivo es obligatorio para anular una certificación'
                });
            }

            const resultado = await Certificado.anular(
                id,
                motivo,
                id_usuario_anulacion,
                id_certificacion_sustituta || null
            );

            res.json({
                success: true,
                message: 'Certificación anulada exitosamente',
                data: resultado
            });

        } catch (error) {
            console.error('Error en anularCertificacion:', error);
            res.status(500).json({
                success: false,
                message: 'Error al anular la certificación',
                error: error.message
            });
        }
    }

    // =====================================================
    // 5. REPORTES Y ESTADÍSTICAS
    // =====================================================

    // Obtener reporte de certificaciones por mes
    static async obtenerReporteMensual(req, res) {
        try {
            const reporte = await Certificado.getReporteMensual();

            res.json({
                success: true,
                data: reporte
            });

        } catch (error) {
            console.error('Error en obtenerReporteMensual:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener reporte mensual',
                error: error.message
            });
        }
    }

    // Obtener estadísticas generales
    static async obtenerEstadisticas(req, res) {
        try {
            const estadisticas = await Certificado.getEstadisticas();

            res.json({
                success: true,
                data: estadisticas
            });

        } catch (error) {
            console.error('Error en obtenerEstadisticas:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener estadísticas',
                error: error.message
            });
        }
    }

    // Obtener datos consolidados de un asambleísta (para vista previa)
    static async obtenerDatosConsolidados(req, res) {
        try {
            const { id_asambleista } = req.params;

            const datos = await Certificado.getDatosConsolidados(id_asambleista);

            if (!datos) {
                return res.status(404).json({
                    success: false,
                    message: 'No se encontraron datos del asambleísta'
                });
            }

            res.json({
                success: true,
                data: datos
            });

        } catch (error) {
            console.error('Error en obtenerDatosConsolidados:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener datos consolidados',
                error: error.message
            });
        }
    }
}

module.exports = CertificadorController;