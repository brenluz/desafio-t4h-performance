#!/usr/bin/env bash
# Pré-teste do experimento 12 (P13: consultas paralelas num banco limitado a 1 CPU). Só leitura.
# 1) Quais consultas das rotas usam workers paralelos hoje (max_parallel_workers_per_gather = 2, padrão).
# 2) vendas-por-dia com 2 e com 0 workers, 7 execuções de cada, banco ocioso e cache quente.
#    A configuração é mudada só na sessão (SET), não no servidor.
set -euo pipefail
cd "$(dirname "$0")/../.."

VENDAS="SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia, count(DISTINCT p.id) AS pedidos, sum(i.quantidade) AS itens, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '2024-06-01' AND '2024-06-07' AND p.status <> 'cancelado' GROUP BY p.criado_em::date ORDER BY p.criado_em::date"

docker compose exec -T banco psql -U loja -d loja -X -v ON_ERROR_STOP=1 <<SQL
SHOW max_parallel_workers_per_gather;
\echo '##### quais consultas das rotas planejam workers (padrao)'
\echo '--- cliente'
EXPLAIN SELECT * FROM clientes WHERE id = 42;
\echo '--- cliente-por-email'
EXPLAIN SELECT * FROM clientes WHERE lower(email) = lower('cliente42@exemplo.com') ORDER BY id;
\echo '--- pedidos-do-cliente'
EXPLAIN SELECT p.id, p.status, p.criado_em, i.produto_id, pr.nome AS produto_nome, i.quantidade, i.preco_unitario_centavos FROM pedidos p LEFT JOIN itens_pedido i ON i.pedido_id = p.id LEFT JOIN produtos pr ON pr.id = i.produto_id WHERE p.cliente_id = 42 ORDER BY p.criado_em DESC, p.id DESC, i.id;
\echo '--- pedidos-por-status (contagem)'
EXPLAIN SELECT coalesce((SELECT total FROM contagem_pedidos_status WHERE status = 'pago'), 0) AS total;
\echo '--- pedidos-por-status (pagina 1000 de pago)'
EXPLAIN SELECT p.* FROM (SELECT id FROM pedidos WHERE status = 'pago' ORDER BY criado_em DESC, id DESC LIMIT 20 OFFSET 19980) s JOIN pedidos p ON p.id = s.id ORDER BY p.criado_em DESC, p.id DESC;
\echo '--- busca-produtos'
EXPLAIN SELECT * FROM produtos WHERE nome ILIKE '%' || 'ergo' || '%' ORDER BY nome, id LIMIT 20;
\echo '--- top-produtos'
EXPLAIN SELECT pr.id, pr.nome, pr.categoria, r.unidades, r.receita_centavos FROM resumo_vendas_produto r JOIN produtos pr ON pr.id = r.produto_id ORDER BY r.receita_centavos DESC, r.produto_id LIMIT 10;
\echo '--- vendas-por-dia'
EXPLAIN $VENDAS;

\echo '##### vendas-por-dia: aquecendo o cache'
SELECT count(*) FROM ($VENDAS) x;
SELECT count(*) FROM ($VENDAS) x;

\echo '##### COM 2 workers (padrao), 7 execucoes'
SET max_parallel_workers_per_gather = 2;
EXPLAIN (ANALYZE, BUFFERS) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;

\echo '##### SEM workers (0), 7 execucoes'
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;
EXPLAIN (ANALYZE) $VENDAS;
SQL
