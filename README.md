# Fuzzware Experiments

This directory contains the data required to reproduce the experiments from our USENIX 2022 publication [Fuzzware: Using Precise MMIO Modeling for Effective Firmware Fuzzing](https://www.usenix.org/system/files/sec22summer_scharnowski.pdf).

# Directory Layout
The layout of this directory maps subdirectories to the respective experiments within the publication.

| Subdirectory   | Section  | Experiment | Description |
| -------------- | -------- | -----------| ----------- |
| [01-access-modeling-for-fuzzing/pw-discovery](01-access-modeling-for-fuzzing/pw-discovery)       | 6.1 | Costs of Model Generation, Input Overhead Elimination, PW Discovery Timings | Computation costs (paragraph "Costs of Model Generation"), overhead elimination of models (Table 2), password character discovery timings (Figure 6). |
| [01-access-modeling-for-fuzzing/p2im-unittests](01-access-modeling-for-fuzzing/p2im-unittests) | 6.1 | MMIO Access Model Generality / Passing p2im unit tests. | Unit test passing rates (paragraph "MMIO Access Model Generality"). |
| [02-comparison-with-state-of-the-art/P2IM](02-comparison-with-state-of-the-art/P2IM)           | 6.2 | Fuzzware fuzzing P2IM Target Set for SoA comparison     | Fuzzware performance on P2IM targets (Figure 5, Table 5). |
| [02-comparison-with-state-of-the-art/uEmu](02-comparison-with-state-of-the-art/uEmu)           | 6.2 | Fuzzware fuzzing uEmu Target Set for SoA comparison     | Fuzzware performance on uEmu targets (Table 5). |
| [03-fuzzing-new-targets/Contiki-NG](03-fuzzing-new-targets/contiki-ng)                         | 6.3 | Fuzzware fuzzing Contiki-NG for bug discovery           | Case studies (paragraph "Bug Case Studies"), discovered bugs / assigned CVEs (Table 6). |
| [03-fuzzing-new-targets/Zephyr-OS](03-fuzzing-new-targets/zephyr-os)                           | 6.3 | Fuzzware fuzzing Zephyr OS for bug discovery            | Case studies (paragraph "Bug Case Studies"), discovered bugs / assigned CVEs (Table 6). |
| [04-crash-analysis](04-crash-analysis)                                                         | 6.4 | Crashes triggered across experiments                    | Crash root causes (Table 3). |

# Running the Experiments
As it is hard to predict the type of compute infrastructure that is available to the user (one very beefy instance, many small instances, or anything in between), we supply helper scripts that allow parallelizing execution in different setups.

> **Docker Image**: A docker image is available to run Fuzzware in a pre-built environment. This may become necessary in case dependencies make building Fuzzware challenging for a specific version of the source code. The image alongside some documentation on how to use the image can be found [here on dockerhub](https://hub.docker.com/r/fuzzware/fuzzware).

## Manual Experimentation
If you would like to play around with specific targets by hand, fuzzing a target in isolation can be done using the `fuzzware pipeline` and `fuzzware genstats` utilities.

As an example, to manually fuzz test the `CNC` target which was originally introduced by the authors of P2IM, run:
```
$ fuzzware pipeline 02-comparison-with-state-of-the-art/P2IM/CNC --run-for 24:00:00
```
This will start Fuzzware with a single fuzzing instance and default parameters, and place a `fuzzware-project` directory in `02-comparison-with-state-of-the-art/P2IM/CNC/fuzzware-project`.

For a documentation of supported arguments of Fuzzware's utilities, use `fuzzware <util_name> -h`, and refer to the documentation in the main Fuzzware project.

## Running Full Experiment via SSH Helper Scripts
This is the recommended (default) way of reproducing the experiments so that no customization of run scripts should be necessary.

As involving a lot of SSH-reachable machines and needing to synchronize files can be tedious, we provide helpers for the use case of having (privileged) access to a list of dual core machines. The scripts implementing this functionality are named [ssh_based_kickoff_experiments.sh](02-comparison-with-state-of-the-art/ssh_based_kickoff_experiments.sh) and [ssh_based_collect_results.sh](02-comparison-with-state-of-the-art/ssh_based_collect_results.sh).

The scripts allow running all targets of the [pw discovery](01-access-modeling-for-fuzzing/pw-discovery) and [P2IM + uEmu Sample Fuzzing](02-comparison-with-state-of-the-art) in parallel. While the full experiment reproduction takes around a CPU year to complete, the provided scripts allow reproducing the full experiments to complete within 10 and 5 days (plus some extra time for statistics generation) respectively in the recommended configuration. The exact settings can of course be adapted to reflect the available computation resources and influence the overall experiment execution time.

The default version of these scripts can be installed using the installation script [ssh_hosts_install.py](ssh_hosts_install.py). Starting the installation can be done by simply running
```
./ssh_hosts_install.py
```

Setting up the SSH hosts has some preconditions and setup requirements:
- 41 separate ssh-reachable hosts running Ubuntu (to parallelize the 2x10 instances of the [pw-discovery experiment](01-access-modeling-for-fuzzing/pw-discovery) and the 21 instances of the [P2IM + uEmu Sample Fuzzing experiment](02-comparison-with-state-of-the-art))
- configured host naming convention: fuzzware-duo-01, fuzzware-duo-02, fuzzware-duo-03, ..., fuzzware-duo-41
- working ssh configuration with pre-set username
- password-less sudo set up for user
  - if password-less sudo is not available, [set_limits_and_prepare_afl.sh](helper_scripts/set_limits_and_prepare_afl.sh) can be run with root privileges manually on the targets)
  - if root privileges are generally unavailable, the experiments may still be runable by setting the `AFL_SKIP_CPUFREQ=1` environment variable and by having an afl-accepted core pattern
- pre-installed version of fuzzware (see the main fuzzware repo for installation instructions)

For the default sample setup, the following SSH configuration (`~/.ssh/config`) can be used:
```
Host fuzzware-*
    User worker
    IdentityFile ~/.ssh/<your_key>.key
```

Alongside a set of host entries in `/etc/hosts`:
```
10.0.13.37 fuzzware-duo-01
10.0.13.38 fuzzware-duo-02
10.0.13.39 fuzzware-duo-03
```

To check on experiments or doing other custom things, you can then use:
```
for i in $(seq 1 41); do
    remote_host="fuzzware-duo-$(printf "%02d" $i)"
    # check tmux sessions for running experiments
    ssh -t "worker@$remote_host" "echo $remote_host; tmux list-sessions"
done
```

## Running Full Experiments Locally
Each experiment subdirectory provides a `run_experiments.sh` (e.g., [pw-discovery](01-access-modeling-for-fuzzing/pw-discovery/run_experiment.sh), [P2IM unit tests](01-access-modeling-for-fuzzing/p2im-unittests/run_experiment.sh), [P2IM + uEmu Sample Fuzzing](02-comparison-with-state-of-the-art/run_experiment.sh)) script which reproduces the full experiment.

For the computationallly more expensive experiments, the reproduction script will take too long when run sequentially on a single host. On-host parallelization can be achieved by adjusting or supplying additional arguments to the `run_experiment.sh` scripts.

In case you would like to split a given experiment into chunks of targets (for example, your infrastructure may contain a bunch of 16-core machines and the provided scripts do not exactly fit your compute setup), different parts of each experiment may be chunked off using the related `run_targets.sh` scripts that are located next to `run_experiments.sh`. See the scripts themselves for documentation on how to use them, customize parallelization options, experiment repetition counts, and so on.

## Manually Creating Run Scripts
The scripts provided in this repository are essentially convenience wrappers which we created to make the reproduction and parallelization easier in different hardware environments. However, most scripts provided in this repository are just wrappers around two main fuzzware utilities:

1. `fuzzware pipeline`: Run fuzzer including MMIO modeling with different options to produce a project directory which represents the given run. See `fuzzware pipeline -h` for the full set of options.
2. `fuzzware genstats`: Generate statistics on the results of a particular project directory. See `fuzzware genstats -h` for the full set of options.

For cross-project statistics aggregation, however, Fuzzware does not come with a utility for generating cross-run statistics. This is why we provide scripts which calculate the relevant aggregates within the respective experiment directories. These scripts base on the statistics that are placed into the `stats` project-subdir by `fuzzware genstats`.

# Required Computation Resources
The fulll set of experiments requires a fair amount of computation resources. This is due to the number of targets tested and the repetitions that were done to account for the variance which is inherent to fuzz testing.

To run the full set of experiments performed in Sections 6.1 and 6.2 on a single machine, without parallelization requires a total of `300+` days of fuzzing time. This number stems from:

1. Password discovery: 10 targets, 2 configurations (modeling activated/deactivated), 10 repetitions, 24-hours single run time. -> 205 days including trace/metrics generation.
2. P2IM unit tests: 46 targets, 15 minutes single run time -> 1 day including trace/metrics generation.
3. P2IM fuzzing: 10 targets, 5 repetitions, 24-hour single run time -> 50 days
4. uEmu fuzzing: 11 targets, 5 repetitions, 24-hour single run time -> 50 days

These numbers exclude the additional time required to perform post-fuzzing generation of full traces.
