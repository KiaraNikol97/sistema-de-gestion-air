// :::::::::::::::::::::::::::::::::::::::::::::::::
// ISSUE #15 - Modelo de Reformas y Versionamiento
// Autora: María Fernanda Vargas Guzmán
// Sprint 2 - Semana 2
// :::::::::::::::::::::::::::::::::::::::::::::::::

class Reforma {

    // Registrar una reforma normativa
    registrarReforma(datos) {

        /*
        Aquí se ejecutará el INSERT sobre:
        reforma_aplicada

        El trigger tg_vigencia_normativa se encargará de:
        - pasar la versión anterior a Histórica
        - crear la nueva versión Vigente
        */

        console.log("Registrando reforma:", datos);
    }

    // Obtener versión vigente
    obtenerElementoVigente(id_reglamento, numero_etiqueta) {

        /*
        Aquí se consultará:
        obtener_elemento_vigente(...)
        */

        console.log(
            "Consultando versión vigente:",
            id_reglamento,
            numero_etiqueta
        );
    }

    // Consultar historial de versiones
    obtenerHistorialVersiones(id_reglamento, numero_etiqueta) {

        /*
        Consulta histórica de elemento_normativo
        */

        console.log(
            "Consultando historial:",
            id_reglamento,
            numero_etiqueta
        );
    }
}

module.exports = Reforma;
