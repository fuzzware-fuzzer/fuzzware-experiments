#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

fuzzware -h > /dev/null || {
    echo "Could not find fuzzware. Please re-execute $0 within a fuzzware virtual env (after installation: $ workon fuzzware; $0) to generate configs."
    exit 1
}

# Configure samples
NEWLY_BUILT_DIR="$DIR/../rebuilt"
for t in $NEWLY_BUILT_DIR/CVE*/*.elf; do
    fuzzware genconfig --base-config $DIR/base_configs/contiki_common.yml $t
done
