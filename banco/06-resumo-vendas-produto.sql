-- Resumo de vendas por produto, pré-calculado para o relatório top-produtos.
-- Mesma agregação que a rota fazia a cada chamada (itens de pedidos não cancelados).
-- Numa loja real precisaria de REFRESH MATERIALIZED VIEW CONCURRENTLY periódico;
-- o índice único em produto_id é o que o CONCURRENTLY exige.
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

ANALYZE;
