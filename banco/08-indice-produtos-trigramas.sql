-- Índice de trigramas para a busca de produtos por trecho do nome (/produtos/busca).
-- A rota usa nome ILIKE '%termo%'; um B-tree não serve com % no começo, o GIN do pg_trgm serve.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX produtos_nome_trgm_idx ON produtos USING gin (nome gin_trgm_ops);

ANALYZE;
