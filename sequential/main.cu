#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cuda.h>

static int min3(int a, int b, int c) {
    int m = a < b ? a : b;
    return m < c ? m : c;
}

int edit_distance(const char *a, const char *b) {
    int n = (int)strlen(a);
    int m = (int)strlen(b);

    int **dp = (int **)malloc((n + 1) * sizeof(int *));
    if (!dp) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }

    for (int i = 0; i <= n; i++) {
        dp[i] = (int *)malloc((m + 1) * sizeof(int));
        if (!dp[i]) {
            fprintf(stderr, "Memory allocation failed\n");
            exit(1);
        }
    }

    for (int i = 0; i <= n; i++) dp[i][0] = i;
    for (int j = 0; j <= m; j++) dp[0][j] = j;

    for (int i = 1; i <= n; i++) {
        for (int j = 1; j <= m; j++) {
            int cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
            dp[i][j] = min3(
                dp[i - 1][j] + 1,
                dp[i][j - 1] + 1,
                dp[i - 1][j - 1] + cost
            );
        }
    }

    int result = dp[n][m];

    for (int i = 0; i <= n; i++) free(dp[i]);
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

    printf("Sequence 1: %s\n", seq1);
    printf("Sequence 2: %s\n", seq2);
    printf("Edit distance: %d\n", dist);

    return 0;
}