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

  char *line = NULL;
  size_t linecap = 0;
  ssize_t linelen;

  size_t cap = 1024;
  size_t len = 0;
  char *seq = (char *)malloc(cap);
  if (!seq) {
    fclose(fp);
    printf("error read_sequence !seq\n");
    exit(0);
  }

  while ((linelen = getline(&line, &linecap, fp)) != -1) {
    if (linelen == 0)
      continue;

    if (line[0] == '>') {
      continue;
    }

    while (linelen > 0 &&
           (line[linelen - 1] == '\n' || line[linelen - 1] == '\r')) {
      line[--linelen] = '\0';
    }

    if (len + (size_t)linelen + 1 > cap) {
      while (len + (size_t)linelen + 1 > cap)
        cap *= 2;
      char *tmp = (char *)realloc(seq, cap);
      if (!tmp) {
        free(seq);
        free(line);
        fclose(fp);
        return NULL;
      }
      seq = tmp;
    }

    memcpy(seq + len, line, (size_t)linelen);
    len += (size_t)linelen;
  }

  seq[len] = '\0';

  free(line);
  fclose(fp);

  return seq;
}