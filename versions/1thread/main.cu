#include "main.h"

#define T_BLOCK 1024

__device__ static int dmin3(int a, int b, int c) {
  int m = a < b ? a : b;
  return m < c ? m : c;
}

__global__ void d_init_dpi(int *dp, int m, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n)
    dp[i * m] = i;
}

__global__ void d_init_dpj(int *dp, int m) {
  int j = blockIdx.x * blockDim.x + threadIdx.x;
  if (j < m)
    dp[j] = j;
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
  cudaMalloc(&da, n * sizeof(char));
  cudaMalloc(&db, m * sizeof(char));
  cudaMemcpy(da, a, n * sizeof(char), cudaMemcpyHostToDevice);
  cudaMemcpy(db, b, m * sizeof(char), cudaMemcpyHostToDevice);
  cudaMalloc(&ddp, n * m * sizeof(int));
  cudaMemset(ddp, 0, n * m * sizeof(int));

  int blocks = (n + T_BLOCK - 1) / T_BLOCK;
  d_init_dpi<<<blocks, T_BLOCK>>>(ddp, m, n);
  cudaDeviceSynchronize();
  blocks = (m + T_BLOCK - 1) / T_BLOCK;
  d_init_dpj<<<blocks, T_BLOCK>>>(ddp, m);

  cudaDeviceSynchronize();
  d_edit_core<<<1, 1>>>(da, db, ddp, n, m);
  int result;
  cudaMemcpy(&result, &ddp[(n - 1) * m + (m - 1)], sizeof(int),
             cudaMemcpyDeviceToHost);

  return result;
}

int main(int argc, char *argv[]) {
  char *seq1 = read_sequence(argv[1]);
  char *seq2 = read_sequence(argv[2]);

  int dist = edit_distance(seq1, seq2);
  printf("Edit distance: %d\n", dist);

  return 0;
}