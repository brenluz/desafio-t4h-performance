#!/usr/bin/env bash
# Pré-teste do experimento 09 (vendas-por-dia agregada no SQL). Só leitura.
# 1) Equivalência byte a byte do JSON (equivalencia.js, dentro do container da API).
# 2) Plano e tempo da consulta atual e da nova, para uma janela de 7 dias.
set -euo pipefail
cd "$(dirname "$0")/../.."
P=diagnostico/12-vendas-sql

echo "##### equivalencia (JSON atual x novo)"
docker compose cp "$P/equivalencia.js" api:/tmp/equivalencia.js >/dev/null
docker compose exec -T -e NODE_PATH=/app/node_modules api node /tmp/equivalencia.js

q() { docker compose exec -T banco psql -U loja -d loja -X -c "$1"; }
echo "##### ATUAL (2024-06-01..2024-06-07)"
q "EXPLAIN (ANALYZE, BUFFERS) SELECT p.id AS pedido_id, p.criado_em, p.observacoes, i.quantidade, i.preco_unitario_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '2024-06-01' AND '2024-06-07' AND p.status <> 'cancelado'"
echo "##### NOVA (2024-06-01..2024-06-07)"
q "EXPLAIN (ANALYZE, BUFFERS) SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia, count(DISTINCT p.id) AS pedidos, sum(i.quantidade) AS itens, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '2024-06-01' AND '2024-06-07' AND p.status <> 'cancelado' GROUP BY p.criado_em::date ORDER BY p.criado_em::date"
