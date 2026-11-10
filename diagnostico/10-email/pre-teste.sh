#!/usr/bin/env bash
# Pré-teste do experimento 08 (índice de expressão em lower(email)).
# O índice é criado dentro de uma transação com ROLLBACK: nada fica no banco.
# Testa um e-mail que existe, um com maiúsculas (o dado guarda 'Cliente3@Exemplo.com' para id múltiplo de 3)
# e um que não existe, como nos casos do contrato.
set -euo pipefail
cd "$(dirname "$0")/../.."

Q() { echo "SELECT * FROM clientes WHERE lower(email) = lower('$1') ORDER BY id"; }

docker compose exec -T banco psql -U loja -d loja -X -v ON_ERROR_STOP=1 <<SQL
\echo '##### ATUAL: cliente42@exemplo.com'
EXPLAIN (ANALYZE, BUFFERS) $(Q cliente42@exemplo.com);
\echo '##### ATUAL: CLIENTE3@EXEMPLO.COM'
EXPLAIN (ANALYZE, BUFFERS) $(Q CLIENTE3@EXEMPLO.COM);

BEGIN;
CREATE INDEX clientes_lower_email_idx ON clientes (lower(email));
ANALYZE clientes;
\echo '##### COM INDICE: cliente42@exemplo.com'
EXPLAIN (ANALYZE, BUFFERS) $(Q cliente42@exemplo.com);
\echo '##### COM INDICE: CLIENTE3@EXEMPLO.COM'
EXPLAIN (ANALYZE, BUFFERS) $(Q CLIENTE3@EXEMPLO.COM);
\echo '##### COM INDICE: ninguem@exemplo.com'
EXPLAIN (ANALYZE, BUFFERS) $(Q ninguem@exemplo.com);
\echo '##### tamanho do indice'
SELECT pg_size_pretty(pg_relation_size('clientes_lower_email_idx'));
\echo '##### e-mails duplicados em lower(email)? (define se o indice poderia ser UNIQUE)'
SELECT count(*) AS emails_repetidos FROM (SELECT lower(email) FROM clientes GROUP BY 1 HAVING count(*) > 1) t;
ROLLBACK;

\echo '##### confere que nada ficou (esperado 0)'
SELECT count(*) FROM pg_indexes WHERE indexname = 'clientes_lower_email_idx';
SQL
