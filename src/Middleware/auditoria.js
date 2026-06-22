
// Middleware para capturar IP del cliente

function capturarIP(req, res, next) {
    // Obtener IP real (considerando proxies)
    const ip = req.headers['x-forwarded-for'] || 
               req.connection.remoteAddress || 
               req.socket.remoteAddress || 
               req.ip;
    
    // Guardar IP en la request para usarla después
    req.clienteIP = ip;
    
    next();
}

// Función para registrar en bitácora
async function registrarEnBitacora(db, id_usuario, accion, tabla_afectada, detalle, ip) {
    try {
        await db.query(
            `INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle, ip_origen)
             VALUES (?, ?, ?, ?, ?)`,
            [id_usuario, accion, tabla_afectada, detalle, ip]
        );
    } catch (error) {
        console.error('Error registrando en bitácora:', error);
    }
}

module.exports = { capturarIP, registrarEnBitacora };