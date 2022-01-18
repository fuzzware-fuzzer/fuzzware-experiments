#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

export BOARD=${BOARD:-disco_l475_iot1}
export SAMPLE_DIR=samples/bluetooth/peripheral_dis

export ZEPHYR_VERSION=2.2.0

$DIR/docker_build_sample.sh