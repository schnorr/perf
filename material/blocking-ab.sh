#!/usr/bin/env bash
# Demonstração de blocking: compara várias flags de compilação do mmul.c
# na MESMA máquina (o bloco), em ordem aleatória a cada repetição.
#
# Uso: ./blocking-ab.sh [ID] [REPETICOES] [ORDEM_MATRIZ] [TAM_BLOCO]
#   ID            identificador do bloco (padrão: hostname)
#   REPETICOES    número de rodadas; cada rodada executa todas as
#                 alternativas uma vez, em ordem aleatória (padrão: 5)
#   ORDEM_MATRIZ  n da matriz n x n (padrão: 1024)
#   TAM_BLOCO     tamanho do bloco do mmul (padrão: 32)
#
# As alternativas vêm da variável FLAGS, separadas por ';', ex.:
#   FLAGS="-O2;-O3" ./blocking-ab.sh
#   FLAGS="-O2;-O3 -march=native" ./blocking-ab.sh
# (padrão: "-O0;-O1;-O2;-O3")
#
# Saída (CSV na stdout, uma linha por execução):
#   id,rep,ordem,n,bs,flags,tempo   (tempo em segundos)

set -euo pipefail

ID=${1:-$(hostname)}
REPS=${2:-5}
N=${3:-1024}
BS=${4:-32}
CC=${CC:-gcc}
IFS=';' read -r -a ALT <<< "${FLAGS:--O0;-O1;-O2;-O3}"

DIR=$(cd "$(dirname "$0")" && pwd)
SRC="$DIR/mmul.c"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for i in "${!ALT[@]}"; do
  # shellcheck disable=SC2086
  "$CC" ${ALT[$i]} -o "$TMP/mmul_$i" "$SRC"
done

# Mede o tempo de parede (s) de uma execução.
mede() {
  local ini fim
  ini=$(date +%s%N)
  "$TMP/mmul_$1" "$N" "$BS" > /dev/null
  fim=$(date +%s%N)
  awk -v d=$((fim - ini)) 'BEGIN { printf "%.4f", d / 1e9 }'
}

echo "id,rep,ordem,n,bs,flags,tempo"
for rep in $(seq 1 "$REPS"); do
  ordem=0
  for i in $(shuf -i 0-$(( ${#ALT[@]} - 1 ))); do
    ordem=$((ordem + 1))
    t=$(mede "$i")
    echo "$ID,$rep,$ordem,$N,$BS,${ALT[$i]},$t"
  done
done
