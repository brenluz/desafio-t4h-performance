#!/usr/bin/env bash
# Diagnóstico 03: onde o banco gasta tempo sob carga depois do experimento 05.
# Mesmo método do diagnostico/02-pg-stat-statements/coletar.sh (reusa o compose de lá);
# salva nesta pasta para não sobrescrever o ranking do Diagnóstico 02.
# No fim, colhe EXPLAIN (ANALYZE, BUFFERS) das consultas que restaram pesadas,
# com o cache ainda quente da carga, e devolve o banco à configuração normal.
set -euo pipefail
cd "$(dirname "$0")/../.."

PASTA=diagnostico/07-ranking-apos-05
DIAG=(docker compose -f docker-compose.yml -f diagnostico/02-pg-stat-statements/docker-compose.pg-stat.yml)
psql() { docker compose exec -T banco psql -U loja -d loja -X "$@"; }

echo "Reiniciando o banco com pg_stat_statements..."
"${DIAG[@]}" up -d
psql -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;" >/dev/null

echo "Aquecendo por 15s..."
docker compose run --rm -e VUS=5 -e DURACAO=15s -e SEMENTE=43 carga run --quiet --no-summary /carga/teste-carga.js >/dev/null
psql -c "SELECT pg_stat_statements_reset();" >/dev/null

echo "Carga: 20 usuários por 60s, semente 42..."
docker compose run --rm -e VUS=20 -e DURACAO=60s -e SEMENTE=42 carga run --quiet /carga/teste-carga.js > "$PASTA/carga.txt"

psql -c "
SELECT calls,
       round(total_exec_time) AS total_ms,
       round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 1) AS pct_tempo,
       round(mean_exec_time::numeric, 1) AS media_ms,
       rows,
       shared_blks_hit, shared_blks_read, temp_blks_written,
       left(regexp_replace(query, '\s+', ' ', 'g'), 140) AS consulta
  FROM pg_stat_statements
 WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'loja')
 ORDER BY total_exec_time DESC
 LIMIT 15;" > "$PASTA/ranking.txt"

echo "EXPLAIN das consultas restantes (cache quente da carga)..."
{
  echo "##### top-produtos (limite 10)"
  psql -c "EXPLAIN (ANALYZE, BUFFERS) SELECT pr.id, pr.nome, pr.categoria, sum(i.quantidade) AS unidades, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM itens_pedido i JOIN pedidos p ON p.id = i.pedido_id JOIN produtos pr ON pr.id = i.produto_id WHERE p.status <> 'cancelado' GROUP BY pr.id, pr.nome, pr.categoria ORDER BY receita_centavos DESC, pr.id LIMIT 10"
  echo "##### count por status (pago)"
  psql -c "EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) AS total FROM pedidos WHERE status = 'pago'"
  echo "##### pagina por status (pago, OFFSET 19980)"
  psql -c "EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM pedidos WHERE status = 'pago' ORDER BY criado_em DESC, id DESC LIMIT 20 OFFSET 19980"
  echo "##### cliente por email"
  psql -c "EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM clientes WHERE lower(email) = lower('cliente42@exemplo.com') ORDER BY id"
  echo "##### busca produtos (cadeira)"
  psql -c "EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM produtos WHERE nome ILIKE '%' || 'cadeira' || '%' ORDER BY nome, id LIMIT 20"
  echo "##### vendas-por-dia (7 dias, com o indice do experimento 05)"
  psql -c "EXPLAIN (ANALYZE, BUFFERS) SELECT p.id AS pedido_id, p.criado_em, p.observacoes, i.quantidade, i.preco_unitario_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '2024-06-01' AND '2024-06-07' AND p.status <> 'cancelado'"
} > "$PASTA/consultas-ociosas.txt"

echo "Desligando o pg_stat_statements e voltando o banco ao normal..."
psql -c "DROP EXTENSION pg_stat_statements;" >/dev/null
docker compose up -d

cat "$PASTA/ranking.txt"
