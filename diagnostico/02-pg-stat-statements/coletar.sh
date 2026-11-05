# Diagnóstico: quais consultas consomem mais tempo do banco sob a mesma carga do medir.sh.
# Liga o pg_stat_statements só durante a coleta e devolve o banco à configuração normal no fim.
set -euo pipefail
cd "$(dirname "$0")/../.."

PASTA=diagnostico/02-pg-stat-statements
DIAG=(docker compose -f docker-compose.yml -f "$PASTA/docker-compose.pg-stat.yml")
psql() { docker compose exec -T banco psql -U loja -d loja -X "$@"; }

echo "Reiniciando o banco com pg_stat_statements..."
"${DIAG[@]}" up -d
psql -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"

echo "Aquecendo por 15s..."
docker compose run --rm -e VUS=5 -e DURACAO=15s -e SEMENTE=43 carga run --quiet --no-summary /carga/teste-carga.js >/dev/null
psql -c "SELECT pg_stat_statements_reset();" >/dev/null

echo "Carga: 20 usuários por 60s, semente 42..."
docker compose run --rm -e VUS=20 -e DURACAO=60s -e SEMENTE=42 carga run --quiet /carga/teste-carga.js > "$PASTA/carga.txt"

psql -c "
SELECT calls,
       round(total_exec_time) AS total_ms,
       round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 1) AS pct_tempo,
       round(mean_exec_time::numeric, 1) AS media_ms,
       rows,
       shared_blks_hit, shared_blks_read, temp_blks_written,
       left(regexp_replace(query, '\s+', ' ', 'g'), 140) AS consulta
  FROM pg_stat_statements
 WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'loja')
 ORDER BY total_exec_time DESC
 LIMIT 15;" > "$PASTA/ranking.txt"

echo "Desligando o pg_stat_statements e voltando o banco ao normal..."
psql -c "DROP EXTENSION pg_stat_statements;" >/dev/null
docker compose up -d

cat "$PASTA/ranking.txt"