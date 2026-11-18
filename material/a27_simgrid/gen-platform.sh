#!/bin/bash
# Gera as plataformas da aula 27: 1 mestre + 32 nós em uma zona "Cluster"
# (cada host tem um link privado full-duplex até um backbone compartilhado).
#   platform-homog.xml   : todos os nós a 1 Gflop/s
#   platform-heterog.xml : velocidades 1.75, 0.25, 1.25, 0.75 Gflop/s (ciclo; média = 1)
gen() { # $1 = arquivo, $2.. = lista cíclica de velocidades (Gf)
  out=$1; shift; speeds=("$@"); n=${#speeds[@]}
  {
  echo "<?xml version='1.0'?>"
  echo '<!DOCTYPE platform SYSTEM "https://simgrid.org/simgrid.dtd">'
  echo '<platform version="4.1">'
  echo '  <zone id="cl" routing="Cluster">'
  echo '    <host id="master" speed="1Gf"/>'
  echo '    <link id="l-master" bandwidth="125MBps" latency="50us" sharing_policy="SPLITDUPLEX"/>'
  echo '    <host_link id="master" up="l-master_UP" down="l-master_DOWN"/>'
  for i in $(seq 0 31); do
    s=${speeds[$((i % n))]}
    echo "    <host id=\"node-$i\" speed=\"${s}Gf\"/>"
    echo "    <link id=\"l-$i\" bandwidth=\"125MBps\" latency=\"50us\" sharing_policy=\"SPLITDUPLEX\"/>"
    echo "    <host_link id=\"node-$i\" up=\"l-${i}_UP\" down=\"l-${i}_DOWN\"/>"
  done
  echo '    <backbone id="backbone" bandwidth="1.25GBps" latency="100us"/>'
  echo '  </zone>'
  echo '</platform>'
  } > "$out"
}
gen platform-homog.xml 1
gen platform-heterog.xml 1.75 0.25 1.25 0.75
