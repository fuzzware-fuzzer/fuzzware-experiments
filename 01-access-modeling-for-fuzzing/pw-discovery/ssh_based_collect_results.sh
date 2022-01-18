#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"
# This sample script starts fuzzing experiments on ssh-available machines.
# Requirements: 
# - 20 separate ssh-reachable hosts
# - host naming convention: <HOST_BASE_NAME>00, <HOST_BASE_NAME>01, <HOST_BASE_NAME>02, ... (example: fuzzware-duo-00, fuzzware-duo-01)
# - working ssh configuration with pre-set username
# - password-less sudo set up for user
#   - if password-less sudo is not available, set_limits_and_prepare_afl.sh can be run with root privileges manually on the targets)
#   - if no sudo is available, 
# - pre-installed fuzzware

# Hosts. Example assumes: fuzzware-duo-01 fuzzware-duo-02 ...
export HOST_BASE_NAME=fuzzware-duo-

export EXPERIMENT_NAME="01-access-modeling-for-fuzzing/pw-discovery"
# P2IM and uEmu targets
TARGETS="ARCH_PRO EFM32LG_STK3600 LPC1768 NUCLEO_F103RB NUCLEO_L152RE EFM32GG_STK3700 LPC1549 MOTE_L152RC NUCLEO_F207ZG UBLOX_C027"
export TARGETS

# First collect the experiments with modeling (default host index start: 22, as 01-21 run P2IM / uEmu samples)
export HOST_START_INDEX=${HOST_START_INDEX:-22}
$DIR/../../helper_scripts/ssh_wrapper_collect_experiment_results.sh

# First collect the experiments without modeling
export HOST_START_INDEX=$(( $HOST_START_INDEX + 10 ))
$DIR/../../helper_scripts/ssh_wrapper_collect_experiment_results.sh