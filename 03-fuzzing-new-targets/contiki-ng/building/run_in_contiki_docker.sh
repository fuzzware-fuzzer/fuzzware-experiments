#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

# This build env is known to allow builds of contiki-ng version 4.4 samples
CONTIKI_DOCKER_VERSION=f823e6a1

base_dir="$(realpath $DIR/..)"

# See if we have already cloned contiki-ng sources
if [ ! -e "$base_dir/contiki-ng" ]; then
    git clone https://github.com/contiki-ng/contiki-ng "$base_dir/contiki-ng"
    git -C "$base_dir/contiki-ng" checkout release/v4.4
fi

# Map our base dir and run the actual command (which will be one of the build scripts normally)
docker run -ti --user="$(id -u)" -v $base_dir:/workdir --workdir=/workdir contiker/contiki-ng:$CONTIKI_DOCKER_VERSION $@