#!/bin/bash
# Aula 28 -- ping-pong real (Open MPI local, memória compartilhada) e
# simulado (SMPI, imagem oficial docker.io/simgrid/stable, SimGrid 4.1).
# Uso (a partir deste diretório): ./run.sh
set -e
Rscript gen-sizes.R                         # planos de calibração/validação (ordem aleatória)
mpicc -O2 pingpong.c -o pingpong-real
mpirun -np 2 --bind-to core ./pingpong-real sizes-calib.txt > real-calib.csv
mpirun -np 2 --bind-to core ./pingpong-real sizes-valid.txt > real-valid.csv
Rscript fit.R                               # regressão -> factors.csv
sort -n -u sizes-valid.txt > sizes-sim.txt  # simulação é determinística: 1 medida por tamanho
docker run --rm -v "$PWD":/work -w /work docker.io/simgrid/stable sh -c '
  smpicc -O2 pingpong.c -o pingpong-smpi
  SIM="smpirun -np 2 -platform platform-2hosts.xml -hostfile hostfile.txt
       --cfg=smpi/simulate-computation:no --log=root.thres:critical"
  # Configuração "limpa": tempo = L + s/B exatamente (sem tráfego reverso,
  # sem envio destacado/eager), para que o simulador use o modelo ajustado.
  CLEAN="--cfg=network/crosstraffic:0 --cfg=smpi/send-is-detached-thresh:0"
  tail -n +2 factors.csv | tr -d "\"" | while IFS=, read model lat bw; do
    $SIM $CLEAN --cfg=smpi/lat-factor:"$lat" --cfg=smpi/bw-factor:"$bw" \
         ./pingpong-smpi sizes-sim.txt > sim-$model.csv
    # mesma calibração, mas com as opções padrão do SMPI (verificação)
    $SIM --cfg=smpi/lat-factor:"$lat" --cfg=smpi/bw-factor:"$bw" \
         ./pingpong-smpi sizes-sim.txt > sim-$model-padrao.csv
  done'
