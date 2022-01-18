#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

TARGET_LIST="ARCH_PRO LPC1549 NUCLEO_F103RB EFM32GG_STK3700 LPC1768 NUCLEO_F207ZG UBLOX_C027 EFM32LG_STK3600 MOTE_L152RC NUCLEO_L152RE"

FUZZING_RUNTIME=24:00:00

if [ $# -ge 1 ]; then
    NUM_PARALLEL_INSTANCES="$1"
else
    # Experiment default: No parallelization
    NUM_PARALLEL_INSTANCES=1
fi

if [ $# -ge 2 ]; then
    EXPERIMENT_REPETITION_COUNT="$2"
else
    # Experiment default: 10 repetitions
    EXPERIMENT_REPETITION_COUNT=10
fi

# Default sequential config (200 days of time): 10 repetitions, with+without modeling, all targets, no parallelization
SKIP_NON_MODELING=0

# For a more lightweight version of the experiment, we can only run everything a for single time and skip the non-modeling step, and possibly run multiple experiments in parallel
# This will allow reproducing the numbers in 6.1 of the paper (excluding re-runs for averages), but not Figure 6 (password character discovery timings) in the Appendix.
# EXPERIMENT_REPETITION_COUNT=1
# NUM_PARALLEL_INSTANCES=2
# SKIP_NON_MODELING=1

fuzzware checkenv -n $NUM_PARALLEL_INSTANCES || { echo "Error during initial sanity checks. Please fix according to debug output."; exit 1; }

echo "CAUTION: Without modification, this will take a whopping 200 days to complete. This is the case as 10*2*10 (targets*configs*repetitions) = 200 24-hour fuzzing experiments are executed."
echo "This is a wrapper around run_targets.sh, which you can use directly to parallelize execution and split runs of different targets to different machines to reduce the overall runtime."
sleep 5

# Run all targets with modeling
$DIR/run_targets.sh 1 $EXPERIMENT_REPETITION_COUNT $NUM_PARALLEL_INSTANCES $FUZZING_RUNTIME $TARGET_LIST

if [ $SKIP_NON_MODELING -ne 1 ]; then
    # Run all targets without modeling
    $DIR/run_targets.sh 0 $EXPERIMENT_REPETITION_COUNT $NUM_PARALLEL_INSTANCES $FUZZING_RUNTIME $TARGET_LIST
fi

$DIR/run_metric_aggregation.py
