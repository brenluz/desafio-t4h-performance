CREATE INDEX pedidos_criado_em_dia_idx ON pedidos ((criado_em::date));
ANALYZE;