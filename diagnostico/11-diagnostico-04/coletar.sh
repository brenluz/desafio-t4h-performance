#!/usr/bin/env bash
# Diagnóstico 04 (depois do experimento 08): o banco saiu da saturação e a API chegou a ~96% da cota de CPU.
# Mede, sob a mesma carga do medir.sh:
#   1) onde a API gasta CPU (profiler de amostragem do V8: node --prof);
#   2) onde o banco gasta tempo (pg_stat_statements, como nos Diagnósticos 02 e 03);
#   3) quanto log a API escreve por rota (o middleware grava o corpo inteiro de cada resposta).
# Nada disso muda o docker-compose.yml nem o código: usa arquivos de compose à parte com -f
# e, no fim, devolve banco e API à configuração normal.
set -euo pipefail
cd "$(dirname "$0")/../.."

PASTA=diagnostico/11-diagnostico-04
DIAG=(docker compose -f docker-compose.yml
      -f diagnostico/02-pg-stat-statements/docker-compose.pg-stat.yml
      -f "$PASTA/docker-compose.api-prof.yml")
psql() { docker compose exec -T banco psql -U loja -d loja -X "$@"; }

echo "Subindo banco com pg_stat_statements e API com profiler..."
"${DIAG[@]}" up -d
until curl -fsS http://127.0.0.1:3000/saude >/dev/null 2>&1; do sleep 1; done
psql -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;" >/dev/null

echo "Aquecendo por 15s..."
docker compose run --rm -e VUS=5 -e DURACAO=15s -e SEMENTE=43 carga run --quiet --no-summary /carga/teste-carga.js >/dev/null
psql -c "SELECT pg_stat_statements_reset();" >/dev/null

echo "Carga: 20 usuários por 60s, semente 42..."
INICIO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
docker compose run --rm -e VUS=20 -e DURACAO=60s -e SEMENTE=42 carga run --quiet /carga/teste-carga.js > "$PASTA/carga.txt"

echo "Ranking do banco..."
psql -c "
SELECT calls,
       round(total_exec_time) AS total_ms,
       round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 1) AS pct_tempo,
       round(mean_exec_time::numeric, 1) AS media_ms,
       rows,
       left(regexp_replace(query, '\s+', ' ', 'g'), 120) AS consulta
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

cat "$PASTA/ranking.txt" "$PASTA/log-api.txt"
