-- Índice que cobre as colunas lidas por vendas-por-dia em itens_pedido.
-- Com quantidade e preço dentro do índice, a consulta faz Index Only Scan e não visita a tabela.
-- Substitui o índice simples por pedido_id do experimento 01 (mesma primeira coluna; manter os dois só gastaria espaço).
CREATE INDEX itens_pedido_pedido_id_inclui_idx ON itens_pedido (pedido_id) INCLUDE (quantidade, preco_unitario_centavos);

DROP INDEX itens_pedido_pedido_id_idx;

ANALYZE;
