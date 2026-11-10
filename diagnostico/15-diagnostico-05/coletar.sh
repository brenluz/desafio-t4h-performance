#!/usr/bin/env bash
# Diagnóstico 05 (depois do experimento 11): 6 de 7 rotas no degrau de ~100 ms; vendas-por-dia com p95 > 1 s;
# banco no teto de CPU e com memória perto do limite (máx. 496,6 de 512 MiB).
# Mede, sob a mesma carga do medir.sh:
#   1) throttling de CPU do banco e da API SÓ durante a carga (cpu.stat lido antes e depois);
#   2) onde o banco gasta tempo (pg_stat_statements, compose do Diagnóstico 02);
#   3) onde a API gasta CPU (node --prof, compose do Diagnóstico 04) e o volume de log por rota;
#   4) composição da memória do container do banco (memory.stat do cgroup) e parâmetros de memória do PostgreSQL;
#   5) EXPLAIN de vendas-por-dia com o cache quente, logo depois da carga.
# Não muda o docker-compose.yml nem o código; no fim devolve banco e API à configuração normal.
set -euo pipefail
cd "$(dirname "$0")/../.."

PASTA=diagnostico/15-diagnostico-05
DIAG=(docker compose -f docker-compose.yml
      -f diagnostico/02-pg-stat-statements/docker-compose.pg-stat.yml
      -f diagnostico/11-diagnostico-04/docker-compose.api-prof.yml)
psql() { docker compose exec -T banco psql -U loja -d loja -X "$@"; }
cpustat() { docker compose exec -T "$1" sh -c "grep -E '^(usage_usec|nr_periods|nr_throttled|throttled_usec) ' /sys/fs/cgroup/cpu.stat"; }
memoria() {
  docker compose exec -T banco sh -c '
    echo "memory.max: $(cat /sys/fs/cgroup/memory.max)"
    echo "memory.current: $(cat /sys/fs/cgroup/memory.current)"
    echo "memory.peak: $(cat /sys/fs/cgroup/memory.peak 2>/dev/null || echo indisponivel)"
    grep -E "^(anon|file|shmem|file_mapped|active_file|inactive_file|active_anon|inactive_anon) " /sys/fs/cgroup/memory.stat'
}

echo "Subindo banco com pg_stat_statements e API com profiler..."
"${DIAG[@]}" up -d
until curl -fsS http://127.0.0.1:3000/saude >/dev/null 2>&1; do sleep 1; done
psql -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;" >/dev/null

echo "Aquecendo por 15s..."
docker compose run --rm -e VUS=5 -e DURACAO=15s -e SEMENTE=43 carga run --quiet --no-summary /carga/teste-carga.js >/dev/null
psql -c "SELECT pg_stat_statements_reset();" >/dev/null

{ echo "### banco antes"; cpustat banco; echo "### api antes"; cpustat api; } > "$PASTA/cpu-antes.txt"
echo "Carga: 20 usuários por 60s, semente 42..."
INICIO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
docker compose run --rm -e VUS=20 -e DURACAO=60s -e SEMENTE=42 carga run --quiet /carga/teste-carga.js > "$PASTA/carga.txt"
{ echo "### banco depois"; cpustat banco; echo "### api depois"; cpustat api; } > "$PASTA/cpu-depois.txt"

echo "Memória do banco logo depois da carga..."
{
  memoria
  echo "### parametros de memoria do PostgreSQL"
  psql -Atc "SELECT name || ' = ' || setting || coalesce(' ' || unit, '') FROM pg_settings WHERE name IN ('shared_buffers','work_mem','maintenance_work_mem','effective_cache_size','max_connections') ORDER BY 1"
  echo "### conexoes abertas no banco"
  psql -Atc "SELECT state || ' ' || count(*) FROM pg_stat_activity WHERE datname = 'loja' GROUP BY state ORDER BY 1"
} > "$PASTA/memoria-banco.txt"

echo "Ranking do banco..."
psql -c "
SELECT calls,
       round(total_exec_time) AS total_ms,
       round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 1) AS pct_tempo,
       round(mean_exec_time::numeric, 1) AS media_ms,
       rows,
       shared_blks_hit, shared_blks_read, temp_blks_written,
       left(regexp_replace(query, '\s+', ' ', 'g'), 110) AS consulta
  FROM pg_stat_statements
 WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'loja')
 ORDER BY total_exec_time DESC
 LIMIT 12;" > "$PASTA/ranking.txt"

echo "EXPLAIN de vendas-por-dia com cache quente..."
psql -c "EXPLAIN (ANALYZE, BUFFERS) SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia, count(DISTINCT p.id) AS pedidos, sum(i.quantidade) AS itens, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '2024-06-01' AND '2024-06-07' AND p.status <> 'cancelado' GROUP BY p.criado_em::date ORDER BY p.criado_em::date" > "$PASTA/explain-vendas.txt"

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

cat "$PASTA/ranking.txt"
