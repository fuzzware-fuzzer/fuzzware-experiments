#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

if [ $# -lt 6 ]; then
    echo "Usage: $0 <experiment_repetition_count> <num_parallel_procs> <fuzzing_runtime> <fuzzing_instances_per_run> <target_name_1> [<target_name_2> ...]";
    echo
    echo "=== Example 1 (single process) ==="
    echo "Description: run targets contiki-ng/prebuilt_samples/CVE-2020-12140 and contiki-ng/prebuilt_samples/CVE-2020-12141, for a single run each, fully sequentially, 24 hours each, with a single fuzzing instance"
    echo "Expected run time / RAM requirements: 2 days / 1 core / 4 GB"
    echo "Command line: $0 1 1 1 24:00:00 1 contiki-ng/prebuilt_samples/CVE-2020-12140 and contiki-ng/prebuilt_samples/CVE-2020-12141"
    echo
    echo "=== Example 2 (multiprocessing) ==="
    echo "Description: run target zephyr-os/prebuilt_samples/CVE-2021-3323 with modeling, parallelize 10 total runs, running 2 10-day experiments at a time, with 15 fuzzing instances per run (requires 30 physical cores)."
    echo "Expected run time / RAM requirements: 50 days / 30 cores / 16 GB"
    echo "Command line: $0 1 10 2 240:00:00 15 zephyr-os/prebuilt_samples/CVE-2021-3323"
    exit 1;
fi

run_with_modeling="$1"
experiment_repetition_count="$2"
num_parallel_procs="$3"
fuzzing_runtime="$4"
fuzzing_instances_per_run="$5"
shift; shift; shift; shift; shift;
target_list=$@

echo "running with run_with_modeling=$run_with_modeling, experiment_repetition_count=$experiment_repetition_count, num_parallel_procs=$num_parallel_procs, fuzzing_runtime=$fuzzing_runtime, fuzzing_instances_per_run=$fuzzing_instances_per_run"

project_base_name="fuzzware-project"
statistics_names="coverage crashcontexts"
extra_emu_args="--run-for $fuzzing_runtime"
if [ $run_with_modeling -ne 1 ]; then
    # For the non-modeling cases, we adapt project name and add a pipeline argument
    project_base_name="${project_base_name}-no-modeling" 
    extra_emu_args="$extra_emu_args --disable-modeling"
fi

# We run the target for the specified number of times to account for variance
( for run_no in `seq 1 $experiment_repetition_count`; do
    project_name=$(printf ${project_base_name}-run-%02d $run_no)

    for target in $target_list; do
        echo "fuzzware pipeline -p $project_name -n $fuzzing_instances_per_run $extra_emu_args $DIR/$target && fuzzware genstats -p $DIR/$target/$project_name $statistics_names"
    done
done ) | xargs -I{} --max-procs $num_parallel_procs -- bash -c "{}"
# If you are interested in seeing the actual commands that get queued, use this one instead:
# done ) | xargs -I{} --max-procs $num_parallel_procs -- bash -c "echo '{}'"
