# Fuzzware Comparison to State of the Art
In this experiment we evaluate coverage on P2IM and uEmu targets.

## Running the experiment
In its most basic form, reproduce the experiments by running:
```
./run_experiment.sh
```

However, running it this way will take too long for the experiment to conclude within a resonable amount of time (105 days, see below). This is why some parallelization will be required for a reasonable experiment run time.

Parallelization can be achieved in two ways:
1. On-host parallelization: The number of experiments to run in parallel can be configured by supplying an argument to `./run_experiment.sh`.
2. SSH-based parallelization: Split running the experiment on a separate SSH-accessible host for each target (21 hosts are required for the default configuration). See the [main README](../README.md) and the install helper [ssh_hosts_install.py](../ssh_hosts_install.py) for installation instructions. See [ssh_based_kickoff_experiments.sh](ssh_based_kickoff_experiments.sh) and [ssh_based_collect_results.sh](ssh_based_collect_results.sh) for running the experiment on remote instances and collecting the results afterwards.
3. Mixing and matching: The provided scripts can be mixed and matched, for example to distribute the experiments across a smaller set of medium-sized machines. However, this requires adapting the scripts and command-line arguments. To get started modifying the scripts (or just re-writing them according to your wishes from scratch), refer to the [run_targets.sh wrapper](run_targets.sh) (which allows running only a subset of targets with configurable on-host parallelization), and [ssh_based_kickoff_experiments.sh](ssh_based_kickoff_experiments.sh) to see how the ssh wrapper scripts in [../helper_scripts](../helper_scripts) are invoked.

## Expected Result
Fuzzing will generate project directories under `uEmu/<target>/fuzzware-project-run-XX` and `P2IM/<target>/fuzzware-project-run-XX` (e.g., `uEmu/LiteOS_IoT/fuzzware-project-run-01`).
These directories adhere to the standard fuzzware project layout. After statistics generation, the project directory will
contain aggregated data within the `stats` subdirectory, also according to the standard fuzzware project layout.

Running `run_metric_aggregation.py` will aggregate data from the different `stats` subdirectories, output the relevant data to stdout, and place plots in a `plots` directory next to this README file..

## Computation Resources
Runtime:
- Maximum without parallelization: 105 days with a single fuzzing instance + additional trace generation time.
RAM: 4GB RAM per parallel instance (2GB per instance could suffice as well)

Estimated Run Time details:
The full experiment takes quite a bit of computation resources. We run every one of the 21 targets for 24 hours, and repeat the runs 5 times.

This gives a total CPU time for fuzzing of 21 * 5 = 105 days worth of fuzzing time.

The experiment can be parallelized on the granularity of each 24-hour fuzzing run.

For our own evaluation, we split the experiments among batches of 21 dual core cloud machines in parallel, resulting in roughly 5 days of experiment time.

## Groundtruth
To differentiate between TCG translation blocks and actual coverage, we pre-generated lists of valid basic blocks for each target. These lists have been generated using IDAPython. The script used to generate the basic block valid lists can be found under `fuzzware/scripts/idapython` in the fuzzware installation directory.

## Test Procedure

The experiment is performed by `run_experiment.sh` in the following steps:
1. Run 24-hour fuzzing runs on each target. This is done using the `fuzzware pipeline` utility and results in a Fuzzware project directory.
2. Generate the statistics for each Fuzzware project directory. This is done using the `fuzzware genstats` utility.
3. Based on the statistics generated for each Fuzzware project directory, aggregate the data from Fuzzware projects' `stats` directories again to calculate averages, as well as draw plots. This is done using `run_metric_aggregation.py`.

Note: The runtime for the experiments is prohibitively long if not parallelized. As a result, one will likely split the execution and aggregate data afterwards. For the final aggregation, it is not required to copy the full project directories from remote servers. The larger directories `mainXXX` and `mmio_states` can be omitted. However, the fuzzware project directory location should be maintained when copying subdirectories such as the `stats` directory from a remote server. As such, when copying the `stats` directory for the third run of the `uEmu/LiteOS_IoT` target, place it under `uEmu/LiteOS_IoT/fuzzware-project-run-03/stats` before running `run_metric_aggregation.py`.
