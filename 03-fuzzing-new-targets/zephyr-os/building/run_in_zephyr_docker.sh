#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

# This build env is known to allow builds of zephyr version 2.2.0 and 2.4.0 samples
ZEPHYR_DOCKER_VERSION=0.13.1

docker run -ti --user="user" -v "$(realpath $DIR/..)":/workdir --workdir=/workdir docker.io/zephyrprojectrtos/zephyr-build:v$ZEPHYR_DOCKER_VERSION $@