#!/usr/bin/env bash
# Pré-teste do experimento 11 (contagem de pedidos por status pré-calculada numa visão materializada).
# Tudo dentro de uma transação com ROLLBACK: nada fica no banco.
# Usa PREPARE/EXECUTE com planos customizados, como as consultas sem nome da API.
set -euo pipefail
cd "$(dirname "$0")/../.."

docker compose exec -T banco psql -U loja -d loja -X -v ON_ERROR_STOP=1 <<'SQL'
\timing on
SET plan_cache_mode = force_custom_plan;
PREPARE atual(text) AS SELECT count(*) AS total FROM pedidos WHERE status = $1;
\echo '##### ATUAL'
EXPLAIN (ANALYZE, BUFFERS) EXECUTE atual('pago');
EXPLAIN (ANALYZE, BUFFERS) EXECUTE atual('pendente');

BEGIN;
\echo '##### construcao da visao (custo de um REFRESH completo)'
CREATE MATERIALIZED VIEW contagem_pedidos_status AS
SELECT status, count(*) AS total FROM pedidos GROUP BY status;
CREATE UNIQUE INDEX contagem_pedidos_status_status_idx ON contagem_pedidos_status (status);
ANALYZE contagem_pedidos_status;

PREPARE nova(text) AS SELECT coalesce((SELECT total FROM contagem_pedidos_status WHERE status = $1), 0) AS total;
\echo '##### NOVA'
EXPLAIN (ANALYZE, BUFFERS) EXECUTE nova('pago');
EXPLAIN (ANALYZE, BUFFERS) EXECUTE nova('pendente');

\echo '##### equivalencia: os 4 status validos e um status sem pedidos (esperado iguais em todas as linhas)'
SELECT s AS status,
       (SELECT count(*) FROM pedidos WHERE status = s) AS atual,
       coalesce((SELECT total FROM contagem_pedidos_status WHERE status = s), 0) AS nova,
       (SELECT count(*) FROM pedidos WHERE status = s) = coalesce((SELECT total FROM contagem_pedidos_status WHERE status = s), 0) AS iguais,
       pg_typeof((SELECT count(*) FROM pedidos WHERE status = s)) AS tipo_atual,
       pg_typeof(coalesce((SELECT total FROM contagem_pedidos_status WHERE status = s), 0)) AS tipo_nova
  FROM unnest(ARRAY['pago','entregue','cancelado','pendente','perdido']) AS s;

\echo '##### tamanho'
SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) FROM pg_class WHERE relname LIKE 'contagem_pedidos_status%' ORDER BY 1;
ROLLBACK;

\echo '##### confere que nada ficou (esperado 0)'
SELECT count(*) FROM pg_class WHERE relname LIKE 'contagem_pedidos_status%';
SQL
