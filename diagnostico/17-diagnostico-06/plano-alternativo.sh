#!/usr/bin/env bash
# Diagnóstico 06, complemento: custo real do plano com Seq Scan em itens_pedido (escolhido em 5 de 725 janelas)
# contra o plano de Nested Loop, na mesma janela (2024-05-03 a 2024-05-09). Só leitura; o plano alternativo é
# forçado só na sessão (SET enable_hashjoin = off). 3 execuções de cada, cache quente. Também mede a CPU do
# container em 20 execuções de cada plano.
set -euo pipefail
cd "$(dirname "$0")/../.."
Q="SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia, count(DISTINCT p.id) AS pedidos, sum(i.quantidade) AS itens, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '2024-05-03' AND '2024-05-09' AND p.status <> 'cancelado' GROUP BY p.criado_em::date ORDER BY p.criado_em::date"
uso() { docker compose exec -T banco sh -c "grep '^usage_usec ' /sys/fs/cgroup/cpu.stat | cut -d' ' -f2"; }

docker compose exec -T banco psql -U loja -d loja -X <<SQL
\echo '##### plano escolhido pelo planejador (Hash Join + Seq Scan em itens)'
EXPLAIN (ANALYZE, BUFFERS) $Q;
EXPLAIN (ANALYZE) $Q;
EXPLAIN (ANALYZE) $Q;
\echo '##### mesmo filtro com hash join desligado na sessao (Nested Loop)'
SET enable_hashjoin = off;
EXPLAIN (ANALYZE, BUFFERS) $Q;
EXPLAIN (ANALYZE) $Q;
EXPLAIN (ANALYZE) $Q;
SQL

for modo in on off; do
  antes=$(uso)
  { echo "SET enable_hashjoin = $modo;"; for _ in $(seq 20); do echo "$Q;"; done; } | docker compose exec -T banco psql -U loja -d loja -X -q -o /dev/null
  depois=$(uso)
  echo "enable_hashjoin=$modo execucoes=20 cpu_container_ms=$(( (depois - antes) / 1000 )) cpu_por_execucao_ms=$(( (depois - antes) / 20000 ))"
done
