const { Pool } = require('pg');

const config = {
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.DB_USER || 'loja',
  database: process.env.DB_NAME || 'loja',
};

// Conexões reaproveitadas entre consultas, em vez de abrir e fechar uma por consulta.
// max padrão = 20: o mesmo número de consultas simultâneas que a carga já gera (20 usuários virtuais),
// para medir só o custo de abrir conexões, sem mudar a concorrência no banco (experimento 04).
// DB_POOL_MAX troca o tamanho sem mudar o código (experimento 17).
const pool = new Pool({ ...config, max: Number(process.env.DB_POOL_MAX || 20) });

// Uma conexão ociosa pode cair (ex.: o banco reiniciou). O pool já a descarta;
// sem este ouvinte o erro derrubaria o processo.
pool.on('error', (erro) => {
  console.error('erro em conexão ociosa do pool', erro.message);
});

async function consultar(sql, parametros = []) {
  const resultado = await pool.query(sql, parametros);
  return resultado.rows;
}

module.exports = { consultar };