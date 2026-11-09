# Pré-teste: plano da consulta de vendas-por-dia hoje e com dois índices candidatos.
# Cada índice é criado dentro de uma transação com ROLLBACK: nada fica no banco.
cd ~/meu-desafio
q() { docker compose exec -T banco psql -U loja -d loja -X "$@"; }

echo "##### distribuicao"
q -c "SELECT min(criado_em), max(criado_em), count(*) FROM pedidos;"
q -c "SELECT round(avg(c)) media_pedidos_dia, min(c), max(c) FROM (SELECT criado_em::date d, count(*) c FROM pedidos GROUP BY 1) t;"

Q="SELECT p.id AS pedido_id, p.criado_em, p.observacoes, i.quantidade, i.preco_unitario_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '2024-06-01' AND '2024-06-07' AND p.status <> 'cancelado'"
QR="SELECT p.id AS pedido_id, p.criado_em, p.observacoes, i.quantidade, i.preco_unitario_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em >= '2024-06-01' AND p.criado_em < date '2024-06-07' + 1 AND p.status <> 'cancelado'"

echo "##### ATUAL (sem indice novo)"
q -c "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) $Q"

echo "##### A: indice de expressao em (criado_em::date), dentro de transacao com ROLLBACK"
q <<SQL
BEGIN;
CREATE INDEX tmp_pedidos_dia ON pedidos ((criado_em::date));
ANALYZE pedidos;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) $Q;
ROLLBACK;
SQL

echo "##### B: consulta reescrita como intervalo + indice em criado_em, com ROLLBACK"
q <<SQL
BEGIN;
CREATE INDEX tmp_pedidos_criado ON pedidos (criado_em);
ANALYZE pedidos;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) $QR;
ROLLBACK;
SQL

echo "##### confere que nada ficou"
q -Atc "SELECT indexname FROM pg_indexes WHERE tablename='pedidos' ORDER BY 1"
