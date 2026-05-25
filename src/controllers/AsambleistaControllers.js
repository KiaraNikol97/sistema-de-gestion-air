// :::::::::::::::::::::::::::::::::::::::::::::::::
// ISSUE #9 - Catálogo de Asambleístas
// Autora: María Fernanda Vargas Guzmán
// Sprint 2 - Semana 2 
// Controller MVC
// :::::::::::::::::::::::::::::::::::::::::::::::::

// Conectarse
const AsambleistaModel = require('../models/AsambleistaModels');

// Mostrar listado de asambleístas
async function mostrarAsambleistas(req, res) {

    try {

        const asambleistas = await AsambleistaModel.listarAsambleistas();

        res.render("asambleistas", {
            asambleistas: asambleistas,
            mensaje: null,
            error: null
        });

    } catch (error) {

        res.render("asambleistas", {
            asambleistas: [],
            mensaje: null,
            error: "Error al mostrar los asambleístas."
        });
    }
}

// Registrar nuevo asambleísta
async function registrarAsambleista(req, res) {

    try {

        const cedula = req.body.cedula;
        const nombre = req.body.nombre;
        const correo = req.body.correo;

        // Validar campos obligatorios
        if (!cedula || !nombre) {

            return res.send("La cédula y el nombre son obligatorios.");
        }

        // Validar formato de cédula
        const formatoCedula = /^[0-9]-[0-9]{4}-[0-9]{4}$/;

        if (!formatoCedula.test(cedula)) {

            return res.send("La cédula debe tener el formato 0-0000-0000.");
        }

        // Validar cédula duplicada
        const existeCedula = await AsambleistaModel.buscarPorCedula(cedula);

        if (existeCedula) {

            return res.send("Ya existe un asambleísta registrado con esa cédula.");
        }

        // Crear asambleísta
        await AsambleistaModel.crearAsambleista(
            cedula,
            nombre,
            correo
        );

        res.redirect("/asambleistas");

    } catch (error) {

        res.send("Error al registrar el asambleísta.");
    }
}


// Buscar asambleístas
async function buscarAsambleistas(req, res) {

    try {

        const textoBusqueda = req.query.buscar;

        let asambleistas;

        if (!textoBusqueda) {

            asambleistas = await AsambleistaModel.listarAsambleistas();

        } else {

            asambleistas = await AsambleistaModel.buscarAsambleistas(textoBusqueda);
        }

        res.render("asambleistas", {
            asambleistas: asambleistas,
            mensaje: null,
            error: null
        });

    } catch (error) {

        res.send("Error al buscar asambleístas.");
    }
}


// Editar asambleísta
async function editarAsambleista(req, res) {

    try {

        const id_asambleista = req.params.id;

        const cedula = req.body.cedula;
        const nombre = req.body.nombre;
        const correo = req.body.correo;

        // Validar campos obligatorios
        if (!cedula || !nombre) {

            return res.send("La cédula y el nombre son obligatorios.");
        }

        // Validar formato de cédula
        const formatoCedula = /^[0-9]-[0-9]{4}-[0-9]{4}$/;

        if (!formatoCedula.test(cedula)) {

            return res.send("Formato de cédula inválido.");
        }

        // Editar asambleísta
        await AsambleistaModel.editarAsambleista(
            id_asambleista,
            cedula,
            nombre,
            correo
        );

        res.redirect("/asambleistas");

    } catch (error) {

        res.send("Error al editar el asambleísta.");
    }
}


// Eliminar asambleísta
async function eliminarAsambleista(req, res) {

    try {

        const id_asambleista = req.params.id;

        await AsambleistaModel.eliminarAsambleista(id_asambleista);

        res.redirect("/asambleistas");

    } catch (error) {

        res.send("Error al eliminar el asambleísta.");
    }
}


// Mostrar bitácora de cambios
async function mostrarBitacora(req, res) {

    try {

        const id_asambleista = req.params.id;

        const bitacora = await AsambleistaModel.obtenerBitacoraAsambleista(id_asambleista);

        res.render("bitacoraAsambleista", {
            bitacora: bitacora
        });

    } catch (error) {

        res.send("Error al mostrar la bitácora.");
    }
}


module.exports = {
    mostrarAsambleistas,
    registrarAsambleista,
    buscarAsambleistas,
    editarAsambleista,
    eliminarAsambleista,
    mostrarBitacora
};
