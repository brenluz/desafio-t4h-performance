-- Índice de expressão para a busca por e-mail sem diferenciar maiúsculas (/clientes?email=).
-- A rota filtra por lower(email); um índice simples em email não serviria.
CREATE INDEX clientes_lower_email_idx ON clientes (lower(email));

ANALYZE;
