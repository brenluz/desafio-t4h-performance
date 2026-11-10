#!/usr/bin/env bash
# Pré-teste do experimento 12, parte 2: quanta CPU do container do banco cada execução de vendas-por-dia consome,
# com 2 workers (padrão) e sem workers. Lê usage_usec do cgroup antes e depois de 50 execuções na mesma sessão,
# com o banco ocioso (sem carga). A configuração muda só na sessão (SET). Repete a medição 3 vezes por modo.
set -euo pipefail
cd "$(dirname "$0")/../.."

VENDAS="SELECT to_char(p.criado_em::date, 'YYYY-MM-DD') AS dia, count(DISTINCT p.id) AS pedidos, sum(i.quantidade) AS itens, sum(i.quantidade * i.preco_unitario_centavos) AS receita_centavos FROM pedidos p JOIN itens_pedido i ON i.pedido_id = p.id WHERE p.criado_em::date BETWEEN '2024-06-01' AND '2024-06-07' AND p.status <> 'cancelado' GROUP BY p.criado_em::date ORDER BY p.criado_em::date;"
uso() { docker compose exec -T banco sh -c "grep '^usage_usec ' /sys/fs/cgroup/cpu.stat | cut -d' ' -f2"; }

rodar() {
  local workers=$1
  { echo "SET max_parallel_workers_per_gather = $workers;"; for _ in $(seq 50); do echo "$VENDAS"; done; } \
    | docker compose exec -T banco psql -U loja -d loja -X -q -o /dev/null
}

rodar 2 >/dev/null   # aquece o cache
for rodada in 1 2 3; do
  for workers in 2 0; do
    antes=$(uso); inicio=$(date +%s%N)
    rodar "$workers"
    depois=$(uso); fim=$(date +%s%N)
    cpu_ms=$(( (depois - antes) / 1000 ))
    parede_ms=$(( (fim - inicio) / 1000000 ))
    echo "rodada=$rodada workers=$workers execucoes=50 cpu_container_ms=$cpu_ms cpu_por_execucao_ms=$(( cpu_ms / 50 )) tempo_total_ms=$parede_ms"
  done
done
