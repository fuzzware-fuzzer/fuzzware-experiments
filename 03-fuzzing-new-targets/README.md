# Fuzzware Fuzzing New Targets
In this experiment we fuzzed different parts of contiki-ng and zephyr RTOS to find previously unknown bugs.

To create samples which reproduce cleanly, we created builds that contain the respective bug from the associated CVE. In case additional known bugs are present in the tested version of the target, we use a later commit of the target which incorporates fixes for other bugs, and revert the fix for the bug which we would like to trigger. We do this with the goal of triggering minimal amounts of non-CVE-related crashes, and easen the crash analysis process.

The targets can also be built and fuzz-tested based on the version described in the paper. However, with multiple bugs present in the target, fuzzware will produce crashes which mostly belong to the easier-to-trigger bugs, while bugs that stem from the harder-to-trigger bugs become harder to spot.

We opt for creating these differentiated samples, as these may also be used by future fuzzers as a benchmark to trigger harder-to-reach bugs.

## Running the experiment
While working on this project, we had fuzz testing of zephyr-os and contiki-ng running in the background, rather than having clear-cut 24h fuzzing runs, as the goal in this case was not the comparison with the state of the art, but finding bugs.

As the timing of crash triggers differs considerably between targets, as well as between runs on a given target, there is no much point in running a fixed-time experiment here.

Also, we expect more CPU resources to be required than for the previous experiments to trigger each crash. As such, we do not supply a singular run script.

To test a given target by starting a fuzzing run with a given number of cores, you can use the `fuzzware pipeline` utility with this general syntax:

```
fuzzware pipeline -n <number_of_cores> <target_stack>/prebuilt_samples/<target_name>
```

As an example, to test the `CVE-2020-10066` sample with 15 fuzzing instances, use:
```
fuzzware pipeline -n 15 zephyr-os/prebuilt_samples/CVE-2020-10066
```

## Expected Result
The goal of this experiment is to reproduce the crashes that trigger the bugs for the assigned CVEs.

Crashing inputs from new fuzzing runs can be found in `*/prebuilt_samples/CVE-<targeted_CVE_number>/fuzzware-project*/main*/fuzzers/fuzzer*/crashes`

Sample crashing inputs can be found in the `POC` subdirectories of each pre-built target (e.g., [zephyr-os/prebuilt_samples/CVE-2021-3319/POC](zephyr-os/prebuilt_samples/CVE-2021-3319/POC)).

The following table contains approximate data about how long it took for crashes to occur per sample, based on how many fuzzer instances (`fuzzware-pipeline`'s `-n` argument).

## Computation Resources
This experiment is not bounded to a strict amount of time and computation resources. Similarly, the time taken to trigger each bug varies by run. The different bugs have different degrees of difficulty, leading to different amounts of expected time to crash discovery. To provide an estimation of the rough difficulty for Fuzzware to trigger each bug in the given samples, we give example timings of our re-runs for the different samples that are re-built in a way to minimize the occurrence of spurious crashes (crashes which occur because a bug is triggered from one of the other CVEs).

| Target | # Fuzzing Instances | Example time in Seconds until Crash Discovery |
| ------ | ------------------- | ------------------------------- |
| CVE-2020-10064 | 15 |  12572 |
| CVE-2020-10065 | 15 |  16841 |
| CVE-2020-10066 | 15 |   6691 |
| CVE-2021-3319  | 15 |   8898 |
| CVE-2021-3320  | 15 | 110718 |
| CVE-2021-3321  | 50 | 602888 |
| CVE-2021-3322  | 15 | 174680 |
| CVE-2021-3323  | 15 |  81753 |
| CVE-2021-3329  | 50 |  16207 |
| CVE-2021-3330  | 50 | 89221 |
| CVE-2020-12140 | 25 | 7031 |
| CVE-2020-12141 | 25 | 16881 |

Note that the given timings are taken from isolated runs and may not represent the timings one may experience when re-running Fuzzware on them oneself. Also, the bugs of some samples are now much harder to trigger with the builds that include fixes for bugs from related CVEs. This is the case as additional checks have been introduced, which make the firmware parsing logic discard many of the frames which would previously have been accepted. This manifests especially for CVE-2021-3321 and CVE-2021-3330, which both require re-assembling increasingly well-formatted radio frames.

## Groundtruth
### Crashing Proof-of-Concept Inputs
In this case we know about the bugs which are associated with the assigned CVEs. We provide sample triggers in `POC` subdirectories for each pre-built sample. For example, a crashing input for CVE-2021-3319 can be found in [zephyr-os/prebuilt_samples/CVE-2021-3319/POC](zephyr-os/prebuilt_samples/CVE-2021-3319/POC) and replayed using [run.sh](zephyr-os/prebuilt_samples/CVE-2021-3319/POC/run.sh).

### Re-Building the Target Samples
We provide pre-built samples for each CVE in `*/prebuilt_samples` ([contiki-ng pre-built samples](contiki-ng/prebuilt_samples) and [zephyr-os pre-built samples](zephyr-os/prebuilt_samples)).

The same samples can also be re-built using the `rebuild_targets.sh` scripts ([contiki-ng rebuild_targets.sh](contiki-ng/rebuild_targets.sh) and [zephyr-os rebuild_targets.sh](zephyr-os/rebuild_targets.sh)).

Running these scripts will create docker containers as build environments for both contiki-ng and zephyr RTOS, build samples, and place them in each target's `rebuilt` directory. The expectation of the output is that the zephyr samples, the binary firmware files are fully reproduced, i.e., hash sums for each firmware `.bin` file should match. After re-building the Zephyr samples, you can verify this running:
```
md5sum zephyr-os/prebuilt_samples/CVE*/*.bin */rebuilt/CVE*/*.bin
```

For contiki-ng, the build system within the CE docker container does not seem to produce reproducible binary blobs. While they are functionally equivalent, binaries seem to differ on different host systems by the position of some functions within the binary, leading to differences in call opcodes, function pointers and the like.

## Test Procedure

The experiment is performed by `run_experiment.sh` in the following steps:
1. Run fuzzers for each target sample using `fuzzware pipeline -n <number_of_cores> <target_stack>/prebuilt_samples/<target_name>` (e.g., `fuzzware pipeline -n 15 zephyr-os/prebuilt_samples/CVE-2020-10066`), resulting in Fuzzware project directories in `contiki-ng/prebuilt_samples/CVE*/fuzzware-project*` and `zephyr-os/prebuilt_samples/CVE*/fuzzware-project*`.
2. For each target, wait for crashes to occur within the given Fuzzware project directory. These will be located in `*/prebuilt_samples/CVE*/fuzzware-project*/main*/fuzzers/fuzzer*/crashes`.
3. Manual step: Inspect crashes
