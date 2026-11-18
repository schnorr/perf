#!/bin/bash
# Compila e executa o plano experimental da aula 27 dentro da imagem oficial
# do SimGrid (SimGrid 4.1).  Uso (a partir deste diretório):  ./run.sh
# Saída: results.csv
set -e
IMG=docker.io/simgrid/stable
./gen-platform.sh
docker run --rm -v "$PWD":/work -w /work $IMG sh -c '
  g++ -O2 -std=c++17 master-workers.cpp -lsimgrid -o master-workers
  echo "platform,strategy,workers,tasks,flops,bytes,cv,seed,simtime,walltime" > results.csv
  for plat in homog heterog; do
   for strat in rr ondemand; do
    for W in 1 2 4 6 8 10 12 14 16 20 24 28 32; do
     for B in 1e6 1e7; do
      # cv = 0: determinístico, uma única execução basta
      echo -n "$plat," >> results.csv
      ./master-workers platform-$plat.xml $strat $W 500 1e9 $B 0 1 --log=root.thres:critical >> results.csv
      # cv = 0.5: custos aleatórios, 10 réplicas (sementes diferentes)
      for seed in $(seq 1 10); do
        echo -n "$plat," >> results.csv
        ./master-workers platform-$plat.xml $strat $W 500 1e9 $B 0.5 $seed --log=root.thres:critical >> results.csv
      done
     done
    done
   done
  done'

# Custo da simulação: tempo de parede vs. nº de tarefas (32 trabalhadores, sob demanda)
docker run --rm -v "$PWD":/work -w /work $IMG sh -c '
  echo "platform,strategy,workers,tasks,flops,bytes,cv,seed,simtime,walltime" > scaling.csv
  for N in 1000 10000 100000 1000000; do
    for rep in 1 2 3; do
      echo -n "homog," >> scaling.csv
      ./master-workers platform-homog.xml ondemand 32 $N 1e9 1e6 0.5 $rep --log=root.thres:critical >> scaling.csv
    done
  done'
