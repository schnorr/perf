#!/bin/bash
#SBATCH --job-name=blocking-ab
#SBATCH --partition=blaise
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --time=00:30:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#
# Executa no PCAD um projeto experimental gerado por blocking-ab.sh.
#
# Uso (no diretório que contém blocking-ab.sh e mmul.c):
#   sbatch blocking-ab.slurm plano.csv [resultados.csv]
#
# Além dos resultados, registra o ambiente da execução em
# <resultados>-ambiente.txt (nó, data, compilador, CPU).

set -euo pipefail

PLANO=${1:?Uso: sbatch blocking-ab.slurm plano.csv [resultados.csv]}
SAIDA=${2:-resultados-${SLURM_JOB_ID}.csv}

cd "$SLURM_SUBMIT_DIR"

{
  echo "job: $SLURM_JOB_ID  nó: $(hostname)  início: $(date -Is)"
  echo "plano: $PLANO ($(md5sum < "$PLANO" | cut -d' ' -f1))"
  gcc --version | head -1
  lscpu
} > "${SAIDA%.csv}-ambiente.txt"

./blocking-ab.sh executa "$PLANO" > "$SAIDA"

echo "fim: $(date -Is)" >> "${SAIDA%.csv}-ambiente.txt"
