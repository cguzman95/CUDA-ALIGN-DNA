#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define T_BLOCK 1024

static int min3(int a, int b, int c) {
  int m = a < b ? a : b;
  return m < c ? m : c;
}

__device__ static int dmin3(int a, int b, int c) {
  int m = a < b ? a : b;
  return m < c ? m : c;
}

__global__ void d_edit_core(char *a, char *b, int *dp, int n, int m) {
  int tid = blockIdx.x * blockDim.x + threadIdx.x;

  if (tid == 0) {
    for (int i = 1; i < n; i++) {
      for (int j = 1; j < m; j++) {
        int cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        dp[i * m + j] = dmin3(dp[(i - 1) * m + j] + 1, dp[i * m + (j - 1)] + 1,
                              dp[(i - 1) * m + (j - 1)] + cost);
      }
    }
  }
}

int edit_distance(const char *a, const char *b) {
  int n = (int)strlen(a) + 1;
  int m = (int)strlen(b) + 1;

  int *ddp;
  char *da, *db;
  cudaMalloc(&ddp, n * m * sizeof(int));
  cudaMalloc(&da, n * sizeof(char));
  cudaMalloc(&db, m * sizeof(char));
  cudaMemcpy(da, a, n * sizeof(char), cudaMemcpyHostToDevice);
  cudaMemcpy(db, b, m * sizeof(char), cudaMemcpyHostToDevice);

  int *dp = (int *)malloc(n * m * sizeof(int));
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      dp[i * m + j] = 0;
    }
  }

  for (int i = 0; i < n; i++)
    dp[i * m] = i;
  for (int j = 0; j < m; j++)
    dp[j] = j;
  int result;

  cudaMemcpy(ddp, dp, n * m * sizeof(int), cudaMemcpyHostToDevice);
  cudaDeviceSynchronize();
  d_edit_core<<<1, 1>>>(da, db, ddp, n, m);
  cudaMemcpy(&result, &ddp[(n - 1) * m + (m - 1)], sizeof(int),
             cudaMemcpyDeviceToHost);

  /*
  for (int i = 1; i < n; i++) {
    for (int j = 1; j < m; j++) {
      int cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
      dp[i * m + j] = min3(dp[(i - 1) * m + j] + 1, dp[i * m + (j - 1)] + 1,
                           dp[(i - 1) * m + (j - 1)] + cost);
    }
  }
  result = dp[(n - 1) * m + (m - 1)];
*/

  free(dp);
  return result;
}

int main(int argc, char *argv[]) {
  if (argc != 3) {
    fprintf(stderr, "Usage: %s SEQ1 SEQ2\n", argv[0]);
    return 1;
  }

  const char *seq1 = argv[1];
  const char *seq2 = argv[2];

  int dist = edit_distance(seq1, seq2);
  printf("Edit distance: %d\n", dist);

  return 0;
}