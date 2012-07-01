
// Compile: gcc -Wall -g -shared -D_GNU_SOURCE -fPIC -rdynamic mylibrand.c -lc -ldl -o mylibrand.so
// not portable (-D_GNU_SOURCE)

#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

int rand()
{
  // init the pointer to the original function
  int (*real_rand)(void) = (int (*)(void))dlsym(RTLD_NEXT, "rand");
  
  //// call the original function
  //int r = real_rand();

  // get the env. variable
  char * p_env_ctrl = NULL;
  p_env_ctrl = getenv("MYRAND");

  if (p_env_ctrl)
  {
    // try to convert the variable to integer and return that value
    return(atoi(p_env_ctrl));
  } else
  {
    // call original function
    return real_rand();
  }
}

// eof
