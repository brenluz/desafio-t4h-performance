#!/usr/bin/env bash
# Pré-teste do experimento 13, parte 2: CPU do container por execução de vendas-por-dia, desenho A-B-A.
# A = índice atual (itens_pedido_pedido_id_idx); B = índice que cobre (pedido_id INCLUDE quantidade, preco).
# Motivo: na primeira medição (pre-teste.txt) o lado B mediu logo depois de construir um índice de 45 MB,
# com escrita em segundo plano contando na mesma CPU do container, e possivelmente com um download na máquina.
# Aqui: A (3x50), cria B e espera 30 s, B (3x50), remove B, A de novo (3x50). Tudo numa transação com ROLLBACK.
set -euo pipefail
cd "$(dirname "$0")/../.."

V="SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia, count(DISTINCT p.id) AS pedidos, sum(i.quantidade) AS itens, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '2024-06-01' AND '2024-06-07' AND p.status <> 'cancelado' GROUP BY p.criado_em::date ORDER BY p.criado_em::date;"

bloco() {
  echo "\\echo '##### $1 rodada $2'"
  echo "$V"
  echo "\\! grep '^usage_usec ' /sys/fs/cgroup/cpu.stat"
  for _ in $(seq 50); do echo "$V"; done
  echo "\\! grep '^usage_usec ' /sys/fs/cgroup/cpu.stat"
}

{
  echo "BEGIN;"
  for r in 1 2 3; do bloco "A1 indice atual" "$r"; done
  echo "\\echo '##### plano A1'"
  echo "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) ${V%;};"
  echo "CREATE INDEX itens_pedido_pedido_id_inclui_idx ON itens_pedido (pedido_id) INCLUDE (quantidade, preco_unitario_centavos);"
  echo "SELECT pg_sleep(30);"
  for r in 1 2 3; do bloco "B indice que cobre" "$r"; done
  echo "\\echo '##### plano B'"
  echo "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) ${V%;};"
  echo "DROP INDEX itens_pedido_pedido_id_inclui_idx;"
  for r in 1 2 3; do bloco "A2 indice atual de novo" "$r"; done
  echo "\\echo '##### plano A2'"
  echo "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) ${V%;};"
  echo "ROLLBACK;"
  echo "SELECT indexname FROM pg_indexes WHERE tablename = 'itens_pedido' ORDER BY 1;"
} | docker compose exec -T banco psql -U loja -d loja -X -q > diagnostico/18-indice-cobrindo/cpu-aba-bruto.txt 2>&1

awk '
  /^##### (A1|B |A2)/ { modo = $0; n = 0 }
  /^usage_usec/ { v[++n] = $2; if (n == 2) printf "%-45s cpu_por_execucao_ms=%.1f\n", modo, (v[2]-v[1])/50000 }
' diagnostico/18-indice-cobrindo/cpu-aba-bruto.txt
grep -E "##### plano|Index (Only )?Scan using itens|Heap Fetches|Buffers: shared hit=[0-9]+( read=[0-9]+)?$|Execution Time" diagnostico/18-indice-cobrindo/cpu-aba-bruto.txt | head -24
tail -4 diagnostico/18-indice-cobrindo/cpu-aba-bruto.txt
