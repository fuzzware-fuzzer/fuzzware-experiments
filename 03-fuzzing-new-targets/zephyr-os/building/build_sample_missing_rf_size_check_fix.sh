#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

export CVENUM=no-CVE-false-positive-rf-size-check
export BASE_COMMIT=a980762f70d7048825e6ce9e42ceb6b5f87a5e44
export FIX_COMMITS=

# Fully patched ieee802154 sample with missing rf size check to trigger false positive crash
export PATCHES="fix-CVE-2021-3323.patch wdt_sam_watchdog_callback_check.patch"

export BOARD=sam4s_xplained
export SHIELD=atmel_rf2xx_xplained
export ZEPHYR_VERSION=2.4.0

# Set common options for our
export SAMPLE_DIR=samples/net/sockets/echo_server

export OVERLAYS=overlay-802154.conf

export EXTRA_DEFINES="-DCONFIG_SHELL=n -DCONFIG_NET_SHELL=n -DCONFIG_NET_L2_IEEE802154_SHELL=n -DCONFIG_NET_SHELL_DYN_CMD_COMPLETION=n "

$DIR/docker_build_sample.sh
