#!/usr/bin/env bash
# Demonstração de blocking: compara várias flags de compilação do mmul.c
# na MESMA máquina (o bloco), em ordem aleatória a cada repetição.
#
# Duas etapas: (1) gerar o projeto experimental; (2) executá-lo.
#
#   ./blocking-ab.sh plano  [ID] [REPETICOES] [ORDEM_MATRIZ] [TAM_BLOCO] > plano.csv
#   ./blocking-ab.sh executa plano.csv > resultados.csv
#
#   ID            identificador do bloco (padrão: hostname)
#   REPETICOES    número de rodadas; cada rodada executa todas as
#                 alternativas uma vez, em ordem aleatória (padrão: 5)
#   ORDEM_MATRIZ  n da matriz n x n (padrão: 1024)
#   TAM_BLOCO     tamanho do bloco do mmul (padrão: 32)
#
# As alternativas vêm da variável FLAGS, separadas por ';', ex.:
#   FLAGS="-O2;-O3" ./blocking-ab.sh plano
#   FLAGS="-O2;-O3 -march=native" ./blocking-ab.sh plano
# (padrão: "-O0;-O1;-O2;-O3")
#
# Plano (CSV):     id,rep,ordem,n,bs,flags
# Resultado (CSV): id,rep,ordem,n,bs,flags,tempo   (tempo em segundos)
# A execução segue as linhas do plano na ordem em que aparecem.

set -euo pipefail

uso() {
  sed -n '7,8p' "$0" | sed 's/^# *//' >&2
  exit 1
}

plano() {
  local ID=${1:-$(hostname)} REPS=${2:-5} N=${3:-1024} BS=${4:-32}
  local ALT rep ordem i
  IFS=';' read -r -a ALT <<< "${FLAGS:--O0;-O1;-O2;-O3}"
  echo "id,rep,ordem,n,bs,flags"
  for rep in $(seq 1 "$REPS"); do
    ordem=0
    for i in $(shuf -i 0-$(( ${#ALT[@]} - 1 ))); do
      ordem=$((ordem + 1))
      echo "$ID,$rep,$ordem,$N,$BS,${ALT[$i]}"
    done
  done
}

executa() {
  local PLANO=$1 CC=${CC:-gcc}
  local DIR SRC f id rep ordem n bs flags ini fim
  [ -r "$PLANO" ] || { echo "Plano não encontrado: $PLANO" >&2; exit 1; }
  DIR=$(cd "$(dirname "$0")" && pwd)
  SRC="$DIR/mmul.c"
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT

  # Compila uma vez cada alternativa distinta presente no plano
  declare -A BIN
  i=0
  while IFS= read -r f; do
    BIN[$f]="$TMP/mmul_$i"
    # shellcheck disable=SC2086
    "$CC" $f -o "${BIN[$f]}" "$SRC"
    i=$((i + 1))
  done < <(tail -n +2 "$PLANO" | cut -d, -f6 | sort -u)

  echo "id,rep,ordem,n,bs,flags,tempo"
  tail -n +2 "$PLANO" | while IFS=, read -r id rep ordem n bs flags; do
    ini=$(date +%s%N)
    "${BIN[$flags]}" "$n" "$bs" > /dev/null
    fim=$(date +%s%N)
    awk -v d=$((fim - ini)) -v l="$id,$rep,$ordem,$n,$bs,$flags" \
      'BEGIN { printf "%s,%.4f\n", l, d / 1e9 }'
  done
}

case "${1:-}" in
  plano)   shift; plano "$@" ;;
  executa) [ $# -eq 2 ] || uso; executa "$2" ;;
  *)       uso ;;
esac
