// :::::::::::::::::::::::::::::::::::::::::::::::::
// ISSUE #15 - Modelo de Reformas y Versionamiento
// Autora: María Fernanda Vargas Guzmán
// Sprint 2 - Semana 2 
// Controller MVC
// :::::::::::::::::::::::::::::::::::::::::::::::::

const Reforma = require("../models/Reforma");

class ReformaController {

    constructor() {
        this.reformaModel = new Reforma();
    }

    registrarReforma(datos) {

        // Validaciones básicas
        if (!datos.texto_nuevo) {

            console.log(
                "Error: Debe existir un nuevo texto."
            );

            return;
        }

        // Llamada al modelo
        this.reformaModel.registrarReforma(datos);
    }

    consultarVersionVigente(id_reglamento, numero_etiqueta) {

        this.reformaModel.obtenerElementoVigente(
            id_reglamento,
            numero_etiqueta
        );
    }
}

module.exports = ReformaController;
