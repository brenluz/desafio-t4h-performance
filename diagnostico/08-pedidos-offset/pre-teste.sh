#!/usr/bin/env bash
# Pré-teste do P4b (página de /pedidos com OFFSET alto). Só leitura.
# 1) Tenta reproduzir os blocos temporários do Diagnóstico 03 variando status e offset.
# 2) Compara a consulta atual com a reescrita "late row lookup" nos mesmos parâmetros.
set -euo pipefail
cd "$(dirname "$0")/../.."
q() { docker compose exec -T banco psql -U loja -d loja -X -c "$1"; }

echo "##### temp acumulado no banco antes da serie"
q "SELECT temp_files, temp_bytes FROM pg_stat_database WHERE datname='loja';"

atual() {
  echo "##### ATUAL status=$1 offset=$2"
  q "EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM pedidos WHERE status = '$1' ORDER BY criado_em DESC, id DESC LIMIT 20 OFFSET $2;"
}
reescrita() {
  echo "##### REESCRITA status=$1 offset=$2"
  q "EXPLAIN (ANALYZE, BUFFERS) SELECT p.* FROM (SELECT id FROM pedidos WHERE status = '$1' ORDER BY criado_em DESC, id DESC LIMIT 20 OFFSET $2) s JOIN pedidos p ON p.id = s.id ORDER BY p.criado_em DESC, p.id DESC;"
}

for status in pago entregue cancelado pendente; do
  for offset in 0 9980 19980; do
    atual "$status" "$offset"
  done
done

# Caso do contrato: pagina=15000 em pago -> OFFSET 299980, alem das 300 mil linhas (resposta vazia)
atual pago 299980

for status in pago pendente; do
  for offset in 0 19980; do
    reescrita "$status" "$offset"
  done
done
reescrita pago 299980

echo "##### temp acumulado no banco depois da serie"
q "SELECT temp_files, temp_bytes FROM pg_stat_database WHERE datname='loja';"
