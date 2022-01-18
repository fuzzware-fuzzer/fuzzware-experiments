#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

set -e

# Compile targets in docker environment
for build_file in "$DIR/building"/build_sample_*.sh; do
    $DIR/building/run_in_zephyr_docker.sh /workdir/building/$(basename $build_file)
done

echo "Trying to configure targets in current environment"
echo "In case you have no local fuzzware installation, run"
echo "$DIR/building/gen_target_configs.sh manually."
$DIR/building/gen_target_configs.sh

echo "rebuilt targets are located at $NEWLY_BUILT_DIR"