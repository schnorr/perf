# Planos experimentais do ping-pong (aula 28), ambos em ordem aleatória.
#  calib: 400 tamanhos log-uniformes em [1 B, 4 MiB]           (calibração)
#  valid: potências de 2 e pontos médios, 10 réplicas cada      (validação)
set.seed(42)
calib <- round(exp(runif(400, log(1), log(4 * 2^20))))
writeLines(as.character(sample(calib)), "sizes-calib.txt")
p <- 0:22
valid <- sort(unique(c(2^p, round(1.5 * 2^p))))
writeLines(as.character(sample(rep(valid, 10))), "sizes-valid.txt")
