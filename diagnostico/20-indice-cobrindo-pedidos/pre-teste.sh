#!/usr/bin/env bash
# Pré-teste do experimento 16: índice que cobre a parte de pedidos de vendas-por-dia.
# Tudo dentro de uma transação com ROLLBACK (nada fica no banco). Sem ANALYZE: só o índice muda.
#   1) A1: CPU por execução com o índice atual (pedidos_criado_em_dia_idx), 3 x 50.
#   2) Variante sem criado_em: ((criado_em::date)) INCLUDE (id, status) -> o plano usa Index Only Scan?
#   3) Variante com criado_em: ((criado_em::date)) INCLUDE (criado_em, id, status), no lugar do índice atual:
#      plano, CPU (B, 3 x 50, depois de 30 s), equivalência das 725 janelas, planos das 725 janelas, tamanho.
#   4) Depois do ROLLBACK: A2, CPU com o índice atual de novo, 3 x 50.
set -euo pipefail
cd "$(dirname "$0")/../.."
P=diagnostico/20-indice-cobrindo-pedidos

dia() { date -u -d "2024-01-01 + $1 days" +%F; }
V() { echo "SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia, count(DISTINCT p.id) AS pedidos, sum(i.quantidade) AS itens, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '$1' AND '$2' AND p.status <> 'cancelado' GROUP BY p.criado_em::date ORDER BY p.criado_em::date"; }
TODAS="SELECT j.inicio, r.* FROM (SELECT (date '2024-01-01' + g)::date AS inicio, (date '2024-01-01' + g + 6)::date AS fim FROM generate_series(0, 724) g) j CROSS JOIN LATERAL (SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia, count(DISTINCT p.id) AS pedidos, sum(i.quantidade) AS itens, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN j.inicio AND j.fim AND p.status <> 'cancelado' GROUP BY p.criado_em::date) r"

bloco() {
  echo "\\echo '##### $1 rodada $2'"
  echo "$(V 2024-06-01 2024-06-07);"
  echo "\\! grep '^usage_usec ' /sys/fs/cgroup/cpu.stat"
  for _ in $(seq 50); do echo "$(V 2024-06-01 2024-06-07);"; done
  echo "\\! grep '^usage_usec ' /sys/fs/cgroup/cpu.stat"
}

{
  echo "SHOW shared_buffers;"
  echo "CREATE TEMP TABLE resultado_antes AS $TODAS;"
  for r in 1 2 3; do bloco "A1 indice atual" "$r"; done
  echo "\\echo '##### plano A1'"
  echo "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) $(V 2024-06-01 2024-06-07);"

  echo "BEGIN;"
  echo "DROP INDEX pedidos_criado_em_dia_idx;"
  echo "CREATE INDEX pedidos_dia_sem_criado_em_idx ON pedidos ((criado_em::date)) INCLUDE (id, status);"
  echo "\\echo '##### plano com a variante SEM criado_em no indice'"
  echo "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) $(V 2024-06-01 2024-06-07);"
  echo "DROP INDEX pedidos_dia_sem_criado_em_idx;"
  echo "CREATE INDEX pedidos_dia_inclui_idx ON pedidos ((criado_em::date)) INCLUDE (criado_em, id, status);"
  echo "\\echo '##### tamanho da variante COM criado_em'"
  echo "SELECT pg_size_pretty(pg_relation_size('pedidos_dia_inclui_idx'));"
  echo "SELECT pg_sleep(30);"
  for r in 1 2 3; do bloco "B indice que cobre pedidos" "$r"; done
  echo "\\echo '##### plano B'"
  echo "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) $(V 2024-06-01 2024-06-07);"
  echo "\\echo '##### equivalencia: 725 janelas (esperado 0 diferencas)'"
  echo "CREATE TEMP TABLE resultado_depois AS $TODAS;"
  echo "SELECT (SELECT count(*) FROM resultado_antes) AS linhas_antes, (SELECT count(*) FROM resultado_depois) AS linhas_depois, (SELECT count(*) FROM (TABLE resultado_antes EXCEPT ALL TABLE resultado_depois) a) + (SELECT count(*) FROM (TABLE resultado_depois EXCEPT ALL TABLE resultado_antes) b) AS diferencas;"
  echo "\\echo '##### planos das 725 janelas'"
  for i in $(seq 0 724); do
    echo "\\echo JANELA"
    echo "EXPLAIN (COSTS OFF) $(V "$(dia "$i")" "$(dia $((i + 6)))");"
  done
  echo "ROLLBACK;"

  for r in 1 2 3; do bloco "A2 indice atual de novo" "$r"; done
  echo "SELECT indexname FROM pg_indexes WHERE tablename = 'pedidos' ORDER BY 1;"
} | docker compose exec -T banco psql -U loja -d loja -X -q > "$P/pre-teste-bruto.txt" 2>&1

awk '
  /^##### (A1|B |A2)/ { modo = $0; n = 0 }
  /^usage_usec/ { v[++n] = $2; if (n == 2) printf "%-45s cpu_por_execucao_ms=%.1f\n", modo, (v[2]-v[1])/50000 }
' "$P/pre-teste-bruto.txt"
sed -n '/planos das 725/,/^ROLLBACK/p' "$P/pre-teste-bruto.txt" | awk '
  /^JANELA/ { if (sig != "") c[sig]++; sig = ""; next }
  /(Scan|Join|Loop)/ { s = $0; gsub(/^ *(-> *)?/, "", s); sub(/ +\(.*$/, "", s); sig = sig " > " s }
  END { if (sig != "") c[sig]++; for (s in c) printf "%4d janelas |%s\n", c[s], s }' | sort -rn
