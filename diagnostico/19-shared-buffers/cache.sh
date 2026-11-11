#!/usr/bin/env bash
# Diagnóstico de cache para os experimentos 14 e 15 (shared_buffers).
# Zera as estatísticas, roda uma carga igual à do medir.sh (20 VUs, 60 s, semente 42) e lê:
#   - shared_buffers em uso e acerto de cache do banco inteiro;
#   - páginas lidas de fora do shared_buffers por tabela e por índice;
#   - composição da memória do container do banco (cgroup), para o custo de memória.
# Não muda configuração nem dados. Uso: diagnostico/19-shared-buffers/cache.sh <arquivo-de-saida>
set -euo pipefail
cd "$(dirname "$0")/../.."
SAIDA="$1"
psql() { docker compose exec -T banco psql -U loja -d loja -X "$@"; }

docker compose run --rm -e VUS=5 -e DURACAO=15s -e SEMENTE=43 carga run --quiet --no-summary /carga/teste-carga.js >/dev/null
psql -c "SELECT pg_stat_reset();" >/dev/null
docker compose run --rm -e VUS=20 -e DURACAO=60s -e SEMENTE=42 carga run --quiet /carga/teste-carga.js > "${SAIDA%.txt}-carga.txt"

{
  echo "commit: $(git rev-parse --short HEAD)"
  echo "### configuracao"
  psql -Atc "SELECT name || ' = ' || current_setting(name) FROM unnest(ARRAY['shared_buffers','max_parallel_workers_per_gather','effective_cache_size']) AS name"
  echo "### acerto de cache do banco durante a carga"
  psql -c "SELECT blks_hit, blks_read, round(100.0 * blks_hit / nullif(blks_hit + blks_read, 0), 2) AS pct_acerto FROM pg_stat_database WHERE datname = 'loja'"
  echo "### paginas lidas de fora do shared_buffers, por tabela (heap) e por indice"
  psql -c "SELECT relname, heap_blks_read, heap_blks_hit, idx_blks_read, idx_blks_hit FROM pg_statio_user_tables ORDER BY heap_blks_read + idx_blks_read DESC"
  psql -c "SELECT indexrelname, idx_blks_read, idx_blks_hit, pg_size_pretty(pg_relation_size(indexrelid)) AS tamanho FROM pg_statio_user_indexes WHERE idx_blks_read + idx_blks_hit > 0 ORDER BY idx_blks_read DESC"
  echo "### memoria do container do banco (cgroup) logo depois da carga"
  docker compose exec -T banco sh -c 'echo "memory.max: $(cat /sys/fs/cgroup/memory.max)"; echo "memory.current: $(cat /sys/fs/cgroup/memory.current)"; echo "memory.peak: $(cat /sys/fs/cgroup/memory.peak)"; grep -E "^(anon|file|shmem|active_file|inactive_file) " /sys/fs/cgroup/memory.stat'
} > "$SAIDA"
grep -E "Requisições/s" "${SAIDA%.txt}-carga.txt"
cat "$SAIDA"
