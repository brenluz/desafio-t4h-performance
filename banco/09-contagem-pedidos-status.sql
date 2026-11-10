-- Contagem de pedidos por status, pré-calculada para o total da paginação de /pedidos.
-- Numa loja real precisaria de REFRESH MATERIALIZED VIEW CONCURRENTLY periódico;
-- o índice único em status é o que o CONCURRENTLY exige.
CREATE MATERIALIZED VIEW contagem_pedidos_status AS
SELECT status, count(*) AS total
  FROM pedidos
 GROUP BY status;

CREATE UNIQUE INDEX contagem_pedidos_status_status_idx ON contagem_pedidos_status (status);

ANALYZE;
