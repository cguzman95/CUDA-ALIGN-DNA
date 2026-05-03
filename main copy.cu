#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define T_BLOCK 1024

__device__ static int dmin3(int a, int b, int c) {
  int m = a < b ? a : b;
  return m < c ? m : c;
}

__global__ void d_init_dpi(int *dp, int m) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  dp[i * m] = i;
}

__global__ void d_init_dpj(int *dp) {
  int j = blockIdx.x * blockDim.x + threadIdx.x;
  dp[j] = j;
  // printf("%d\n",dp[j]);
}

__global__ void d_edit_core(const char *a, const char *b, int *dp, int n,
                            int m) {
  int tid = blockIdx.x * blockDim.x + threadIdx.x;

  if (tid == 0) {
    for (int i = 1; i < n; i++) {
      for (int j = 1; j < m; j++) {
        int cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        dp[i * m + j] = dmin3(dp[(i - 1) * m + j] + 1, dp[i * m + (j - 1)] + 1,
                              dp[(i - 1) * m + (j - 1)] + cost);
      }
    }
    printf("Edit distance: %d\n", dp[(n - 1) * m + (m - 1)]);
  }
}

int edit_distance(const char *a, const char *b) {
  int n = (int)strlen(a) + 1;
  int m = (int)strlen(b) + 1;

  int **dp = (int **)malloc(n * sizeof(int *));
  for (int i = 0; i < n; i++) {
    dp[i] = (int *)malloc(m * sizeof(int));
  }

  int *ddp;
  const char *da, *db;
  cudaMalloc(&ddp, n * m * sizeof(int));
  cudaMemset(ddp, 0, n * m * sizeof(int));
  cudaMalloc(&da, n * sizeof(char));
  cudaMalloc(&db, m * sizeof(char));

  /*
  cudaMemcpy(ddp, dp, n * m * sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(da, a, n * sizeof(char), cudaMemcpyHostToDevice);
  cudaMemcpy(db, b, n * sizeof(char), cudaMemcpyHostToDevice);
*/
  int blocks;
  blocks = (n + T_BLOCK - 1) / T_BLOCK;
  d_init_dpi<<<blocks, T_BLOCK>>>(ddp, m);
  blocks = (m + T_BLOCK - 1) / T_BLOCK;
  d_init_dpj<<<blocks, T_BLOCK>>>(ddp);
  cudaDeviceSynchronize();
  d_edit_core<<<1, 1>>>(da, db, ddp, n, m);

  int result;
  cudaMemcpy(&result, &ddp[(n - 1) * m + (m - 1)], sizeof(int),
             cudaMemcpyDeviceToHost);

  /*
  for (int i = 0; i < n; i++)
    dp[i][0] = i;
  for (int j = 0; j < m; j++)
    dp[0][j] = j;

  for (int i = 1; i < n; i++) {
    for (int j = 1; j < m; j++) {
      int cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
      dp[i][j] =
          min3(dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost);
    }
  }
  int result = dp[n - 1][m - 1];
  */

  for (int i = 0; i < n; i++)
    free(dp[i]);
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