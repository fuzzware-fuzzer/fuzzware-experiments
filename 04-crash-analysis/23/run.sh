#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

fuzzware -h > /dev/null || {
    echo "fuzzware not found (workon fuzzware?)"
    exit 1
}

fuzzware emu -v -t -M $DIR/crashing_input $@