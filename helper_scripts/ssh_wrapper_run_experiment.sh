#!/bin/bash
# Wrapper script to run experiments across ssh-reachable instances

# Default params about environment
VENV_NAME=fuzzware

tmux_sess_name="fuzzware-eval"

# Base directory which has fuzzware and fuzzware-experiments as subdirs (default: home directory)
BASE_PATH=${BASE_PATH:-"~"}
# hostname format (default: fuzzware-duo-01, fuzzware-duo-02)
HOST_NAME_FMT=${HOST_NAME_FMT:-"%s%02d"}

if [ $USE_DOCKER_INSTALL -eq 1 ]; then
    # In docker container, we don't need the virtualenv and use the constant targets location
    base_dir=/home/user/fuzzware/targets/fuzzware-experiments/$EXPERIMENT_NAME
    cmd="$BASE_PATH/fuzzware/run_docker.sh $BASE_PATH $base_dir/run_targets.sh $RUN_TARGETS_BASE_ARGS"
    test_cmd="$BASE_PATH/fuzzware/run_docker.sh $BASE_PATH fuzzware checkenv"
else
    # For a local installation, use virtualenv and configured base dir
    base_dir="$BASE_PATH/fuzzware-experiments/$EXPERIMENT_NAME"
    cmd="source ~/.virtualenvs/$VENV_NAME/bin/activate; $base_dir/run_targets.sh $RUN_TARGETS_BASE_ARGS"
    test_cmd="source ~/.virtualenvs/$VENV_NAME/bin/activate; fuzzware checkenv"
fi

# Set up environment and dry run
i=$HOST_START_INDEX
for target_sub_path in $TARGETS; do
    remote_host="$(printf "$HOST_NAME_FMT" ${HOST_BASE_NAME} $i)"

    echo "[*] preparing and checking target $target_sub_path on $remote_host in dir $experiment_dir"
    # Prepare afl environment settings
    ssh "$remote_host" "sudo $BASE_PATH/fuzzware-experiments/helper_scripts/set_limits_and_prepare_afl.sh &>/dev/null"

    # Test basic invocation
    ssh -t "$remote_host" "$test_cmd" || {
        echo "[-] Dry run failed for target! Exiting..."
        exit 1
    }

    i=$((i+1))
done

# Kick off actual experiments once everything looks good
i=$HOST_START_INDEX
for target_sub_path in $TARGETS; do
    remote_host="$(printf "$HOST_NAME_FMT" ${HOST_BASE_NAME} $i)"

    echo "[*] kicking off target $target_sub_path on $remote_host in dir $experiment_dir"

    # Kick off target in remote tmux session
    ssh -t "$remote_host" "tmux kill-session -t $tmux_sess_name 2>/dev/null; tmux new-session -d -s $tmux_sess_name bash -c '$cmd $target_sub_path'"  || {
        echo "error while kicking off experiment, exiting"
        exit 1
    }

    i=$((i+1))
done

echo "Sleeping for a minute to sanity check targets after..."
sleep 60

i=$HOST_START_INDEX
for target_sub_path in $TARGETS; do
    remote_host="$(printf "$HOST_NAME_FMT" ${HOST_BASE_NAME} $i)"

    echo "[*] checking tmux experiment session '$tmux_sess_name' on host $remote_host"
    ssh -t "$remote_host" "tmux has-session -t $tmux_sess_name" || {
        echo "error while checking that tmux session is still alive, exiting"
        exit 1
    }
    i=$((i+1))
done

echo
echo "[+] Experiments successfully started!"