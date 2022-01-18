#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

fuzzware -h > /dev/null || {
    echo "Could not find fuzzware. Please re-execute $0 within a fuzzware virtual env (after installation: $ workon fuzzware; $0) to generate configs."
    exit 1
}

# Configure samples
NEWLY_BUILT_DIR="$DIR/../rebuilt"
for t in $NEWLY_BUILT_DIR/CVE*/*.elf; do
    echo "== Generating config for $t"
    elf_name=$(basename $t .elf)
    cve=${elf_name#zephyr-}

    base_config="$DIR/base_configs/$cve.yml"
    if [ -e "$base_config" ]; then
        echo "Using CVE-specific base config: $base_config"
    else
        base_config="$DIR/base_configs/zephyr_default.yml"
        echo "Using fallback base config $base_config"
    fi

    fuzzware genconfig --base-config "$base_config" $t
    echo
done
