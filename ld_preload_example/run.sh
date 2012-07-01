#!/bin/bash

NR_LOOPS=3


echo "Compile stuff."
gcc -Wall -g -shared -D_GNU_SOURCE -fPIC -rdynamic mylibrand.c -lc -ldl -o mylibrand.so
ecode=$?
gcc -Wall -g get_rand.c -o get_rand
ecode="${ecode}$?"

if [[ "${ecode}" =~ "^[0]+$" ]]; then
  echo ".compiled ok ${ecode} (ecodes:${ecode})"
else
  echo ".compilation failed (ecodes:${ecode})"
  exit 1
fi

echo "Normal rand operation:"
for i in $(seq 1 ${NR_LOOPS}); do
  ./get_rand
  sleep 1
done

echo "Overriden rand operation:"
for i in $(seq 1 ${NR_LOOPS}); do
  export MYRAND=${i}
  LD_PRELOAD=${PWD}/mylibrand.so ./get_rand
  sleep 1
done



# eof
