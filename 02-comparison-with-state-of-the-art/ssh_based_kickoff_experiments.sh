#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

# Hosts. Example assumes: fuzzware-duo-00 fuzzware-duo-01 ...
export HOST_BASE_NAME=fuzzware-duo-
# ID to begin with. Example assumes: fuzzware-duo-00 fuzzware-duo-01 fuzzware-duo-02 ...
export HOST_START_INDEX=${HOST_START_INDEX:-1}
# Fuzzware installed locally or in docker?. Example: Use docker install (see ../ssh_hosts_install.py script)
export USE_DOCKER_INSTALL=${USE_DOCKER_INSTALL:-1}

export EXPERIMENT_NAME="02-comparison-with-state-of-the-art"
# P2IM and uEmu targets
TARGETS="uEmu/6LoWPAN_Receiver uEmu/6LoWPAN_Sender uEmu/RF_Door_Lock uEmu/Thermostat uEmu/XML_Parser uEmu/LiteOS_IoT uEmu/Zepyhr_SocketCan uEmu/utasker_MODBUS uEmu/utasker_USB uEmu/uEmu.3Dprinter uEmu/uEmu.GPSTracker"
TARGETS="$TARGETS P2IM/CNC P2IM/Drone P2IM/Heat_Press P2IM/Reflow_Oven P2IM/Soldering_Iron P2IM/Console P2IM/Gateway P2IM/PLC P2IM/Robot P2IM/Steering_Control"
export TARGETS

NUM_PROCS_ON_HOST=1
# If the instances are more beefy, we can parallelize on-host to reduce the experiment run time
# NUM_PROCS_ON_HOST=2

# All targets 5 times, with modeling, no parallization on the host itself
#                             <use_modeling> <experiment_repetition_count> <num_parallel_procs> <fuzzing_runtime>
export RUN_TARGETS_BASE_ARGS="1              5                             $NUM_PROCS_ON_HOST   24:00:00"

$DIR/../helper_scripts/ssh_wrapper_run_experiment.sh
