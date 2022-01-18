#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

# Wrapper script to collect stats data from experiments across ssh-reachable instances

# Base directory which has fuzzware and fuzzware-experiments as subdirs (default: home directory)
BASE_PATH=${BASE_PATH:-"~"}
# hostname format (default: fuzzware-duo-00, fuzzware-duo-01)
HOST_NAME_FMT=${HOST_NAME_FMT:-"%s%02d"}

i=$HOST_START_INDEX
for target_sub_path in $TARGETS; do
    remote_host="$(printf "$HOST_NAME_FMT" ${HOST_BASE_NAME} $i)"

    remote_target_dir="$BASE_PATH/fuzzware-experiments/$EXPERIMENT_NAME/$target_sub_path"
    local_target_dir="$DIR/../$EXPERIMENT_NAME/$target_sub_path"

    echo "[*] collecting results for target $target_sub_path on $remote_host from dir $remote_target_dir, copying it to local dir: $local_target_dir"

    # relative rsyncing
    remote_target_dir="$remote_target_dir/./"

    # Collect the stats directory, as well as the models for further aggregation
    rsync -avz -r --relative -e ssh "$remote_host:$remote_target_dir/fuzzware-project*run-[0-9][0-9]/stats" "$remote_host:$remote_target_dir/fuzzware-project*run-[0-9][0-9]/main*/fuzzers/fuzzer*/crashes" "$remote_host:$remote_target_dir/fuzzware-project*run-[0-9][0-9]/data" "$remote_host:$remote_target_dir/fuzzware-project*run-[0-9][0-9]/main*/config.yml" "$local_target_dir" || {
        echo "Failed to collect data or got interrupted..."
        exit 1
    }

    # The mmio_config file will not always exist, so sync it separately
    rsync -avz    --relative -e ssh "$remote_host:$remote_target_dir/fuzzware-project*run-[0-9][0-9]/mmio_config.yml" "$local_target_dir" 2> /dev/null

    i=$((i+1))
done