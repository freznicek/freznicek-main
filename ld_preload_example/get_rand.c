
// Compile: gcc -Wall -g get_rand.c -o get_rand

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(int argc, char **argv)
{
  srand(time(0));
  int m_rand = rand();
  printf("my random number: %i\n", m_rand);
  return 0;
}

// eof
