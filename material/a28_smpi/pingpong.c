/* Ping-pong MPI (aula 28): mede o tempo de ida (round-trip / 2) para uma
 * lista de tamanhos de mensagem lida de um arquivo (uma linha por medida,
 * já em ordem aleatória).  Uso: mpirun -np 2 ./pingpong sizes.txt
 * Saída (rank 0): seq,size,time   (time em segundos, só ida) */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[])
{
  int rank;
  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  FILE* f = fopen(argv[1], "r");
  int n = 0, cap = 1024, s;
  int* sizes = malloc(cap * sizeof(int));
  while (fscanf(f, "%d", &s) == 1) {
    if (n == cap) sizes = realloc(sizes, (cap *= 2) * sizeof(int));
    sizes[n++] = s;
  }
  fclose(f);
  int max = 0;
  for (int i = 0; i < n; i++) if (sizes[i] > max) max = sizes[i];
  char* buf = calloc(max > 0 ? max : 1, 1);
  if (rank == 0) printf("seq,size,time\n");
  for (int w = 0; w < 100; w++) { /* aquecimento */
    if (rank == 0) { MPI_Send(buf, 1, MPI_CHAR, 1, 0, MPI_COMM_WORLD);
                     MPI_Recv(buf, 1, MPI_CHAR, 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE); }
    else           { MPI_Recv(buf, 1, MPI_CHAR, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                     MPI_Send(buf, 1, MPI_CHAR, 0, 0, MPI_COMM_WORLD); }
  }
  for (int i = 0; i < n; i++) {
    MPI_Barrier(MPI_COMM_WORLD);
    double t0 = MPI_Wtime();
    if (rank == 0) {
      MPI_Send(buf, sizes[i], MPI_CHAR, 1, 0, MPI_COMM_WORLD);
      MPI_Recv(buf, sizes[i], MPI_CHAR, 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
      printf("%d,%d,%.9f\n", i, sizes[i], (MPI_Wtime() - t0) / 2);
    } else {
      MPI_Recv(buf, sizes[i], MPI_CHAR, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
      MPI_Send(buf, sizes[i], MPI_CHAR, 0, 0, MPI_COMM_WORLD);
    }
  }
  free(buf); free(sizes);
  MPI_Finalize();
  return 0;
}
