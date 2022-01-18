#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"
# This sample script starts fuzzing experiments on ssh-available machines.
# Requirements: 
# - 21 separate ssh-reachable hosts
# - host naming convention: <HOST_BASE_NAME>00, <HOST_BASE_NAME>01, <HOST_BASE_NAME>02, ... (example: fuzzware-duo-00, fuzzware-duo-01)
# - working ssh configuration with pre-set username
# - password-less sudo set up for user
#   - if password-less sudo is not available, set_limits_and_prepare_afl.sh can be run with root privileges manually on the targets)
#   - if no sudo is available, 
# - pre-installed local fuzzware

# Hosts. Example assumes: fuzzware-duo-01 fuzzware-duo-02 ...
export HOST_BASE_NAME=fuzzware-duo-
# ID to begin with. Example assumes: fuzzware-duo-01 fuzzware-duo-02 fuzzware-duo-03 ...
export HOST_START_INDEX=${HOST_START_INDEX:-1}

export EXPERIMENT_NAME="02-comparison-with-state-of-the-art"
# P2IM and uEmu targets
TARGETS="uEmu/6LoWPAN_Receiver uEmu/6LoWPAN_Sender uEmu/RF_Door_Lock uEmu/Thermostat uEmu/XML_Parser uEmu/LiteOS_IoT uEmu/Zepyhr_SocketCan uEmu/utasker_MODBUS uEmu/utasker_USB uEmu/uEmu.3Dprinter uEmu/uEmu.GPSTracker"
TARGETS="$TARGETS P2IM/CNC P2IM/Drone P2IM/Heat_Press P2IM/Reflow_Oven P2IM/Soldering_Iron P2IM/Console P2IM/Gateway P2IM/PLC P2IM/Robot P2IM/Steering_Control"
export TARGETS

$DIR/../helper_scripts/ssh_wrapper_collect_experiment_results.sh
