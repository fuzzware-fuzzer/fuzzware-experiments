#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

CONTIKI_CVES="2020-12140 2020-12141"
ZEPHYR_CVES="2020-10064 2020-10065 2020-10066 2021-3319 2021-3320 2021-3321 2021-3322 2021-3323 2021-3329 2021-3330"

TARGET_LIST=""
for cve in $CONTIKI_CVES; do
    TARGET_LIST="$TARGET_LIST contiki-ng/prebuilt_samples/CVE-$cve"
done

for cve in $ZEPHYR_CVES; do
    TARGET_LIST="$TARGET_LIST zephyr-os/prebuilt_samples/CVE-$cve"
done


if [ $# -ge 1 ]; then
    NUM_PARALLEL_INSTANCES="$1"
else
    # Experiment default: No parallelization
    NUM_PARALLEL_INSTANCES=1
fi

if [ $# -ge 2 ]; then
    EXPERIMENT_REPETITION_COUNT="$2"
else
    # Experiment default: 1 repetition
    EXPERIMENT_REPETITION_COUNT=1
fi

if [ $# -ge 3 ]; then
    FUZZING_RUNTIME="$3"
else
    # Experiment default: 10 days of runtime
    FUZZING_RUNTIME=240:00:00
fi

if [ $# -ge 4 ]; then
    FUZZING_INSTANCES_PER_RUN="$4"
else
    # Experiment default: 15 fuzzing instances
    FUZZING_INSTANCES_PER_RUN=15
fi

# Default sequential config (120 days of time): 1 repetition, 12 targets, 10 days, 15 fuzzing instances, with modeling, no parallelization
SKIP_NON_MODELING=1

# For a more lightweight version of the experiment, we can run everything for a single day, with a single fuzzing instance, and possibly run multiple experiments in parallel
# FUZZING_RUNTIME=24:00:00
# EXPERIMENT_REPETITION_COUNT=1
# NUM_PARALLEL_INSTANCES=2
# SKIP_NON_MODELING=1
# FUZZING_INSTANCES_PER_RUN=1

fuzzware checkenv -n $(( $NUM_PARALLEL_INSTANCES * $FUZZING_INSTANCES_PER_RUN )) || { echo "Error during initial sanity checks. Please fix according to debug output."; exit 1; }

echo "CAUTION: Without modification, this will take a whopping 120 days to complete. This is the case as twelve 10-day fuzzing experiments are executed."
echo "This is a wrapper around run_targets.sh, which you can use directly to parallelize execution and split runs of different targets to different machines to reduce the overall runtime."
sleep 5

# Run all targets with modeling
$DIR/run_targets.sh 1 $EXPERIMENT_REPETITION_COUNT $NUM_PARALLEL_INSTANCES $FUZZING_RUNTIME $FUZZING_INSTANCES_PER_RUN $TARGET_LIST

if [ $SKIP_NON_MODELING -ne 1 ]; then
    # Run all targets without modeling
    $DIR/run_targets.sh 0 $EXPERIMENT_REPETITION_COUNT $NUM_PARALLEL_INSTANCES $FUZZING_RUNTIME $FUZZING_INSTANCES_PER_RUN $TARGET_LIST
fi
