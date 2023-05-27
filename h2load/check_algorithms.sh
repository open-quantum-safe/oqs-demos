#!/bin/sh
# This script checks which algorithms work and which ones fail due to segmentation fault

server="https://test.openquantumsafe.org:6000/"

# create an array of algorithms
algorithms="bikel1 bikel3 bikel5 kyber512 kyber768 kyber1024 frodo640aes frodo640shake frodo976aes frodo976shake frodo1344aes frodo1344shake hqc128 hqc192 hqc256"

# declare variables for successes and failures
successes=""
failures=""

# loop through algorithms and execute h2load
for algorithm in $algorithms
do
  h2load -n 1 -c 1 $server --groups  $algorithm >/dev/null 2>error.txt
  if grep -q "Segmentation fault" error.txt; then
    echo "$algorithm failed."
    failures="$failures $algorithm"
  else
    echo "$algorithm succeeded."
    successes="$successes $algorithm"
  fi
done

rm -f error.txt h2load*.dmp

# output results
echo "Successes: $successes"
echo "Failures: $failures"
