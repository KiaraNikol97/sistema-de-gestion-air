// src/controllers/NormativaController.js
// Descripción: Controlador para normativa (reglas de jerarquía)

const NormativaModel = require('../models/NormativaModel');

class NormativaController {
    constructor() {
        this.model = new NormativaModel();
    }
    
    // Mostrar página principal del compilador
    async mostrarCompilador(req, res) {
        try {
            const reglamentos = await this.model.getAllReglamentos();
            res.render('normativa/arbol.view.html', { 
                reglamentos,
                arbol: [],
                mensaje: null
            });
        } catch (error) {
            console.error(error);
            res.status(500).render('error', { mensaje: 'Error al cargar reglamentos' });
        }
    }
    
    // Obtener árbol de un reglamento (API para AJAX)
    async getArbol(req, res) {
        try {
            const id_reglamento = req.params.id;
            const arbol = await this.model.getArbolReglamento(id_reglamento);
            res.json({ success: true, data: arbol });
        } catch (error) {
            console.error(error);
            res.status(500).json({ success: false, error: error.message });
        }
    }
    
    // Mostrar formulario de creación
    async mostrarFormularioCreacion(req, res) {
        try {
            const reglamentos = await this.model.getAllReglamentos();
            const niveles = await this.model.getNiveles();
            
            // Obtener elementos disponibles para ser padre (opcional)
            const [elementos] = await pool.query(
                'SELECT id_elemento, numero_etiqueta, contenido_texto FROM elemento_normativo WHERE fecha_fin_vigencia IS NULL LIMIT 100'
            );
            
            res.render('normativa/editar.view.html', { 
                reglamentos, 
                niveles,
                elementos,
                modo: 'crear',
                datos: null,
                errores: null
            });
        } catch (error) {
            console.error(error);
            res.status(500).render('error', { mensaje: 'Error al cargar formulario' });
        }
    }
    
    // Crear nuevo elemento (con reglas de jerarquía)
    async crearElemento(req, res) {
        try {
            const datos = req.body;
            const id_usuario = req.session?.usuario?.id_usuario || 1; // Temporal
            
            // REGLA DE JERARQUÍA: Validar nivel contra el padre
            if (datos.id_elemento_padre && datos.id_elemento_padre !== '') {
                const padre = await this.model.getElementByIdoById(datos.id_elemento_padre);
                
                if (!padre) {
                    throw new Error('El elemento padre no existe');
                }
                
                const nivelPadre = padre.id_nivel_reglamento;
                const nivelHijo = parseInt(datos.id_nivel_reglamento);
                
                // Un hijo debe tener nivel MAYOR que su padre (más específico)
                if (nivelHijo <= nivelPadre) {
                    throw new Error(`No se puede insertar un "${await this.getNombreNivel(nivelHijo)}" dentro de un "${padre.nivel_nombre}". El nivel debe ser inferior.`);
                }
            }
            
            // Validar que no exista otra versión vigente del mismo elemento
            const id_elemento_padre = datos.id_elemento_padre || null;
            const existeVigente = await this.model.existeVersionVigente(
                datos.id_reglamento,
                datos.numero_etiqueta,
                id_elemento_padre
            );
            
            if (existeVigente && !datos.es_nueva_version) {
                throw new Error(`Ya existe una versión vigente del elemento ${datos.numero_etiqueta}. Use "Publicar nueva versión" para modificarlo.`);
            }
            
            // Crear elemento
            const nuevoId = await this.model.crearElemento({
                ...datos,
                id_usuario_registro: id_usuario,
                fecha_inicio_vigencia: datos.fecha_inicio_vigencia || new Date().toISOString().split('T')[0]
            });
            
            req.session.mensaje = { tipo: 'success', texto: 'Elemento creado con éxito' };
            res.redirect(`/normativa/elemento/${nuevoId}`);
            
        } catch (error) {
            console.error(error);
            const reglamentos = await this.model.getAllReglamentos();
            const niveles = await this.model.getNiveles();
            res.status(400).render('normativa/editar.view.html', { 
                reglamentos, 
                niveles,
                modo: 'crear',
                datos: req.body,
                errores: [error.message]
            });
        }
    }
    
    // Mostrar formulario de edición
    async mostrarFormularioEdicion(req, res) {
        try {
            const id_elemento = req.params.id;
            const elemento = await this.model.getElementByIdoById(id_elemento);
            
            if (!elemento) {
                throw new Error('Elemento no encontrado');
            }
            
            const reglamentos = await this.model.getAllReglamentos();
            const niveles = await this.model.getNiveles();
            
            res.render('normativa/editar.view.html', { 
                reglamentos, 
                niveles,
                modo: 'editar',
                datos: elemento,
                errores: null
            });
        } catch (error) {
            console.error(error);
            res.status(404).render('error', { mensaje: error.message });
        }
    }
    
    // Publicar nueva versión
    async publicarNuevaVersion(req, res) {
        try {
            const { id_elemento, nuevo_texto, justificacion } = req.body;
            const id_usuario = req.session?.usuario?.id_usuario || 1;
            const fecha_inicio = new Date().toISOString().split('T')[0];
            
            const nuevoId = await this.model.publicarNuevaVersion(
                id_elemento, 
                nuevo_texto, 
                fecha_inicio, 
                id_usuario
            );
            
            req.session.mensaje = { 
                tipo: 'success', 
                texto: 'Nueva versión publicada correctamente. La versión anterior quedó como "Histórica".' 
            };
            res.redirect(`/normativa/elemento/${nuevoId}`);
            
        } catch (error) {
            console.error(error);
            res.status(400).json({ success: false, error: error.message });
        }
    }
    
    // Eliminar elemento
    async eliminarElemento(req, res) {
        try {
            const id_elemento = req.params.id;
            
            // Verificar si tiene hijos
            const tieneHijos = await this.model.tieneHijos(id_elemento);
            if (tieneHijos) {
                throw new Error('No se puede eliminar un elemento que tiene elementos hijos');
            }
            
            await this.model.eliminarElemento(id_elemento);
            
            req.session.mensaje = { tipo: 'success', texto: 'Elemento eliminado con éxito' };
            res.json({ success: true });
            
        } catch (error) {
            console.error(error);
            res.status(400).json({ success: false, error: error.message });
        }
    }
    
    // Helper: obtener nombre del nivel por ID
    async getNombreNivel(id_nivel) {
        const [rows] = await pool.query(
            'SELECT nombre FROM catalogo_nivel_reglamento WHERE id_nivel_reglamento = ?',
            [id_nivel]
        );
        return rows[0]?.nombre || 'Nivel desconocido';
    }
}

module.exports = NormativaController;
