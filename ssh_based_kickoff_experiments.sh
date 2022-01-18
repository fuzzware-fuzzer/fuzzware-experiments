#!/usr/bin/env bash
./01-access-modeling-for-fuzzing/pw-discovery/ssh_based_kickoff_experiments.sh || {
    echo "Kicking off experiment 01 failed. Please refer to the error output"
    exit 1
}

./02-comparison-with-state-of-the-art/ssh_based_kickoff_experiments.sh || {
    echo "Kicking off experiment 02 failed. Please refer to the error output"
    exit 1
}

echo "Both experiments have been kicked off successfully"
echo "Experiment 01 is repeated 10 times, so it will take ~10 days to complete"
echo "Experiment 02 is repeated 5 times, so it will take ~5 days to complete"
echo "Note that some more time is taken to generate traces, so account for one day extra"
