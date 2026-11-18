#!/usr/bin/env bash
# Coleta de dados para as aulas 23/24 (regressão linear):
# tempo de parede do mmul.c (gcc -O2, bloco 32) em função da ordem n.
#
# Uso: ./a23_coleta_mmul.sh [REPETICOES] > a23_mmul_tempos.csv
#   n varia de 128 a 1280 em passos de 64 (ou a lista na variável NS);
#   cada par (n, rep) é executado uma vez, e a ordem de TODAS as
#   execuções é aleatorizada (shuf).
#
# Exemplo (pontos fora da faixa, para discutir extrapolação na aula 24):
#   NS="1536 2048" ./a23_coleta_mmul.sh 3 > a24_mmul_extrapolacao.csv
#
# Saída (CSV na stdout): n,rep,tempo   (tempo em segundos)
# As linhas saem na ordem de execução (útil para checar independência).

set -euo pipefail

REPS=${1:-10}
CC=${CC:-gcc}
DIR=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

"$CC" -O2 -o "$TMP/mmul" "$DIR/mmul.c"

# Mede o tempo de parede (s) de uma execução com ordem $1.
mede() {
  local ini fim
  ini=$(date +%s%N)
  "$TMP/mmul" "$1" 32 > /dev/null
  fim=$(date +%s%N)
  awk -v d=$((fim - ini)) 'BEGIN { printf "%.4f", d / 1e9 }'
}

# Plano experimental: todas as combinações (n, rep), em ordem aleatória.
for n in ${NS:-$(seq 128 64 1280)}; do
  for rep in $(seq 1 "$REPS"); do
    echo "$n $rep"
  done
done | shuf > "$TMP/plano"

echo "n,rep,tempo"
while read -r n rep; do
  echo "$n,$rep,$(mede "$n")"
done < "$TMP/plano"
