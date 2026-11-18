# Calibração (aula 28): ajusta tempo = L + size/B ao ping-pong real (sizes-calib)
# e escreve os fatores SMPI correspondentes (base: link de 10 GB/s e 10 us).
d  <- read.csv("real-calib.csv")
L0 <- 10e-6; B0 <- 10e9
fmt <- function(brk, m) { # m: lista de modelos lm, um por segmento
  L <- sapply(m, function(x) coef(x)[1]); B <- sapply(m, function(x) 1/coef(x)[2])
  c(lat = paste0(brk, ":", signif(L/L0, 6), collapse = ";"),
    bw  = paste0(brk, ":", signif(B/B0, 6), collapse = ";"))
}
# Modelo 1: uma única reta, mínimos quadrados ordinários
m1 <- list(lm(time ~ size, d))
# Modelo 2: duas retas (quebra em 4 KiB), mínimos quadrados ponderados (1/y^2)
m2 <- list(lm(time ~ size, subset(d, size <  4096), weights = 1/time^2),
           lm(time ~ size, subset(d, size >= 4096), weights = 1/time^2))
f <- rbind(uma_reta = fmt(0, m1), duas_retas = fmt(c(0, 4096), m2))
write.csv(data.frame(model = rownames(f), f), "factors.csv", row.names = FALSE)
print(f)
