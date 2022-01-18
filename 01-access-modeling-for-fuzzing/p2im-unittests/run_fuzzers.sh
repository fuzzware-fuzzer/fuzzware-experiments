#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"

if [ -z $(which fuzzware 2>/dev/null) ]; then
    echo "[-] fuzzware not available -> \$workon fuzzware"
    exit 1
fi

if [ $# -gt 0 ]; then
    num_procs=$1
    echo "[*] Running $num_procs instance(s) in parallel"
else
    num_procs=1
    echo "[*] Default: Running on a single instance"
fi

num_available_cores=$(getconf _NPROCESSORS_ONLN)
if [ $num_available_cores -gt 1 ] && [ $num_procs -gt $(( $num_available_cores / 2 )) ]; then
    echo "too many parallel instances chosen (got $num_available_cores virtual cores)";
    exit 1;
fi

FUZZING_RUNTIME="00:15:00"

export AFL_SKIP_CPUFREQ=1
( for f in `find $DIR -iname '*.elf'`; do echo $(dirname $f); done ) | xargs -I{} --max-procs $num_procs -- \
    fuzzware pipeline --run-for=$FUZZING_RUNTIME {};

( for p in `find $DIR -name fuzzware-project`; do echo $p; done ) | xargs -I{} --max-procs $(( $num_procs * 2 )) -- \
    fuzzware gentraces -p {} --main-dirs all bb
