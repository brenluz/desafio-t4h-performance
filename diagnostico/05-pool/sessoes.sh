#!/usr/bin/env bash
# Conta quantas conexões (sessões) o banco abre durante uma carga igual à do medir.sh.
# Uso: diagnostico/05-pool/sessoes.sh <arquivo-de-saida>
set -euo pipefail
cd "$(dirname "$0")/../.."

SAIDA="$1"
sessoes() { docker compose exec -T banco psql -U loja -d loja -X -Atc "SELECT sessions FROM pg_stat_database WHERE datname = 'loja'"; }

antes=$(sessoes)
docker compose run --rm -e VUS=20 -e DURACAO=60s -e SEMENTE=42 carga run --quiet /carga/teste-carga.js > "${SAIDA%.txt}-carga.txt"
depois=$(sessoes)

docker compose run --rm -e VUS=20 -e DURACAO=60s -e SEMENTE=42 carga run --quiet /carga/teste-carga.js > "${SAIDA%.txt}-carga.txt"
depois=$(sessoes)

{
  echo "commit: $(git rev-parse --short HEAD)"
  echo "sessoes antes: $antes"
  echo "sessoes depois: $depois"
  echo "diferenca: $((depois - antes)) (inclui as conexoes do proprio psql desta contagem)"
  grep -E "^Requisições" "${SAIDA%.txt}-carga.txt"
} | tee "$SAIDA"