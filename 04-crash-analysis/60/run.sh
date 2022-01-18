#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

pushd $DIR/../../03-fuzzing-new-targets/contiki-ng/prebuilt_samples/CVE-HALucinator-CVE-2019-9183/POC-min-size-check
./run.sh $@
popd