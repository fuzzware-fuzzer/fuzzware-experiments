# Fuzzware Password Character Discovery
In this experiment we collect different metrics about Fuzzware's MMIO modeling:

1. Costs of Model Generation: How much time do MMIO modeling jobs consume?
2. Input Overhead Elimination: How much input overhead is handled by which MMIO model type?
3. Password character recovery speed: How fast are password characters discovered between modeling and non-modelling versions of Fuzzware for different targets?

## Running the experiment
In its most basic form, reproduce the experiments by running:
```
./run_experiment.sh
```

However, running it this way will take too long for the experiment to conclude within a resonable amount of time (200 days, see below). This is why some parallelization will be required for a reasonable experiment run time.

Parallelization can be achieved in two ways:
1. On-host parallelization: The number of experiments to run in parallel can be configured by supplying an argument to `./run_experiment.sh`.
2. SSH-based parallelization: Split running the experiment on a separate SSH-accessible host for each target (20 hosts are required for the default configuration). See the [main README](../../README.md) and the install helper [ssh_hosts_install.py](../../ssh_hosts_install.py) for installation instructions. See [ssh_based_kickoff_experiments.sh](ssh_based_kickoff_experiments.sh) and [ssh_based_collect_results.sh](ssh_based_collect_results.sh) for running the experiment on remote instances and collecting the results afterwards.
3. Mixing and matching: The provided scripts can be mixed and matched, for example to distribute the experiments across a smaller set of medium-sized machines. However, this requires adapting the scripts and command-line arguments. To get started modifying the scripts (or just re-writing them according to your wishes from scratch), refer to the [run_targets.sh wrapper](run_targets.sh) (which allows running only a subset of targets with configurable on-host parallelization), and [ssh_based_kickoff_experiments.sh](ssh_based_kickoff_experiments.sh) to see how the ssh wrapper scripts in [../../helper_scripts](../../helper_scripts) are invoked.

## Expected Result
Fuzzing will generate project directories under `<target>/fuzzware-project-run-XX` (e.g., `ARCH_PRO/fuzzware-project-run-01`).
These directories adhere to the standard fuzzware project layout. After statistics generation, the project directory will
contain aggregated data within the `stats` directory, also according to the standard fuzzware project layout.

Within the `stats` subdirectories, information can be found about the three metrics mentioned previously for each 24-hour fuzzing run at the following locations:
1. Costs of Model Generation: `stats/job_timing_summary.csv`
2. Input Overhead Elimination: `stats/mmio_overhead_elimination.yml`
3. Password character recovery speed: `stats/milestone_discovery_timings.csv`

Running `run_metric_aggregation.py` will aggregate data from the different `stats` directories and output them to stdout.

## Computation Resources
Runtime:
- Maximum without parallelization: 200 days with a single fuzzing instance + additional trace generation time.
- Minimum with parallelization: ~30h (200 instances), ~60h (100 instances), ...
RAM: 4GB RAM per parallel instance (2GB per instance could suffice as well)

Estimated Run Time details:
The full experiment takes quite a bit of computation resources. We run every one of the 10 targets for 24 hours, in two configurations (with modeling enabled and with modeling disabled), and repeat the runs 10 times.

This gives a total CPU time for fuzzing of 10 * 2 * 10 = 200 days worth of fuzzing time.

After fuzzing itself, detailed traces need to be generated, which takes an additional amount of time in the range of 30 minutes to a few hours per 24-hour fuzzing iteration, depending on the target.

The experiment can be parallelized on the granularity of each 24-hour fuzzing run.

## Groundtruth
To measure the password character discovery timings, we collected the required basic block addresses that indicate the successful discovery of each character per target. These basic block addresses can be found in each target directory within the `milestone_bbs.txt` file. Each line within this file represents the discovery address of the next consecutive password character.

## Test Procedure

The experiment is performed in the following steps:
1. Run 24-hour fuzzing runs on each target, once with modeling enabled, and once with modeling disabled. This is done using the `fuzzware pipeline` utility and results in a Fuzzware project directory.
2. Generate the statistics for each Fuzzware project directory. This is done using the `fuzzware genstats` utility.
3. Based on the statistics generated for each Fuzzware project directory, aggregate the data from Fuzzware projects' `stats` directories again to calculate averages.

Note: The runtime for the experiments is prohibitively long if not parallelized. As a result, one will likely split the execution and aggregate data afterwards. For the final aggregation, it is not required to copy the full project directories from remote servers. The larger directories `mainXXX` and `mmio_states` can be omitted. However, the fuzzware project directory location should be maintained when copying subdirectories such as the `stats` directory from a remote server. As such, when copying the `stats` directory for the third run of the `ARCH_PRO` target, place it under `ARCH_PRO/fuzzware-project-run-03/stats` and also sync the `mmio_config.yml` to `ARCH_PRO/fuzzware-project-run-03/mmio_config.yml` before running `run_metric_aggregation.py`.
