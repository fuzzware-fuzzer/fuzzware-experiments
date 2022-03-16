#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

TARGET_LIST="P2IM/CNC P2IM/Drone P2IM/Heat_Press P2IM/Reflow_Oven P2IM/Soldering_Iron P2IM/Console P2IM/Gateway P2IM/PLC P2IM/Robot P2IM/Steering_Control"
TARGET_LIST="$TARGET_LIST uEmu/6LoWPAN_Receiver uEmu/6LoWPAN_Sender uEmu/RF_Door_Lock uEmu/Thermostat uEmu/XML_Parser uEmu/LiteOS_IoT uEmu/Zepyhr_SocketCan uEmu/utasker_MODBUS uEmu/utasker_USB uEmu/uEmu.3Dprinter uEmu/uEmu.GPSTracker"
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
    # Experiment default: 5 repetitions
    EXPERIMENT_REPETITION_COUNT=5
fi

# Default sequential config (105 days of time): 5 repetitions, 21 targets, with modeling, no parallelization
SKIP_NON_MODELING=1

# For a more lightweight version of the experiment, we can run everything a single time, and possibly run multiple experiments in parallel
# This will allow reproducing the data used for Figure 5 in Section 6.2 and Table 5 in the appendix of the paper (excluding re-runs for averages).
# FUZZING_RUNTIME=24:00:00
# EXPERIMENT_REPETITION_COUNT=1
# NUM_PARALLEL_INSTANCES=2
# SKIP_NON_MODELING=1

fuzzware checkenv -n $NUM_PARALLEL_INSTANCES || { echo "Error during initial sanity checks. Please fix according to debug output."; exit 1; }

echo "CAUTION: Without modification, this will take a whopping 105 days to complete. This is the case as 21*5 (targets*repetitions) = 105 24-hour fuzzing experiments are executed."
echo "This is a wrapper around run_targets.sh, which you can use directly to parallelize execution and split runs of different targets to different machines to reduce the overall runtime."
sleep 5

# Run all targets with modeling
$DIR/run_targets.sh 1 $EXPERIMENT_REPETITION_COUNT $NUM_PARALLEL_INSTANCES $FUZZING_RUNTIME $TARGET_LIST

if [ $SKIP_NON_MODELING -ne 1 ]; then
    # Run all targets without modeling
    $DIR/run_targets.sh 0 $EXPERIMENT_REPETITION_COUNT $NUM_PARALLEL_INSTANCES $FUZZING_RUNTIME $TARGET_LIST
fi

$DIR/run_metric_aggregation.py
