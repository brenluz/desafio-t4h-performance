#!/usr/bin/env bash
# Experimento 17: tamanho do pool de conexões da API (DB_POOL_MAX) com os 20 usuários de sempre.
#
# Tamanhos 2, 5, 10 e 20 (o atual), 3 medições de cada, em 3 blocos. Em cada bloco cada tamanho aparece uma vez,
# numa ordem embaralhada fixa, para que deriva e efeitos de ordem não se confundam com o tamanho (F24, seção 7.1).
# Um preparo só, no começo (down -v, 90 s para o autovacuum); entre tamanhos, só a API é recriada.
# O contrato é conferido com cada tamanho antes das medições (e o medir.sh confere de novo em cada uma).
#
# DB_POOL_MAX fica exportada durante cada medição, para que qualquer docker compose chamado pelo medir.sh use
# o mesmo valor; o tamanho e o container da API são registrados antes e depois de cada medição.
# Aos 45 s de cada medição, conta as conexões abertas no banco (o pool mantém as ociosas por 10 s).
# Durante as medições nada é escrito no repositório (o medir.sh conta arquivos sem commit): o registro vai
# para ~/claude-tmp/pool/ e é copiado para esta pasta no fim. Não troca de commit; pode rodar daqui mesmo.
set -uo pipefail
REPO=~/meu-desafio
TMP=~/claude-tmp/pool
DESTINO=$REPO/diagnostico/24-tamanho-pool
BLOCOS=("10 2 20 5" "5 20 2 10" "20 5 10 2")
cd "$REPO"
mkdir -p "$TMP"
: > "$TMP/registro.txt"

registrar() { echo "$*" | tee -a "$TMP/registro.txt"; }

api_atual() {
  echo "DB_POOL_MAX=$(docker compose exec -T api printenv DB_POOL_MAX) container $(docker compose ps -q api | cut -c1-12)"
}

subir_api() {
  export DB_POOL_MAX=$1
  if ! docker compose up -d api >/dev/null 2>&1; then registrar "FALHA: up da api com $1"; return 1; fi
  until curl -fsS http://127.0.0.1:3000/saude >/dev/null 2>&1; do sleep 1; done
  registrar "  api: $(api_atual)"
}

conexoes() {
  docker compose exec -T banco psql -U loja -d loja -tAc \
    "SELECT count(*) FROM pg_stat_activity WHERE backend_type = 'client backend' AND pid <> pg_backend_pid()"
}

fim() {
  unset DB_POOL_MAX
  docker compose up -d api >/dev/null 2>&1
  registrar "api de volta ao padrão: $(api_atual)"
  mkdir -p "$DESTINO" && cp "$TMP/registro.txt" "$DESTINO/registro.txt"
}
trap fim EXIT

registrar "inicio: $(date) commit $(git rev-parse --short HEAD)"
registrar "arquivos fora de resultados: $(git status --porcelain -- . ':(exclude)resultados' | wc -l)"
export DB_POOL_MAX=20
docker compose down -v >/dev/null 2>&1
if ! docker compose up -d --build >/dev/null 2>&1; then registrar "FALHA: docker compose up"; exit 1; fi
until curl -fsS http://127.0.0.1:3000/saude >/dev/null 2>&1; do sleep 2; done
sleep 90

registrar "========== contrato com cada tamanho $(date +%H:%M:%S)"
for n in 20 2 5 10; do
  subir_api "$n" && registrar "  com $n: $(scripts/verificar-contrato.sh comparar 2>&1 | tail -1)"
done

b=0
for bloco in "${BLOCOS[@]}"; do
  b=$((b + 1))
  registrar "========== bloco $b: $bloco $(date +%H:%M:%S)"
  for n in $bloco; do
    subir_api "$n" || continue
    rotulo=$(printf "17-pool-max-%02d" "$n")
    (sleep 45; registrar "  conexões no banco aos 45 s: $(conexoes)") &
    scripts/medir.sh "$rotulo" 2>&1 | grep -E "Resultado salvo|não respondeu" | tee -a "$TMP/registro.txt"
    wait
    registrar "  depois: $(api_atual)"
  done
done
registrar "fim: $(date)"
