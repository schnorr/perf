# a26_mm1.R -- Simulador de eventos discretos de uma fila M/M/1
# Aula 26 (Análise de Desempenho de Sist. Comp., INF/UFRGS)
#
# Uso:  source("a26_mm1.R")
#       d <- mm1_sim(lambda = 0.8, mu = 1, n_clientes = 10000, semente = 42)
#       mean(d$resposta)    # compare com 1/(mu - lambda)
#
# Retorna um data.frame com uma linha por cliente (FIFO: ordem de chegada = de partida):
#   id, chegada, inicio (do serviço), partida, resposta = partida - chegada
# e o atributo "N_medio" (nº médio de clientes no sistema, média no tempo).

mm1_sim <- function(lambda, mu, n_clientes, semente = NULL, trace = FALSE) {
  if (!is.null(semente)) set.seed(semente)          # inicialização: gerador
  relogio <- 0                                       # relógio da simulação
  fila    <- numeric(0)      # estado: instantes de chegada de quem está no sistema
  prox    <- c(chegada = rexp(1, lambda),            # lista de eventos:
               partida = Inf)                        #   servidor vazio
  area_N  <- 0               # integral de N(t) dt (para o N médio)
  inicio  <- 0               # início do serviço do cliente na frente da fila
  r_cheg <- r_ini <- r_part <- numeric(n_clientes)  # saída (pré-alocada)
  k <- 0                                             # nº de partidas
  while (k < n_clientes) {
    ev <- names(which.min(prox))                     # escalonador: próximo evento
    area_N  <- area_N + length(fila) * (prox[[ev]] - relogio)
    relogio <- prox[[ev]]                            # avança o relógio
    if (ev == "chegada") {                           # --- rotina de chegada
      fila <- c(fila, relogio)                       # entra no sistema
      prox["chegada"] <- relogio + rexp(1, lambda)
      if (length(fila) == 1) {                       # servidor estava livre
        inicio <- relogio
        prox["partida"] <- relogio + rexp(1, mu)
      }
    } else {                                         # --- rotina de partida
      k <- k + 1
      r_cheg[k] <- fila[1]; r_ini[k] <- inicio; r_part[k] <- relogio
      fila <- fila[-1]                               # sai do sistema (FIFO)
      if (length(fila) > 0) {                        # atende o próximo
        inicio <- relogio
        prox["partida"] <- relogio + rexp(1, mu)
      } else prox["partida"] <- Inf
    }
    if (trace) cat(sprintf("t=%7.3f %-8s N=%d  prox.chegada=%7.3f  prox.partida=%7.3f\n",
                           relogio, ev, length(fila), prox[["chegada"]], prox[["partida"]]))
  }
  res <- data.frame(id = seq_len(n_clientes), chegada = r_cheg, inicio = r_ini,   # relatório
                    partida = r_part, resposta = r_part - r_cheg)
  attr(res, "N_medio") <- area_N / relogio
  res
}
