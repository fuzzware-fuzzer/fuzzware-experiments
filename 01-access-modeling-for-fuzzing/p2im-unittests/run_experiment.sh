#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

NUM_INSTANCES=1

set -e
fuzzware checkenv -n $NUM_INSTANCES || { echo "Error during initial sanity checks. Please fix according to debug output."; exit 1; }

"$DIR"/run_fuzzers.sh $NUM_INSTANCES || { echo "[ERROR] run_fuzzers failed"; exit 1; }
"$DIR"/check_results.py "$DIR/groundtruth.csv" || { echo "[ERROR] run_fuzzers failed"; exit 1; }
