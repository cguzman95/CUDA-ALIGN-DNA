#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *read_sequence(const char *filename) {
  FILE *fp = fopen(filename, "r");
  if (!fp) {
    perror("fopen");
    exit(0);
  }

  // 1. Get file size
  if (fseek(fp, 0, SEEK_END) != 0) {
    fclose(fp);
    exit(0);
  }
  long size = ftell(fp);
  if (size == -1) {
    fclose(fp);
    exit(0);
  }
  if (fseek(fp, 0, SEEK_SET) != 0) {
    fclose(fp);
    exit(0);
  }

  // 2. Allocate + read
  char *seq = (char *)malloc((size + 1) * sizeof(char));
  if (!seq) {
    fclose(fp);
    exit(0);
  }

  size_t got = fread(seq, 1, size, fp);
  if (got != (size_t)size) {
    free(seq);
    fclose(fp);
    exit(0);
  }
  seq[got] = '\0';

  fclose(fp);

  // 3. Remove any trailing \n \r
  size_t len = strlen(seq);
  while (len > 0 && (seq[len - 1] == '\n' || seq[len - 1] == '\r')) {
    seq[--len] = '\0';
  }

  if (!seq) {
    fprintf(stderr, "Cannot read data/simple.txt\n");
    exit(0);
  }

  return seq;
}