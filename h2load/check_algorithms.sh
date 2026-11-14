#!/bin/sh
# This script checks which algorithms work and which ones fail, including failures due to segmentation fault
# Usage: check_algorithms.sh [server URL]

server="${1:-https://test.openquantumsafe.org:6000/}"

# create an array of algorithms
algorithms="bikel1 bikel3 bikel5 mlkem512 mlkem768 mlkem1024 efrodo640aes efrodo640shake efrodo976aes efrodo976shake efrodo1344aes efrodo1344shake hqc1 hqc3 hqc5"

# declare variables for successes and failures
successes=""
failures=""

# loop through algorithms and execute h2load
# h2load exits 0 even when its requests fail, so check its summary line as well as the exit status
for algorithm in $algorithms
do
  h2load -n 1 -c 1 "$server" --groups "$algorithm" >output.txt 2>&1
  status=$?
  if [ "$status" -eq 0 ] && grep -q ", 1 succeeded, 0 failed, 0 errored" output.txt; then
    echo "$algorithm succeeded."
    successes="$successes $algorithm"
  elif [ "$status" -gt 128 ]; then
    echo "$algorithm failed (crashed with signal $((status - 128)))."
    failures="$failures $algorithm"
  else
    echo "$algorithm failed."
    failures="$failures $algorithm"
  fi
done

rm -f output.txt h2load*.dmp

# output results
echo "Successes: $successes"
echo "Failures: $failures"
