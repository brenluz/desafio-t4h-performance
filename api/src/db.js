const { Pool } = require('pg');

const config = {
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.DB_USER || 'loja',
  database: process.env.DB_NAME || 'loja',
};

// Conexões reaproveitadas entre consultas, em vez de abrir e fechar uma por consulta.
// max = 3 (experimento 17): com 1 CPU no banco, poucas consultas ao mesmo tempo gastam menos CPU por requisição;
// as demais esperam aqui, na fila do pool. 3 rendeu ~34% mais req/s que 20 (o tamanho do experimento 04), com a
// mesma vazão de 2 e mediana menor; com 1, a CPU do banco ficava ociosa. DB_POOL_MAX troca o tamanho sem mudar o código.
const pool = new Pool({ ...config, max: Number(process.env.DB_POOL_MAX || 3) });

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