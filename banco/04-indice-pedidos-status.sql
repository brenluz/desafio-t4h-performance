CREATE INDEX pedidos_status_criado_em_id_idx ON pedidos (status, criado_em DESC, id DESC);
ANALYZE;