#!/usr/bin/env bash
# Read-only diagnosis of the original app. Writes nothing to the repo.
cd ~/meu-desafio
q() { docker compose exec -T banco psql -U loja -d loja -X -c "$1"; }

echo "##### indexes"
q "SELECT tablename, indexname, indexdef FROM pg_indexes WHERE schemaname='public' ORDER BY 1,2;"
echo "##### table sizes"
q "SELECT relname, n_live_tup, pg_size_pretty(pg_total_relation_size(relid)) total FROM pg_stat_user_tables ORDER BY pg_total_relation_size(relid) DESC;"
echo "##### avg observacoes size"
q "SELECT avg(length(observacoes))::int avg_len, max(length(observacoes)) max_len FROM pedidos;"
echo "##### settings"
q "SELECT name, setting, unit FROM pg_settings WHERE name IN ('shared_buffers','work_mem','effective_cache_size','max_connections','random_page_cost','max_parallel_workers_per_gather','jit','shared_preload_libraries');"
echo "##### status distribution"
q "SELECT status, count(*) FROM pedidos GROUP BY 1 ORDER BY 2 DESC;"
echo "##### pedidos per cliente"
q "SELECT avg(c)::numeric(6,1) avg_pedidos, max(c) FROM (SELECT count(*) c FROM pedidos GROUP BY cliente_id) t;"

ex() { echo "##### EXPLAIN: $1"; q "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) $2"; }
ex "cliente por id"       "SELECT * FROM clientes WHERE id = 42"
ex "cliente por email"    "SELECT * FROM clientes WHERE lower(email) = lower('cliente42@exemplo.com') ORDER BY id"
ex "pedidos do cliente"   "SELECT * FROM pedidos WHERE cliente_id = 42 ORDER BY criado_em DESC, id DESC"
ex "itens de um pedido"   "SELECT * FROM itens_pedido WHERE pedido_id = 1000 ORDER BY id"
ex "count por status"     "SELECT count(*) FROM pedidos WHERE status = 'pago'"
ex "pagina por status"    "SELECT * FROM pedidos WHERE status = 'pago' ORDER BY criado_em DESC, id DESC LIMIT 20 OFFSET 19980"
ex "busca produtos"       "SELECT * FROM produtos WHERE nome ILIKE '%' || 'cadeira' || '%' ORDER BY nome, id LIMIT 20"
ex "vendas por dia"       "SELECT p.id, p.criado_em, p.observacoes, i.quantidade, i.preco_unitario_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '2024-03-01' AND '2024-03-07' AND p.status <> 'cancelado'"
ex "top produtos"         "SELECT pr.id, pr.nome, pr.categoria, sum(i.quantidade) u, sum(i.quantidade * i.preco_unitario_centavos) r FROM itens_pedido i JOIN pedidos p ON p.id = i.pedido_id JOIN produtos pr ON pr.id = i.produto_id WHERE p.status <> 'cancelado' GROUP BY pr.id, pr.nome, pr.categoria ORDER BY r DESC, pr.id LIMIT 10"

echo "##### queries per /clientes/42/pedidos request (count of pedidos + itens)"
q "SELECT (SELECT count(*) FROM pedidos WHERE cliente_id=42) pedidos, (SELECT count(*) FROM itens_pedido i JOIN pedidos p ON p.id=i.pedido_id WHERE p.cliente_id=42) itens;"

echo "##### connection cost: 50 x new connection+query vs 50 queries on one connection"
docker compose exec -T banco bash -c 'time (for i in $(seq 50); do psql -U loja -d loja -h 127.0.0.1 -Atqc "select 1" >/dev/null; done)' 2>&1 | grep real
docker compose exec -T banco bash -c 'time (for i in $(seq 50); do echo "select 1;"; done | psql -U loja -d loja -h 127.0.0.1 -Atq >/dev/null)' 2>&1 | grep real

echo "##### API log volume"
docker compose logs api --no-log-prefix 2>/dev/null | wc -lc
docker compose logs api --no-log-prefix 2>/dev/null | awk '{ if (length($0) > m) m = length($0) } END { print "longest log line chars:", m }'
