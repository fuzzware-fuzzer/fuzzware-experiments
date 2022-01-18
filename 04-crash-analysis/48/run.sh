#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

pushd $DIR/../../03-fuzzing-new-targets/zephyr-os/prebuilt_samples/CVE-2020-10066/POC
./run.sh $@
popd