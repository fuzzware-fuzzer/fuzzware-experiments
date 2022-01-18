#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

if [ $# -lt 5 ]; then
    echo "Usage: $0 <experiment_repetition_count> <num_parallel_procs> <fuzzing_runtime> <target_name_1> [<target_name_2> ...]";
    echo
    echo "=== Example 1 (single process) ==="
    echo "Description: run targets P2IM/CNC and uEmu/6LoWPAN_Receiver with modeling, for a single run each, fully sequentially, 24 hours each"
    echo "Expected run time / RAM requirements: 2 days / 4 GB"
    echo "Command line: $0 1 1 1 24:00:00 P2IM/CNC uEmu/6LoWPAN_Receiver"
    echo
    echo "=== Example 2 (multiprocessing) ==="
    echo "Description: run target uEmu/uEmu.GPSTracker with modeling, parallelize 10 total runs, running 4 24-hour experiments at a time):"
    echo "Expected run time / RAM requirements: 3 days / 16 GB"
    echo "Command line: $0 1 10 4 24:00:00 uEmu/uEmu.GPSTracker"
    exit 1;
fi

# Running this configuration in an unmodified way sequentially will take ~210 days of real-time computation
run_with_modeling="$1"
experiment_repetition_count="$2"
num_parallel_procs="$3"
fuzzing_runtime="$4"
shift; shift; shift; shift;
target_list=$@

echo "running with run_with_modeling=$run_with_modeling, experiment_repetition_count=$experiment_repetition_count, num_parallel_procs=$num_parallel_procs, fuzzing_runtime=$fuzzing_runtime"

project_base_name="fuzzware-project"
statistics_names="coverage crashcontexts"
extra_emu_args="--run-for $fuzzing_runtime"
if [ $run_with_modeling -eq 1 ]; then
    # For the normal modeling case, add some more statistics
    statistics_names="${statistics_names} modeling-costs mmio-overhead-elim"
else
    # For the non-modeling cases, we adapt project name and add a pipeline argument
    project_base_name="${project_base_name}-no-modeling" 
    extra_emu_args="$extra_emu_args --disable-modeling"
fi

# We run the target for the specified number of times to account for variance
( for run_no in `seq 1 $experiment_repetition_count`; do
    project_name=$(printf ${project_base_name}-run-%02d $run_no)

    for target in $target_list; do
        echo "fuzzware pipeline -p $project_name $extra_emu_args $DIR/$target && fuzzware genstats -p $DIR/$target/$project_name $statistics_names"
    done
done ) | xargs -I{} --max-procs $num_parallel_procs -- bash -c "{}"
# If you are interested in seeing the actual commands that get queued, use this one instead:
# done ) | xargs -I{} --max-procs $num_parallel_procs -- bash -c "echo '{}'"
