// db.js
const mysql = require('mysql2');
require('dotenv').config();

// Extraer la URL y configurar SSL manualmente
const databaseUrl = process.env.DATABASE_URL;

// Configuración específica para TiDB Cloud
const pool = mysql.createPool({
    uri: databaseUrl,
    ssl: {
        minVersion: 'TLSv1.2',
        rejectUnauthorized: true
    },
    enableKeepAlive: true,
    keepAliveInitialDelay: 10000
});

// Exportamos la promesa de la conexión
module.exports = pool.promise();