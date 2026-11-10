#!/usr/bin/env bash
# Pré-teste do experimento 10 (índice GIN com pg_trgm para a busca ILIKE '%termo%').
# Usa PREPARE/EXECUTE com plan_cache_mode = force_custom_plan, como a API (consultas sem nome,
# planejadas a cada chamada com o valor real), e o mesmo '%' || $1 || '%' da rota.
# Extensão e índice são criados dentro de uma transação com ROLLBACK: nada fica no banco.
set -euo pipefail
cd "$(dirname "$0")/../.."

# Termos da carga (carga/teste-carga.js) e do contrato (contrato/verificar.js, respostas 200).
TERMOS=(cadeira mesa lumin teclado monitor ergo "sem fio" portatil "modelo 12" slim reforcada webcam ERGO inexistente)

bloco_explain() {
  for t in "${TERMOS[@]}"; do
    echo "\\echo '##### $1: $t'"
    echo "EXPLAIN (ANALYZE, BUFFERS) EXECUTE busca('$t');"
  done
}

docker compose exec -T banco psql -U loja -d loja -X -v ON_ERROR_STOP=1 <<SQL
SET plan_cache_mode = force_custom_plan;
PREPARE busca(text) AS SELECT * FROM produtos WHERE nome ILIKE '%' || \$1 || '%' ORDER BY nome, id LIMIT 20;

\echo '##### produtos que casam com cada termo (tamanho do resultado antes do LIMIT)'
SELECT t AS termo, (SELECT count(*) FROM produtos WHERE nome ILIKE '%' || t || '%') AS casam
  FROM unnest(ARRAY['cadeira','mesa','lumin','teclado','monitor','ergo','sem fio','portatil','modelo 12','slim','reforcada','webcam','ERGO','inexistente']) AS t;

$(bloco_explain ATUAL)

BEGIN;
CREATE EXTENSION pg_trgm;
CREATE INDEX produtos_nome_trgm_idx ON produtos USING gin (nome gin_trgm_ops);
ANALYZE produtos;
\echo '##### tamanho do indice'
SELECT pg_size_pretty(pg_relation_size('produtos_nome_trgm_idx'));

$(bloco_explain COM_INDICE)

\echo '##### equivalencia: resultado (20 linhas, em ordem) com e sem o indice, por termo'
CREATE TEMP TABLE com_indice AS
  SELECT t AS termo, r.* FROM unnest(ARRAY['cadeira','mesa','lumin','teclado','monitor','ergo','sem fio','portatil','modelo 12','slim','reforcada','webcam','ERGO','inexistente']) AS t
  CROSS JOIN LATERAL (SELECT row_number() OVER () AS pos, x.* FROM (SELECT * FROM produtos WHERE nome ILIKE '%' || t || '%' ORDER BY nome, id LIMIT 20) x) r;
SET LOCAL enable_bitmapscan = off;
SET LOCAL enable_indexscan = off;
CREATE TEMP TABLE sem_indice AS
  SELECT t AS termo, r.* FROM unnest(ARRAY['cadeira','mesa','lumin','teclado','monitor','ergo','sem fio','portatil','modelo 12','slim','reforcada','webcam','ERGO','inexistente']) AS t
  CROSS JOIN LATERAL (SELECT row_number() OVER () AS pos, x.* FROM (SELECT * FROM produtos WHERE nome ILIKE '%' || t || '%' ORDER BY nome, id LIMIT 20) x) r;
SELECT (SELECT count(*) FROM com_indice) AS linhas_com, (SELECT count(*) FROM sem_indice) AS linhas_sem,
       (SELECT count(*) FROM (TABLE com_indice EXCEPT ALL TABLE sem_indice) d) +
       (SELECT count(*) FROM (TABLE sem_indice EXCEPT ALL TABLE com_indice) d) AS linhas_diferentes;
ROLLBACK;

\echo '##### confere que nada ficou (esperado 0 e 0)'
SELECT count(*) AS indices FROM pg_indexes WHERE indexname = 'produtos_nome_trgm_idx';
SELECT count(*) AS extensoes FROM pg_extension WHERE extname = 'pg_trgm';
SQL
