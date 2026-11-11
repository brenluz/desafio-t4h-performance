#!/usr/bin/env bash
# Investigação: custo-01 (metade da CPU) x custo-03 (metade da CPU e menos memória), intercalados A-B-B-A-A-B.
# Usa os commits já existentes de cada configuração (git switch --detach) e o mesmo preparo em todas as medições.
# Antes e depois de cada medir.sh lê os contadores do cgroup do banco; grava em $TMP (fora do repositório) para
# não contar como arquivo sem commit, e no fim copia para esta pasta.
set -euo pipefail
cd "$(dirname "$0")/../.."
PASTA=diagnostico/21-memoria-metade-cpu
TMP=/tmp/memoria-metade-cpu
rm -rf "$TMP"; mkdir -p "$TMP"
cp "$0" "$TMP/intercalado.sh"

A_COMMIT=090a390; A_ROTULO=custo-01-metade-cpu-intercalado
B_COMMIT=072634d; B_ROTULO=custo-03-metade-cpu-menos-memoria-intercalado

contadores() {
  docker compose exec -T banco sh -c '
    echo "memory.max $(cat /sys/fs/cgroup/memory.max)"
    echo "memory.current $(cat /sys/fs/cgroup/memory.current)"
    echo "memory.peak $(cat /sys/fs/cgroup/memory.peak)"
    grep -E "^(usage_usec|nr_periods|nr_throttled|throttled_usec) " /sys/fs/cgroup/cpu.stat
    grep -E "^(anon|file|shmem|active_file|inactive_file|pgfault|pgmajfault|workingset_refault_file|workingset_activate_file|workingset_refault_anon|pgscan|pgsteal) " /sys/fs/cgroup/memory.stat
    cat /sys/fs/cgroup/io.stat | sed "s/^/io /"'
}

ciclo() {
  local n=$1 commit=$2 rotulo=$3
  echo "##### ciclo $n: $rotulo ($commit)"
  git switch -q --detach "$commit"
  echo "commit: $(git rev-parse --short HEAD); arquivos fora de resultados: $(git status --porcelain -- . ':(exclude)resultados' | wc -l)"
  date
  docker compose down -v 2>&1 | tail -1
  docker compose up -d --build 2>&1 | tail -1
  until curl -fsS http://127.0.0.1:3000/saude >/dev/null 2>&1; do sleep 2; done
  sleep 90
  scripts/verificar-contrato.sh comparar 2>&1 | tail -1
  { echo "ciclo $n $rotulo $commit"; date; contadores; } > "$TMP/ciclo$n-antes.txt"
  scripts/medir.sh "$rotulo" 2>&1 | grep -E "Resultado salvo"
  { echo "ciclo $n $rotulo $commit"; date; contadores; } > "$TMP/ciclo$n-depois.txt"
}

ciclo 1 $A_COMMIT $A_ROTULO
ciclo 2 $B_COMMIT $B_ROTULO
ciclo 3 $B_COMMIT $B_ROTULO
ciclo 4 $A_COMMIT $A_ROTULO
ciclo 5 $A_COMMIT $A_ROTULO
ciclo 6 $B_COMMIT $B_ROTULO

git switch -q master
mkdir -p "$PASTA"
cp "$TMP"/ciclo*.txt "$PASTA/"
echo "##### fim; de volta a $(git branch --show-current)"
