// Pré-teste do experimento 09: prova que agregar vendas-por-dia no SQL devolve exatamente o mesmo JSON
// que a agregação em JavaScript de hoje, para todas as janelas que a carga pode pedir e mais algumas.
// Só leitura. Roda dentro do container da API (mesmo Node, mesmo pg, TZ=UTC):
//   docker compose cp diagnostico/12-vendas-sql/equivalencia.js api:/tmp/equivalencia.js
//   docker compose exec -T -e NODE_PATH=/app/node_modules api node /tmp/equivalencia.js

const { Pool } = require('pg');

const pool = new Pool({ host: process.env.DB_HOST, user: process.env.DB_USER, database: process.env.DB_NAME, max: 4 });

const SQL_ATUAL = `SELECT p.id AS pedido_id, p.criado_em, p.observacoes, i.quantidade, i.preco_unitario_centavos
       FROM pedidos p
       JOIN itens_pedido i ON i.pedido_id = p.id
      WHERE p.criado_em::date BETWEEN $1 AND $2
        AND p.status <> 'cancelado'`;

const SQL_NOVA = `SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia,
            count(DISTINCT p.id) AS pedidos,
            sum(i.quantidade) AS itens,
            sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos
       FROM pedidos p
       JOIN itens_pedido i ON i.pedido_id = p.id
      WHERE p.criado_em::date BETWEEN $1 AND $2
        AND p.status <> 'cancelado'
      GROUP BY p.criado_em::date
      ORDER BY p.criado_em::date`;

// Cópia fiel da agregação de api/src/rotas.js (versão atual).
function respostaAtual(linhas) {
  const porDia = new Map();
  for (const linha of linhas) {
    const dia = linha.criado_em.toISOString().slice(0, 10);
    if (!porDia.has(dia)) porDia.set(dia, { pedidos: new Set(), itens: 0, receita: 0 });
    const acumulado = porDia.get(dia);
    acumulado.pedidos.add(linha.pedido_id);
    acumulado.itens += linha.quantidade;
    acumulado.receita += linha.quantidade * linha.preco_unitario_centavos;
  }
  return [...porDia.entries()]
    .sort(([a], [b]) => (a < b ? -1 : 1))
    .map(([dia, acumulado]) => ({
      dia,
      pedidos: acumulado.pedidos.size,
      itens: acumulado.itens,
      receita_centavos: acumulado.receita,
    }));
}

// Formatação proposta para a rota nova.
function respostaNova(linhas) {
  return linhas.map((linha) => ({
    dia: linha.dia,
    pedidos: Number(linha.pedidos),
    itens: Number(linha.itens),
    receita_centavos: Number(linha.receita_centavos),
  }));
}

function dia(deslocamento) {
  return new Date(Date.UTC(2024, 0, 1) + deslocamento * 86400000).toISOString().slice(0, 10);
}

async function main() {
  const janelas = [];
  // Todas as janelas da carga (carga/teste-carga.js: inicio sorteado em 0..724, fim = inicio + 6).
  for (let i = 0; i <= 724; i += 1) janelas.push([dia(i), dia(i + 6), 'carga']);
  // Janelas do contrato com resposta 200.
  janelas.push(['2024-01-01', '2024-01-07', 'contrato'], ['2024-02-27', '2024-03-02', 'contrato'],
    ['2025-12-25', '2025-12-31', 'contrato'], ['2023-12-30', '2024-01-02', 'contrato']);
  // Bordas: período de 31 dias, fora dos dados, último dia, ano bissexto.
  janelas.push(['2024-01-01', '2024-01-31', 'borda'], ['2025-12-01', '2025-12-31', 'borda'],
    ['2023-01-01', '2023-01-07', 'borda'], ['2026-01-01', '2026-01-07', 'borda'],
    ['2025-12-31', '2025-12-31', 'borda'], ['2024-02-29', '2024-02-29', 'borda']);

  let diferentes = 0;
  let linhasAtual = 0;
  let diasComparados = 0;
  for (const [inicio, fim, tipo] of janelas) {
    const atual = await pool.query(SQL_ATUAL, [inicio, fim]);
    const nova = await pool.query(SQL_NOVA, [inicio, fim]);
    linhasAtual += atual.rows.length;
    const a = JSON.stringify(respostaAtual(atual.rows));
    const n = JSON.stringify(respostaNova(nova.rows));
    diasComparados += nova.rows.length;
    if (a !== n) {
      diferentes += 1;
      console.log(`DIFERENTE ${tipo} ${inicio}..${fim}\n  atual: ${a.slice(0, 300)}\n  nova:  ${n.slice(0, 300)}`);
    }
  }
  console.log(`janelas comparadas: ${janelas.length}`);
  console.log(`dias comparados (linhas da nova consulta): ${diasComparados}`);
  console.log(`linhas que a consulta atual traria para a API: ${linhasAtual}`);
  console.log(`janelas com JSON diferente: ${diferentes}`);
  await pool.end();
}

main().catch((erro) => { console.error(erro); process.exit(1); });
