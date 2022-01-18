#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

pushd $DIR/../../03-fuzzing-new-targets/contiki-ng/prebuilt_samples/CVE-2020-12140/POC
./run.sh $@
popd