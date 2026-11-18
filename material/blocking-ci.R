#!/usr/bin/env Rscript
# Gráfico do slide "How to compute and plot CI in R: output"
# a partir dos CSVs gerados por blocking-ab.sh (um ou vários).
#
# Uso: Rscript blocking-ci.R [--por-rep] saida.pdf arq1.csv [arq2.csv ...]
#
# Padrão: cada "id" (máquina/aluno) é um bloco: as repetições de um
# mesmo id são resumidas pela média antes de calcular os ICs, e as
# diferenças são calculadas dentro de cada bloco (observações pareadas).
#
# --por-rep: cada rodada (id, rep) é um bloco. Útil com uma só máquina:
# as alternativas rodam em sequência, então o bloco é o instante da medição.
#
# Diferenças: entre alternativas consecutivas, em ordem alfabética das
# flags (ex.: -O1 − -O0, -O2 − -O1, -O3 − -O2).

suppressMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(readr)
})

args <- commandArgs(trailingOnly = TRUE)
por_rep <- "--por-rep" %in% args
args <- setdiff(args, "--por-rep")
if (length(args) < 2) {
  stop("Uso: Rscript blocking-ci.R [--por-rep] saida.pdf arq1.csv [arq2.csv ...]")
}
saida <- args[1]
arquivos <- args[-1]

bruto <- arquivos |>
  lapply(read_csv, show_col_types = FALSE,
         col_types = cols(id = col_character(), flags = col_character())) |>
  bind_rows()

alternativas <- sort(unique(bruto$flags)) # -O0, -O1, -O2, -O3
bloco <- if (por_rep) c("id", "rep") else "id"

# Uma linha por bloco, uma coluna por alternativa
largo <- bruto |>
  group_by(across(all_of(bloco)), flags) |>
  summarize(tempo = mean(tempo), .groups = "drop") |>
  pivot_wider(names_from = flags, values_from = tempo)

# Diferenças pareadas dentro de cada bloco, entre alternativas consecutivas
nomes_diff <- character()
for (i in seq_along(alternativas)[-1]) {
  a <- alternativas[i - 1]
  b <- alternativas[i]
  nome <- sprintf("(%s) − (%s)", b, a)
  largo[[nome]] <- largo[[b]] - largo[[a]]
  nomes_diff <- c(nomes_diff, nome)
}

paineis <- c("Tempo", "Diferenças (pareadas)")
dfgg <- largo |>
  select(all_of(c(alternativas, nomes_diff))) |>
  pivot_longer(everything(), names_to = "Alternative", values_to = "Time") |>
  mutate(Alternative = factor(Alternative, levels = c(alternativas, nomes_diff)),
         Painel = factor(ifelse(Alternative %in% nomes_diff, paineis[2], paineis[1]),
                         levels = paineis))

dfsum <- dfgg |>
  group_by(Painel, Alternative) |>
  summarize(num = n(), mean = mean(Time), sd = sd(Time),
            se = 3 * sd / sqrt(num), .groups = "drop")

print(dfsum)

p <- ggplot(dfgg, aes(x = Alternative, y = Time, color = Alternative)) +
  scale_color_brewer(palette = "Set1", guide = "none") + theme_bw() +
  xlab(NULL) + ylab("Tempo (s)") +
  facet_wrap(~Painel, scales = "free") +
  geom_hline(data = data.frame(Painel = factor(paineis[2], levels = paineis)),
             aes(yintercept = 0), color = "gray60", linetype = "dashed") +
  geom_jitter(alpha = .2, position = position_jitter(width = .1)) +
  geom_errorbar(data = dfsum, width = .2,
                aes(y = mean, ymin = mean - se, ymax = mean + se)) +
  geom_point(data = dfsum, shape = 21, size = 3,
             aes(y = mean, color = Alternative)) +
  labs(subtitle = sprintf("%d blocos (%s); IC 99,7%% = média ± 3·sd/√n",
                          nrow(largo), if (por_rep) "rodadas" else "máquinas"))

ggsave(saida, p, width = 8, height = 3.5)
