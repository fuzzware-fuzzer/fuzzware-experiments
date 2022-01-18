#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

pushd $DIR/../../03-fuzzing-new-targets/zephyr-os/prebuilt_samples/CVE-2021-3323/POC
./run.sh $@
popd