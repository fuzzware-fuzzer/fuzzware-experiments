#!/usr/bin/env bash
./01-access-modeling-for-fuzzing/pw-discovery/ssh_based_collect_results.sh || {
    echo "Could not collect results from experiment 01. Please refer to the error output"
    exit 1
}

./02-comparison-with-state-of-the-art/ssh_based_collect_results.sh || {
    echo "Could not collect results from experiment 02. Please refer to the error output"
    exit 1
}

echo "The results from both experiments have been collected successfully"
echo 'You may find experiment 01 data at ./01-access-modeling-for-fuzzing/pw-discovery/<target_set_name>/<tar_name>/fuzzware-project-run-*'
echo 'You may find experiment 02 data at ./02-comparison-with-state-of-the-art/<target_set_name>/<tar_name>/fuzzware-project-run-*'
echo 'Also, for both experiments, please refer to the run_metric_aggregation.py scripts in ./01-access-modeling-for-fuzzing/pw-discovery and ./02-comparison-with-state-of-the-art to generate summary data'
