#!/usr/bin/env bash
# Diagnóstico 06, complemento: o plano de vendas-por-dia muda conforme a janela de datas?
# Planeja (EXPLAIN sem ANALYZE, não executa) as 725 janelas que a carga pode sortear e conta os planos distintos.
# Depois executa com ANALYZE uma janela de cada tipo de plano encontrado.
set -euo pipefail
cd "$(dirname "$0")/../.."

dia() { date -u -d "2024-01-01 + $1 days" +%F; }
{
  for i in $(seq 0 724); do
    echo "\\echo JANELA $(dia "$i") $(dia $((i + 6)))"
    echo "EXPLAIN (COSTS OFF) SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia, count(DISTINCT p.id) AS pedidos, sum(i.quantidade) AS itens, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '$(dia "$i")' AND '$(dia $((i + 6)))' AND p.status <> 'cancelado' GROUP BY p.criado_em::date ORDER BY p.criado_em::date;"
  done
} | docker compose exec -T banco psql -U loja -d loja -X -q -A -t > /tmp/planos-vendas.txt

# Resume cada plano numa assinatura (nós do plano, sem valores) e conta janelas por assinatura.
awk '
  /^JANELA/ { if (sig != "") { n[sig]++; if (!(sig in ex)) ex[sig] = jan }; jan = $2 " " $3; sig = ""; next }
  { gsub(/^ *(-> *)?/, ""); sub(/ +\(.*$/, ""); sub(/ on [a-z_]+.*$/, "&"); if ($0 ~ /^(Sort Key|Group Key|Index Cond|Recheck Cond|Filter|Hash Cond|Join Filter|Presorted Key)/) next; sig = sig " > " $0 }
  END { if (sig != "") { n[sig]++; if (!(sig in ex)) ex[sig] = jan }; for (s in n) printf "%4d janelas | exemplo %s | plano:%s\n", n[s], ex[s], s }
' /tmp/planos-vendas.txt | sort -rn
