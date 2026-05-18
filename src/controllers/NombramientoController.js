const Nombramiento = require('../models/Nombramiento');

/**
 * Controlador para gestionar nombramientos de asambleístas
 * Issue #14 - Historial de Nombramientos
 */

// Registrar un nuevo nombramiento
exports.registrarNombramiento = async (req, res) => {
    try {
        const {
            asambleista_id,
            sector_id,
            id_puesto,
            resolucion_id,
            fecha_inicio,
            fecha_fin,
            observaciones
        } = req.body;
        
        const id_usuario_registro = req.user?.id_usuario || 1; // Temporal: usar de sesión real
        
        // Validar campos obligatorios
        if (!asambleista_id || !sector_id || !id_puesto || !fecha_inicio) {
            return res.status(400).json({
                success: false,
                message: 'Faltan campos obligatorios: asambleista_id, sector_id, id_puesto, fecha_inicio'
            });
        }
        
        // Validar traslape de fechas
        const noHayTraslape = await Nombramiento.validarTraslape(
            asambleista_id,
            id_puesto,
            fecha_inicio,
            fecha_fin
        );
        
        if (!noHayTraslape) {
            return res.status(409).json({
                success: false,
                message: 'El asambleísta ya tiene un nombramiento activo para este puesto en el período indicado'
            });
        }
        
        const id_nombramiento = await Nombramiento.create({
            asambleista_id,
            sector_id,
            id_puesto,
            resolucion_id,
            fecha_inicio,
            fecha_fin,
            id_usuario_registro,
            observaciones
        });
        
        res.status(201).json({
            success: true,
            message: 'Nombramiento registrado exitosamente',
            data: { id_nombramiento }
        });
        
    } catch (error) {
        console.error('Error en registrarNombramiento:', error);
        
        if (error.message.includes('nombramiento activo')) {
            return res.status(409).json({
                success: false,
                message: error.message
            });
        }
        
        res.status(500).json({
            success: false,
            message: 'Error interno al registrar nombramiento'
        });
    }
};

// Finalizar un nombramiento (dar de baja)
exports.finalizarNombramiento = async (req, res) => {
    try {
        const { id } = req.params;
        const { fecha_fin, observacion } = req.body;
        const id_usuario = req.user?.id_usuario || 1;
        
        if (!fecha_fin) {
            return res.status(400).json({
                success: false,
                message: 'La fecha de finalización es obligatoria'
            });
        }
        
        await Nombramiento.finalizar(id, fecha_fin, id_usuario, observacion || 'Finalizado por usuario');
        
        res.json({
            success: true,
            message: 'Nombramiento finalizado exitosamente'
        });
        
    } catch (error) {
        console.error('Error en finalizarNombramiento:', error);
        
        if (error.message.includes('No se encontró')) {
            return res.status(404).json({
                success: false,
                message: error.message
            });
        }
        
        res.status(500).json({
            success: false,
            message: 'Error interno al finalizar nombramiento'
        });
    }
};

// Obtener historial de nombramientos de un asambleísta
exports.getHistorialAsambleista = async (req, res) => {
    try {
        const { asambleista_id } = req.params;
        
        if (!asambleista_id) {
            return res.status(400).json({
                success: false,
                message: 'El ID del asambleísta es requerido'
            });
        }
        
        const historial = await Nombramiento.getHistorialByAsambleistaId(asambleista_id);
        
        res.json({
            success: true,
            data: historial,
            total: historial.length
        });
        
    } catch (error) {
        console.error('Error en getHistorialAsambleista:', error);
        res.status(500).json({
            success: false,
            message: 'Error interno al obtener historial'
        });
    }
};

// Obtener el sector vigente actual de un asambleísta
exports.getSectorVigente = async (req, res) => {
    try {
        const { asambleista_id } = req.params;
        
        const vigente = await Nombramiento.getVigenteByAsambleistaId(asambleista_id);
        
        if (!vigente) {
            return res.json({
                success: true,
                data: null,
                message: 'El asambleísta no tiene un nombramiento vigente actualmente'
            });
        }
        
        res.json({
            success: true,
            data: {
                sector: vigente.sector,
                puesto: vigente.puesto,
                desde: vigente.fecha_inicio,
                hasta: vigente.fecha_fin || 'Indefinido'
            }
        });
        
    } catch (error) {
        console.error('Error en getSectorVigente:', error);
        res.status(500).json({
            success: false,
            message: 'Error interno al obtener sector vigente'
        });
    }
};

// Listar todos los nombramientos (con filtros)
exports.listarNombramientos = async (req, res) => {
    try {
        const { estado, sector_id } = req.query;
        
        const nombramientos = await Nombramiento.getAll({ estado, sector_id });
        
        res.json({
            success: true,
            data: nombramientos,
            total: nombramientos.length,
            filtros: { estado, sector_id: sector_id || null }
        });
        
    } catch (error) {
        console.error('Error en listarNombramientos:', error);
        res.status(500).json({
            success: false,
            message: 'Error interno al listar nombramientos'
        });
    }
};

// Obtener reporte de nombramientos por sector
exports.getReportePorSector = async (req, res) => {
    try {
        const reporte = await Nombramiento.getReportePorSector();
        
        res.json({
            success: true,
            data: reporte
        });
        
    } catch (error) {
        console.error('Error en getReportePorSector:', error);
        res.status(500).json({
            success: false,
            message: 'Error interno al generar reporte'
        });
    }
};
