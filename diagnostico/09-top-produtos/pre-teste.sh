#!/usr/bin/env bash
# Pré-teste do experimento 07 (top-produtos com visão materializada).
# Tudo dentro de uma transação com ROLLBACK: nada fica no banco.
# 1) Plano e tempo da consulta atual.
# 2) Tempo para construir a visão materializada (custo de cada REFRESH).
# 3) Prova de equivalência: todas as linhas (não só as 50 primeiras) da consulta atual
#    e da nova consulta são idênticas, na mesma ordem.
# 4) Plano e tempo da nova consulta.
set -euo pipefail
cd "$(dirname "$0")/../.."

ATUAL="SELECT pr.id, pr.nome, pr.categoria, sum(i.quantidade) AS unidades, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM itens_pedido i JOIN pedidos p ON p.id = i.pedido_id JOIN produtos pr ON pr.id = i.produto_id WHERE p.status <> 'cancelado' GROUP BY pr.id, pr.nome, pr.categoria ORDER BY receita_centavos DESC, pr.id"
NOVA="SELECT pr.id, pr.nome, pr.categoria, r.unidades, r.receita_centavos FROM resumo_vendas_produto r JOIN produtos pr ON pr.id = r.produto_id ORDER BY r.receita_centavos DESC, r.produto_id"

docker compose exec -T banco psql -U loja -d loja -X -v ON_ERROR_STOP=1 <<SQL
\timing on
\echo '##### ATUAL (limite 10)'
EXPLAIN (ANALYZE, BUFFERS) $ATUAL LIMIT 10;

BEGIN;
\echo '##### construcao da visao materializada (custo de um REFRESH completo)'
CREATE MATERIALIZED VIEW resumo_vendas_produto AS
SELECT i.produto_id,
       sum(i.quantidade) AS unidades,
       sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos
  FROM itens_pedido i
  JOIN pedidos p ON p.id = i.pedido_id
 WHERE p.status <> 'cancelado'
 GROUP BY i.produto_id;
CREATE UNIQUE INDEX resumo_vendas_produto_produto_id_idx ON resumo_vendas_produto (produto_id);
CREATE INDEX resumo_vendas_produto_receita_idx ON resumo_vendas_produto (receita_centavos DESC, produto_id);
ANALYZE resumo_vendas_produto;

\echo '##### equivalencia: linhas totais de cada lado'
SELECT (SELECT count(*) FROM ($ATUAL) a) AS linhas_atual, (SELECT count(*) FROM ($NOVA) n) AS linhas_nova;

\echo '##### equivalencia: linhas diferentes, comparando posicao a posicao (esperado 0)'
SELECT count(*) AS posicoes_diferentes
  FROM (SELECT row_number() OVER () AS pos, a.* FROM ($ATUAL) a) a
  FULL JOIN (SELECT row_number() OVER () AS pos, n.* FROM ($NOVA) n) n USING (pos)
 WHERE a.id IS DISTINCT FROM n.id
    OR a.nome IS DISTINCT FROM n.nome
    OR a.categoria IS DISTINCT FROM n.categoria
    OR a.unidades IS DISTINCT FROM n.unidades
    OR a.receita_centavos IS DISTINCT FROM n.receita_centavos;

\echo '##### NOVA (limite 10)'
EXPLAIN (ANALYZE, BUFFERS) $NOVA LIMIT 10;
\echo '##### NOVA (limite 50)'
EXPLAIN (ANALYZE, BUFFERS) $NOVA LIMIT 50;

\echo '##### tamanho da visao e dos indices'
SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) FROM pg_class WHERE relname LIKE 'resumo_vendas_produto%' ORDER BY 1;
ROLLBACK;

\echo '##### confere que nada ficou (esperado 0)'
SELECT count(*) FROM pg_class WHERE relname LIKE 'resumo_vendas_produto%';
SQL
