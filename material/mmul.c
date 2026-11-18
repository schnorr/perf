#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define BLOCO_PADRAO 32

double *aloca_matriz(int n)
{
  double *m = malloc(sizeof(double) * n * n);
  if (!m) {
    fprintf(stderr, "Falha ao alocar memoria\n");
    exit(1);
  }
  return m;
}

void preenche_aleatorio(double *m, int n)
{
  for (int i = 0; i < n * n; i++) {
    m[i] = (double) rand() / RAND_MAX;
  }
}

int minimo(int a, int b)
{
  return (a < b) ? a : b;
}

void multiplica_blocos(double *a, double *b, double *c, int n, int bs)
{
  for (int i = 0; i < n * n; i++) {
    c[i] = 0.0;
  }

  for (int bi = 0; bi < n; bi += bs) {
    for (int bj = 0; bj < n; bj += bs) {
      for (int bk = 0; bk < n; bk += bs) {
        int limite_i = minimo(bi + bs, n);
        int limite_j = minimo(bj + bs, n);
        int limite_k = minimo(bk + bs, n);

        for (int i = bi; i < limite_i; i++) {
          for (int j = bj; j < limite_j; j++) {
            double soma = c[i * n + j];
            for (int k = bk; k < limite_k; k++) {
              soma += a[i * n + k] * b[k * n + j];
            }
            c[i * n + j] = soma;
          }
        }
      }
    }
  }
}

void imprime_resultado(double *c, int n)
{
  printf("c[0][0] = %f\n", c[0]);
  printf("c[%d][%d] = %f\n", n - 1, n - 1, c[(n - 1) * n + (n - 1)]);
}

void libera_matrizes(double *a, double *b, double *c)
{
  free(a);
  free(b);
  free(c);
}

int main(int argc, char *argv[])
{
  if (argc < 2 || argc > 3) {
    fprintf(stderr, "Uso: %s <ordem-da-matriz> [tamanho-do-bloco]\n", argv[0]);
    return 1;
  }

  int n = atoi(argv[1]);
  if (n <= 0) {
    fprintf(stderr, "A ordem da matriz deve ser um inteiro positivo\n");
    return 1;
  }

  int bs = (argc == 3) ? atoi(argv[2]) : BLOCO_PADRAO;
  if (bs <= 0) {
    fprintf(stderr, "O tamanho do bloco deve ser um inteiro positivo\n");
    return 1;
  }

  double *a = aloca_matriz(n);
  double *b = aloca_matriz(n);
  double *c = aloca_matriz(n);

  srand(time(NULL));
  preenche_aleatorio(a, n);
  preenche_aleatorio(b, n);

  multiplica_blocos(a, b, c, n, bs);

  imprime_resultado(c, n);

  libera_matrizes(a, b, c);
  return 0;
}
