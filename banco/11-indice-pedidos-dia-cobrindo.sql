-- Índice que cobre a parte de pedidos de vendas-por-dia: com id, status e criado_em dentro do índice,
-- a consulta faz Index Only Scan em pedidos (além de em itens_pedido) e não visita nenhuma tabela.
-- criado_em precisa estar incluído: o planejador só considera Index Only Scan quando todas as colunas usadas
-- estão no índice, mesmo que a consulta só use criado_em dentro de criado_em::date (documentação, seção 11.9).
-- Substitui o índice de expressão do experimento 05 (mesma chave).
CREATE INDEX pedidos_dia_inclui_idx ON pedidos ((criado_em::date)) INCLUDE (criado_em, id, status);

DROP INDEX pedidos_criado_em_dia_idx;

ANALYZE;
