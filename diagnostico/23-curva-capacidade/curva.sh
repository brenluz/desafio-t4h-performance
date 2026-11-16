#!/usr/bin/env bash
# Curva de capacidade: a aplicação original e a versão final medidas com 1, 5, 10, 20 e 40 usuários virtuais,
# para ver onde cada uma satura (uma medição só com 20 usuários não mostra isso).
#
# Para cada versão: git switch --detach, down -v, 90 s para o autovacuum, contrato, e 3 medições por nível
# com VUS=<n> scripts/medir.sh (mesma duração, aquecimento e semente de sempre).
# Os níveis vão numa ordem embaralhada fixa (20, 1, 40, 5, 10), não crescente, para que efeitos de ordem
# (cache esquentando ao longo das medições) não se confundam com o número de usuários (F24, seção 7.1).
# No fim, a versão final com 20 usuários de novo, como controle de deriva.
# Os resultados ficam sem commit em resultados/ (o medir.sh não conta essa pasta) e são commitados no fim.
# Rodar a partir de uma cópia fora do repositório: os git switch trocam os arquivos.
set -uo pipefail
REPO=~/meu-desafio
cd "$REPO"

FINAL=$(git rev-parse --short master)
ORIGINAL=1b5bd26
NIVEIS=(20 1 40 5 10)

volta_master() { cd "$REPO" && git switch -q master && echo "de volta a $(git branch --show-current)"; }
trap volta_master EXIT

preparar() {
  local commit=$1
  if ! git switch -q --detach "$commit"; then echo "FALHA: git switch $commit"; return 1; fi
  echo "arquivos fora de resultados: $(git status --porcelain -- . ':(exclude)resultados' | wc -l)"
  docker compose down -v >/dev/null 2>&1
  if ! docker compose up -d --build >/dev/null 2>&1; then echo "FALHA: docker compose up"; return 1; fi
  until curl -fsS http://127.0.0.1:3000/saude >/dev/null 2>&1; do sleep 2; done
  sleep 90
  scripts/verificar-contrato.sh comparar 2>&1 | tail -1
}

medir_nivel() {
  local versao=$1 vus=$2 sufixo=${3:-}
  local rotulo
  rotulo=$(printf "curva-%s-vus-%03d%s" "$versao" "$vus" "$sufixo")
  echo "##### $rotulo $(date +%H:%M:%S)"
  for i in 1 2 3; do VUS=$vus scripts/medir.sh "$rotulo" 2>&1 | grep -E "Resultado salvo|não respondeu"; done
}

echo "inicio: $(date)"
for par in "final $FINAL" "original $ORIGINAL"; do
  versao=${par%% *}; commit=${par#* }
  echo "========== $versao ($commit) $(date +%H:%M:%S)"
  preparar "$commit" || continue
  for vus in "${NIVEIS[@]}"; do medir_nivel "$versao" "$vus"; done
done

echo "========== controle: final com 20 usuários $(date +%H:%M:%S)"
preparar "$FINAL" && medir_nivel final 20 -fim
echo "fim: $(date)"
