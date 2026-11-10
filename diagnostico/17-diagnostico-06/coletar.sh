#!/usr/bin/env bash
# Diagnóstico 06 (depois do experimento 12). Mesma carga do medir.sh. Mede:
#   1) throttling de CPU do banco e da API só na janela da carga;
#   2) ranking de consultas (pg_stat_statements);
#   3) uso de cada índice, varreduras sequenciais por tabela e acerto de cache, SÓ durante a carga
#      (estatísticas zeradas com pg_stat_reset logo antes);
#   4) perfil de CPU da API (node --prof) e volume de log por rota.
# Usa composes à parte com -f e devolve tudo ao normal no fim. Confere que o paralelismo continua desligado.
set -euo pipefail
cd "$(dirname "$0")/../.."

PASTA=diagnostico/17-diagnostico-06
DIAG=(docker compose -f docker-compose.yml
      -f "$PASTA/docker-compose.pg-stat.yml"
      -f diagnostico/11-diagnostico-04/docker-compose.api-prof.yml)
psql() { docker compose exec -T banco psql -U loja -d loja -X "$@"; }
cpustat() { docker compose exec -T "$1" sh -c "grep -E '^(usage_usec|nr_periods|nr_throttled|throttled_usec) ' /sys/fs/cgroup/cpu.stat"; }

echo "Subindo banco com pg_stat_statements (sem paralelismo) e API com profiler..."
"${DIAG[@]}" up -d
until curl -fsS http://127.0.0.1:3000/saude >/dev/null 2>&1; do sleep 1; done
psql -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;" >/dev/null
psql -Atc "SHOW max_parallel_workers_per_gather" > "$PASTA/config.txt"

echo "Aquecendo por 15s..."
docker compose run --rm -e VUS=5 -e DURACAO=15s -e SEMENTE=43 carga run --quiet --no-summary /carga/teste-carga.js >/dev/null
psql -c "SELECT pg_stat_statements_reset();" >/dev/null
psql -c "SELECT pg_stat_reset();" >/dev/null

{ echo "### banco antes"; cpustat banco; echo "### api antes"; cpustat api; } > "$PASTA/cpu-antes.txt"
echo "Carga: 20 usuários por 60s, semente 42..."
INICIO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
docker compose run --rm -e VUS=20 -e DURACAO=60s -e SEMENTE=42 carga run --quiet /carga/teste-carga.js > "$PASTA/carga.txt"
{ echo "### banco depois"; cpustat banco; echo "### api depois"; cpustat api; } > "$PASTA/cpu-depois.txt"

echo "Estatísticas de tabelas e índices durante a carga..."
{
  echo "### uso dos indices (idx_scan desde o pg_stat_reset, logo antes da carga)"
  psql -c "SELECT relname AS tabela, indexrelname AS indice, idx_scan, idx_tup_read, pg_size_pretty(pg_relation_size(indexrelid)) AS tamanho FROM pg_stat_user_indexes ORDER BY idx_scan DESC, relname"
  echo "### varreduras sequenciais e por indice, por tabela"
  psql -c "SELECT relname AS tabela, seq_scan, seq_tup_read, idx_scan, n_live_tup FROM pg_stat_user_tables ORDER BY seq_tup_read DESC"
  echo "### acerto de cache do banco durante a carga"
  psql -c "SELECT blks_hit, blks_read, round(100.0 * blks_hit / nullif(blks_hit + blks_read, 0), 2) AS pct_acerto, temp_files, temp_bytes, xact_commit, xact_rollback FROM pg_stat_database WHERE datname = 'loja'"
  echo "### conexoes"
  psql -Atc "SELECT coalesce(state, '?') || ' ' || count(*) FROM pg_stat_activity WHERE datname = 'loja' GROUP BY state ORDER BY 1"
} > "$PASTA/tabelas-indices.txt"

echo "Ranking do banco..."
psql -c "
SELECT calls,
       round(total_exec_time) AS total_ms,
       round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 1) AS pct_tempo,
       round(mean_exec_time::numeric, 2) AS media_ms,
       rows,
       shared_blks_hit, shared_blks_read, temp_blks_written,
       left(regexp_replace(query, '\s+', ' ', 'g'), 110) AS consulta
  FROM pg_stat_statements
 WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'loja')
 ORDER BY total_exec_time DESC
 LIMIT 12;" > "$PASTA/ranking.txt"

echo "Volume de log da API durante a carga..."
docker compose logs api --no-log-prefix --since "$INICIO" 2>/dev/null | awk '
  /"url":"\/relatorios\/vendas/  { r = "vendas-por-dia" }
  /"url":"\/relatorios\/top/     { r = "top-produtos" }
  /"url":"\/pedidos/             { r = "pedidos-por-status" }
  /"url":"\/produtos/            { r = "busca-produtos" }
  /"url":"\/clientes\?/          { r = "cliente-por-email" }
  /"url":"\/clientes\/[0-9]+"/   { r = "cliente" }
  /"url":"\/clientes\/[0-9]+\/pedidos/ { r = "pedidos-do-cliente" }
  { if (r == "") r = "outros"; linhas[r]++; bytes[r] += length($0) + 1; total += length($0) + 1; n++; r = "" }
  END {
    printf "%-20s %8s %12s %10s\n", "rota", "linhas", "bytes", "bytes/linha"
    for (k in linhas) printf "%-20s %8d %12d %10.0f\n", k, linhas[k], bytes[k], bytes[k] / linhas[k]
    printf "%-20s %8d %12d\n", "TOTAL", n, total
  }' > "$PASTA/log-api.txt"

echo "Processando o perfil de CPU da API..."
docker compose exec -T api node --prof-process /tmp/v8.log > "$PASTA/perfil-api.txt" 2>&1 || true

echo "Desligando pg_stat_statements e profiler; voltando ao normal..."
psql -c "DROP EXTENSION pg_stat_statements;" >/dev/null
docker compose up -d
until curl -fsS http://127.0.0.1:3000/saude >/dev/null 2>&1; do sleep 1; done
echo "paralelismo depois de voltar ao normal: $(docker compose exec -T banco psql -U loja -d loja -X -Atc 'SHOW max_parallel_workers_per_gather')" >> "$PASTA/config.txt"

cat "$PASTA/ranking.txt"
