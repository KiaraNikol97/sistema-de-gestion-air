// :::::::::::::::::::::::::::::::::::::::::::::::::
// ISSUE #15 - Modelo de Reformas y Versionamiento
// Autora: María Fernanda Vargas Guzmán
// Sprint 2 - Semana 2 
// Controller MVC
// :::::::::::::::::::::::::::::::::::::::::::::::::

// Conectar
const ReformaModels = require("../models/ReformaModels");

class ReformaController {

    constructor() {
        this.reformaModel = new ReformaModels();
    }

    async registrarReforma(datos) {

        if (!datos.texto_nuevo) {
            console.log("Error: Debe existir un nuevo texto.");
            return;
        }

        if (!datos.id_elemento_normativo) {
            console.log("Error: Debe indicarse el elemento normativo.");
            return;
        }

        if (!datos.fecha_inicio_vigencia) {
            console.log("Error: Debe indicarse la fecha de inicio de vigencia.");
            return;
        }

        return await this.reformaModel.registrarReforma(datos);
    }

    async consultarVersionVigente(id_reglamento, numero_etiqueta) {

        if (!id_reglamento || !numero_etiqueta) {
            console.log("Error: Faltan datos para consultar la versión vigente.");
            return;
        }

        return await this.reformaModel.obtenerElementoVigente(
            id_reglamento,
            numero_etiqueta
        );
    }

    async consultarHistorialVersiones(id_reglamento, numero_etiqueta) {

        if (!id_reglamento || !numero_etiqueta) {
            console.log("Error: Faltan datos para consultar el historial.");
            return;
        }

        return await this.reformaModel.obtenerHistorialVersiones(
            id_reglamento,
            numero_etiqueta
        );
    }
}

module.exports = ReformaController;
