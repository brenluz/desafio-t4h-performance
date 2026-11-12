#!/usr/bin/env bash
# Rodada final: remede a cadeia inteira de experimentos numa sessão só, para que todos os números
# do artigo sejam comparáveis entre si (as medições originais foram feitas em dias e horários diferentes).
#
# Ordem: controle (versão final) -> 00 ... 13 -> 14 (versão final de novo). A versão final medida no início
# e no fim mostra quanto o ambiente derivou ao longo da rodada.
# Cada ponto: git switch --detach no commit medido do experimento, down -v, 90 s para o autovacuum, contrato,
# e 3 medições seguidas com o medir.sh (mesmo protocolo dos experimentos).
# Os resultados ficam sem commit em resultados/ durante a rodada (o medir.sh não conta essa pasta) e são
# commitados no master no fim. Rodar a partir de uma cópia fora do repositório: os git switch trocam os arquivos.
set -uo pipefail
REPO=~/meu-desafio
LOG=${LOG:-~/claude-tmp/rodada.log}
cd "$REPO"

FINAL=$(git rev-parse --short master)
PONTOS=(
  "$FINAL rodada-final-controle-inicio"
  "1b5bd26 rodada-final-00-linha-de-base"
  "09222ee rodada-final-01-indices-fk"
  "e8bafec rodada-final-02-indice-pedidos-status"
  "9bb2e7a rodada-final-03-n-mais-1"
  "4cb8796 rodada-final-04-pool-conexoes"
  "047abf3 rodada-final-05-indice-vendas-por-dia"
  "6deaaab rodada-final-06-pedidos-late-lookup"
  "15eb4a4 rodada-final-07-top-produtos-visao-materializada"
  "3dd7fa4 rodada-final-08-indice-email"
  "adf386e rodada-final-09-vendas-agregada-no-sql"
  "668745f rodada-final-10-busca-trigramas"
  "32bfba2 rodada-final-11-contagem-por-status"
  "9742069 rodada-final-12-sem-paralelismo"
  "ded6504 rodada-final-13-indice-cobrindo-itens"
  "$FINAL rodada-final-14-shared-buffers-256mb"
)

volta_master() { cd "$REPO" && git switch -q master && echo "de volta a $(git branch --show-current)"; }
trap volta_master EXIT

echo "inicio: $(date)"
for ponto in "${PONTOS[@]}"; do
  commit=${ponto%% *}; rotulo=${ponto#* }
  echo "##### $rotulo ($commit) $(date +%H:%M:%S)"
  if ! git switch -q --detach "$commit"; then echo "FALHA: git switch $commit"; continue; fi
  echo "arquivos fora de resultados: $(git status --porcelain -- . ':(exclude)resultados' | wc -l)"
  docker compose down -v >/dev/null 2>&1
  if ! docker compose up -d --build >/dev/null 2>&1; then echo "FALHA: docker compose up"; continue; fi
  until curl -fsS http://127.0.0.1:3000/saude >/dev/null 2>&1; do sleep 2; done
  sleep 90
  scripts/verificar-contrato.sh comparar 2>&1 | tail -1
  for i in 1 2 3; do scripts/medir.sh "$rotulo" 2>&1 | grep -E "Resultado salvo|não respondeu"; done
done
echo "fim: $(date)"
