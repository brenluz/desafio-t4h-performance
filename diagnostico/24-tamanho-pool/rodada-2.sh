#!/usr/bin/env bash
# Experimento 17, rodada 2: tamanhos 1, 2, 3 e 20 do pool com 20 usuários, e a aplicação original na mesma sessão.
#
# Mesmo método do pool.sh: 3 blocos, cada tamanho uma vez por bloco, em ordens embaralhadas fixas (F24, seção 7.1);
# um preparo só para a versão final; entre tamanhos, só a API é recriada; tamanho e container registrados antes e
# depois de cada medição, e as conexões abertas no banco aos 45 s. Depois, a aplicação original (1b5bd26) com
# preparo próprio e 3 medições.
# Troca de commit: rodar a partir de uma cópia fora do repositório. Nada é escrito no repositório durante as
# medições; o registro vai para ~/claude-tmp/pool-r2/ e é copiado para esta pasta no fim, já de volta ao master.
set -uo pipefail
REPO=~/meu-desafio
TMP=~/claude-tmp/pool-r2
DESTINO=$REPO/diagnostico/24-tamanho-pool
ORIGINAL=1b5bd26
BLOCOS=("3 1 20 2" "20 2 3 1" "1 3 2 20")
cd "$REPO"
mkdir -p "$TMP"
: > "$TMP/registro-rodada-2.txt"

registrar() { echo "$*" | tee -a "$TMP/registro-rodada-2.txt"; }

api_atual() {
  echo "DB_POOL_MAX=$(docker compose exec -T api printenv DB_POOL_MAX) container $(docker compose ps -q api | cut -c1-12)"
}

esperar_api() { until curl -fsS http://127.0.0.1:3000/saude >/dev/null 2>&1; do sleep 1; done; }

subir_api() {
  export DB_POOL_MAX=$1
  if ! docker compose up -d api >/dev/null 2>&1; then registrar "FALHA: up da api com $1"; return 1; fi
  esperar_api
  registrar "  api: $(api_atual)"
}

conexoes() {
  docker compose exec -T banco psql -U loja -d loja -tAc \
    "SELECT count(*) FROM pg_stat_activity WHERE backend_type = 'client backend' AND pid <> pg_backend_pid()"
}

preparar() {
  docker compose down -v >/dev/null 2>&1
  if ! docker compose up -d --build >/dev/null 2>&1; then registrar "FALHA: docker compose up"; return 1; fi
  esperar_api
  sleep 90
}

fim() {
  cd "$REPO" && git switch -q master
  unset DB_POOL_MAX
  docker compose down -v >/dev/null 2>&1
  docker compose up -d --build >/dev/null 2>&1
  esperar_api
  registrar "de volta a $(git branch --show-current), api: $(api_atual)"
  mkdir -p "$DESTINO" && cp "$TMP/registro-rodada-2.txt" "$DESTINO/registro-rodada-2.txt"
}
trap fim EXIT

registrar "inicio: $(date) commit $(git rev-parse --short HEAD)"
registrar "arquivos fora de resultados: $(git status --porcelain -- . ':(exclude)resultados' | wc -l)"
export DB_POOL_MAX=20
preparar || exit 1

registrar "========== contrato com cada tamanho $(date +%H:%M:%S)"
for n in 20 1 2 3; do
  subir_api "$n" && registrar "  com $n: $(scripts/verificar-contrato.sh comparar 2>&1 | tail -1)"
done

b=0
for bloco in "${BLOCOS[@]}"; do
  b=$((b + 1))
  registrar "========== bloco $b: $bloco $(date +%H:%M:%S)"
  for n in $bloco; do
    subir_api "$n" || continue
    rotulo=$(printf "17-pool-r2-max-%02d" "$n")
    (sleep 45; registrar "  conexões no banco aos 45 s: $(conexoes)") &
    scripts/medir.sh "$rotulo" 2>&1 | grep -E "Resultado salvo|não respondeu" | tee -a "$TMP/registro-rodada-2.txt"
    wait
    registrar "  depois: $(api_atual)"
  done
done

registrar "========== aplicação original ($ORIGINAL) $(date +%H:%M:%S)"
unset DB_POOL_MAX
if git switch -q --detach "$ORIGINAL"; then
  registrar "arquivos fora de resultados: $(git status --porcelain -- . ':(exclude)resultados' | wc -l)"
  if preparar; then
    registrar "  contrato: $(scripts/verificar-contrato.sh comparar 2>&1 | tail -1)"
    for i in 1 2 3; do
      scripts/medir.sh 17-pool-r2-original 2>&1 | grep -E "Resultado salvo|não respondeu" | tee -a "$TMP/registro-rodada-2.txt"
    done
  fi
else
  registrar "FALHA: git switch $ORIGINAL"
fi
registrar "fim das medições: $(date)"
