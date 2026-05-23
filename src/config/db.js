const { Pool } = require('pg');
require('dotenv').config();

// Verificar que las variables existen
console.log('🔍 Verificando variables de entorno:');
console.log('PG_HOST:', process.env.PG_HOST ? '✅ DEFINIDO' : '❌ FALTA');
console.log('PG_PORT:', process.env.PG_PORT ? '✅ DEFINIDO' : '❌ FALTA');
console.log('PG_USER:', process.env.PG_USER ? '✅ DEFINIDO' : '❌ FALTA');
console.log('PG_DATABASE:', process.env.PG_DATABASE ? '✅ DEFINIDO' : '❌ FALTA');
console.log('PG_PASSWORD:', process.env.PG_PASSWORD ? '✅ DEFINIDO (oculto)' : '❌ FALTA');

// Crear el pool de conexiones
const pool = new Pool({
  host: process.env.PG_HOST,
  port: process.env.PG_PORT || 5432,
  user: process.env.PG_USER,
  password: process.env.PG_PASSWORD,
  database: process.env.PG_DATABASE,
  ssl: {
    rejectUnauthorized: false
  },
  // Timeouts para evitar errores
  connectionTimeoutMillis: 10000,
  idleTimeoutMillis: 30000,
});

// Probar la conexión al iniciar
pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ ERROR de conexión a Supabase:');
    console.error('   Mensaje:', err.message);
    console.error('   Código:', err.code);
    console.error('   Detalles completos:', err);
  } else {
    console.log('✅ Conectado a Supabase (PostgreSQL) correctamente');
    release();
  }
});

// Manejar errores del pool
pool.on('error', (err) => {
  console.error('❌ Error inesperado en el pool de conexiones:', err.message);
});

module.exports = pool;