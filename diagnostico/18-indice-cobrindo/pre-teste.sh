#!/usr/bin/env bash
# Pré-teste do experimento 13 (P15: índice que cobre as colunas lidas por vendas-por-dia).
# Tudo numa sessão só; o índice novo é criado (e o antigo removido) dentro de uma transação com ROLLBACK.
# Não roda ANALYZE: assim a amostra de estatísticas é a mesma nos dois lados e só o índice muda.
#   1) CPU do container por execução (cgroup usage_usec) com o índice atual e com o índice que cobre;
#   2) planos das 725 janelas da carga com o índice que cobre;
#   3) equivalência dos resultados das 725 janelas com e sem o índice;
#   4) plano de pedidos-do-cliente (que também usa o índice por pedido_id).
set -euo pipefail
cd "$(dirname "$0")/../.."
P=diagnostico/18-indice-cobrindo

dia() { date -u -d "2024-01-01 + $1 days" +%F; }
VENDAS() { echo "SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia, count(DISTINCT p.id) AS pedidos, sum(i.quantidade) AS itens, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '$1' AND '$2' AND p.status <> 'cancelado' GROUP BY p.criado_em::date ORDER BY p.criado_em::date"; }
JANELAS="SELECT (date '2024-01-01' + g)::date AS inicio, (date '2024-01-01' + g + 6)::date AS fim FROM generate_series(0, 724) g"
TODAS="SELECT j.inicio, r.* FROM ($JANELAS) j CROSS JOIN LATERAL (SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia, count(DISTINCT p.id) AS pedidos, sum(i.quantidade) AS itens, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN j.inicio AND j.fim AND p.status <> 'cancelado' GROUP BY p.criado_em::date) r"

{
  echo "\\timing off"
  echo "\\echo '##### CPU: indice atual, 50 execucoes (2024-06-01..07)'"
  echo "$(VENDAS 2024-06-01 2024-06-07);"
  echo "\\! grep '^usage_usec ' /sys/fs/cgroup/cpu.stat"
  for _ in $(seq 50); do echo "$(VENDAS 2024-06-01 2024-06-07);"; done
  echo "\\! grep '^usage_usec ' /sys/fs/cgroup/cpu.stat"
  echo "\\echo '##### plano atual (2024-06-01..07)'"
  echo "EXPLAIN (ANALYZE, BUFFERS) $(VENDAS 2024-06-01 2024-06-07);"
  echo "CREATE TEMP TABLE resultado_antes AS $TODAS;"

  echo "BEGIN;"
  echo "CREATE INDEX itens_pedido_pedido_id_inclui_idx ON itens_pedido (pedido_id) INCLUDE (quantidade, preco_unitario_centavos);"
  echo "DROP INDEX itens_pedido_pedido_id_idx;"
  echo "\\echo '##### tamanho do indice que cobre'"
  echo "SELECT pg_size_pretty(pg_relation_size('itens_pedido_pedido_id_inclui_idx'));"
  echo "\\echo '##### CPU: indice que cobre, 50 execucoes (2024-06-01..07)'"
  echo "$(VENDAS 2024-06-01 2024-06-07);"
  echo "\\! grep '^usage_usec ' /sys/fs/cgroup/cpu.stat"
  for _ in $(seq 50); do echo "$(VENDAS 2024-06-01 2024-06-07);"; done
  echo "\\! grep '^usage_usec ' /sys/fs/cgroup/cpu.stat"
  echo "\\echo '##### plano com indice que cobre (2024-06-01..07)'"
  echo "EXPLAIN (ANALYZE, BUFFERS) $(VENDAS 2024-06-01 2024-06-07);"
  echo "\\echo '##### plano com indice que cobre numa janela que hoje usa Seq Scan (2024-01-31..02-06)'"
  echo "EXPLAIN (ANALYZE, BUFFERS) $(VENDAS 2024-01-31 2024-02-06);"
  echo "\\echo '##### pedidos-do-cliente com indice que cobre'"
  echo "EXPLAIN (ANALYZE, BUFFERS) SELECT p.id, p.status, p.criado_em, i.produto_id, pr.nome AS produto_nome, i.quantidade, i.preco_unitario_centavos FROM pedidos p LEFT JOIN itens_pedido i ON i.pedido_id = p.id LEFT JOIN produtos pr ON pr.id = i.produto_id WHERE p.cliente_id = 42 ORDER BY p.criado_em DESC, p.id DESC, i.id;"
  echo "\\echo '##### equivalencia: 725 janelas, linhas e diferencas (esperado 0 diferencas)'"
  echo "CREATE TEMP TABLE resultado_depois AS $TODAS;"
  echo "SELECT (SELECT count(*) FROM resultado_antes) AS linhas_antes, (SELECT count(*) FROM resultado_depois) AS linhas_depois, (SELECT count(*) FROM (TABLE resultado_antes EXCEPT ALL TABLE resultado_depois) a) + (SELECT count(*) FROM (TABLE resultado_depois EXCEPT ALL TABLE resultado_antes) b) AS diferencas;"
  echo "\\echo '##### planos das 725 janelas com indice que cobre'"
  for i in $(seq 0 724); do
    echo "\\echo JANELA $(dia "$i") $(dia $((i + 6)))"
    echo "EXPLAIN (COSTS OFF) $(VENDAS "$(dia "$i")" "$(dia $((i + 6)))");"
  done
  echo "ROLLBACK;"
  echo "\\echo '##### confere que voltou ao normal'"
  echo "SELECT indexname FROM pg_indexes WHERE tablename = 'itens_pedido' ORDER BY 1;"
} | docker compose exec -T banco psql -U loja -d loja -X -q > "$P/pre-teste-bruto.txt" 2>&1

# Resumo: CPU por execução e contagem de planos das 725 janelas.
awk '
  /##### CPU/ { modo = $0; n = 0 }
  /^usage_usec/ { v[++n] = $2; if (n == 2) printf "%s -> cpu_container_ms=%d por_execucao_ms=%.1f\n", modo, (v[2]-v[1])/1000, (v[2]-v[1])/50000 }
' "$P/pre-teste-bruto.txt"
sed -n '/planos das 725/,$p' "$P/pre-teste-bruto.txt" | awk '
  /^JANELA/ { if (sig != "") { c[sig]++ }; sig = ""; next }
  /ROLLBACK|confere/ { if (sig != "") { c[sig]++ }; sig = ""; exit }
  /(Scan|Join|Loop)/ { s = $0; gsub(/^ *(-> *)?/, "", s); sub(/ +\(.*$/, "", s); sig = sig " > " s }
  END { for (s in c) printf "%4d janelas |%s\n", c[s], s }' | sort -rn
