# Crash Analysis
In this experiment, we manually looked at the crashes that were triggered by Fuzzware over the course of the different experiments. As most fuzzing experiments produced a large number of crashes, we pre-clustered the crashes by the pc / lr values of the crashes, and looked at sample crashes for different pc / lr values.

In total, we identified 61 unique crashes. We collected a sample crashing test case for each one of the uniquely identified crashes.

The pre-clustering of crashes for a given fuzzware-project directory can be done via the `fuzzware genstats crashcontexts` utility:
```
fuzzware genstats crashcontexts
```
A file containing different crash contexts can afterwards be found in `fuzzware-project-*/stats/crash_contexts.txt`. This file should already be generated for each project for the synthetic samples ([pw-discovery](../01-access-modeling-for-fuzzing/pw-discovery) and [P2IM / uEmu](../02-comparison-with-state-of-the-art) in case you are running the experiments using the provided experiment kickoff scripts.

> **Note**
> To replay the inputs in this directory, you may need to use the initial version of `fuzzware-emulator` and rebuild fuzzware.
> For example:
> ```bash
> git clone https://github.com/fuzzware-fuzzer/fuzzware-experiments
> git clone https://github.com/fuzzware-fuzzer/fuzzware fuzzware-crash-replay
> cd fuzzware-crash-replay
> ./update.sh
> git --git-dir emulator/.git checkout 075dbb5
> ./build_docker.sh fuzzware-crash-replay
> ./run_docker.sh -r fuzzware-crash-replay -d ../fuzzware-experiments
> ```
> Then within docker
> ```bash
> cd 04-crash-analysis/01
> ./run.sh
> cd ~/fuzzware/targets/03-fuzzing-new-targets/zephyr-os/prebuilt_samples/CVE-2021-3319/POC
> ./run.sh
> ```

## Crash Overview
The following table shows an overview of the crashes which were produced by Fuzzware and which we identified as unique.

| # | Firmware Set       | Category       | Target          | Run Script          | Description |
| - | ------------       | --------       | ------          | ----------          | ----------- |
| 01 | [Synthetic Samples](../01-access-modeling-for-fuzzing/pw-discovery) | Security       | ARCH_PRO        | [run.sh](01/run.sh) | Password bypass crash |
| 02 | [Synthetic Samples](../01-access-modeling-for-fuzzing/pw-discovery) | Security       | EFM32GG_STK3700 | [run.sh](02/run.sh) | Password bypass crash |
| 03 | [Synthetic Samples](../01-access-modeling-for-fuzzing/pw-discovery) | Security       | EFM32LG_STK3600 | [run.sh](03/run.sh) | Password bypass crash |
| 04 | [Synthetic Samples](../01-access-modeling-for-fuzzing/pw-discovery) | Security       | LPC1549         | [run.sh](04/run.sh) | Password bypass crash |
| 05 | [Synthetic Samples](../01-access-modeling-for-fuzzing/pw-discovery) | Security       | LPC1768         | [run.sh](05/run.sh) | Password bypass crash |
| 06 | [Synthetic Samples](../01-access-modeling-for-fuzzing/pw-discovery) | Security       | MOTE_L152RC     | [run.sh](06/run.sh) | Password bypass crash |
| 07 | [Synthetic Samples](../01-access-modeling-for-fuzzing/pw-discovery) | Security       | NUCLEO_F103RB   | [run.sh](07/run.sh) | Password bypass crash |
| 08 | [Synthetic Samples](../01-access-modeling-for-fuzzing/pw-discovery) | Security       | NUCLEO_F207ZG   | [run.sh](08/run.sh) | Password bypass crash |
| 09 | [Synthetic Samples](../01-access-modeling-for-fuzzing/pw-discovery) | Security       | NUCLEO_L152RE   | [run.sh](09/run.sh) | Password bypass crash |
| 10 | [Synthetic Samples](../01-access-modeling-for-fuzzing/pw-discovery) | Security       | UBLOX_C027      | [run.sh](10/run.sh) | Password bypass crash |
| 11 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Security       | CNC             | [run.sh](11/run.sh) | Stack OOB write       |
| 12 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Security       | Gateway         | [run.sh](12/run.sh) | OOB write in HAL      |
| 13 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Security       | Heat Press      | [run.sh](13/run.sh) | Buffer overflow       |
| 14 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Security       | PLC             | [run.sh](14/run.sh) | Missing bounds check  |
| 15 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Security       | PLC             | [run.sh](15/run.sh) | Missing bounds check  |
| 16 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Security       | PLC             | [run.sh](16/run.sh) | Missing bounds check  |
| 17 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Security       | PLC             | [run.sh](17/run.sh) | Missing bounds check  |
| 18 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Security       | CNC             | [run.sh](18/run.sh) | CNC input validation  |
| 19 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Security       | Soldering Iron  | [run.sh](19/run.sh) | Expired pointer use   |
| 20 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Unchecked Init | Robot           | [run.sh](20/run.sh) | Initialization race   |
| 21 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Unchecked Init | Gateway         | [run.sh](21/run.sh) | Missing pointer check |
| 22 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Unchecked Init | Gateway         | [run.sh](22/run.sh) | Missing pointer check |
| 23 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Unchecked Init | Gateway         | [run.sh](23/run.sh) | Expired pointer use   |
| 24 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Unchecked Init | Gateway         | [run.sh](24/run.sh) | Missing pointer check |
| 25 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Unchecked Init | PLC             | [run.sh](25/run.sh) | Missing initialization|
| 26 | [P2IM](../02-comparison-with-state-of-the-art/P2IM)              | Unchecked Init | Reflow Oven     | [run.sh](26/run.sh) | Missing pointer check |
| 27 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Security       | utasker_USB     | [run.sh](27/run.sh) | OOB write to USB buf  |
| 28 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Security       | Thermostat      | [run.sh](28/run.sh) | Stack buffer overflow |
| 29 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Security       | RF_Door_Lock    | [run.sh](29/run.sh) | Stack buffer overflow |
| 30 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Security       | uEmu.GPSTracker | [run.sh](30/run.sh) | Unconstrained alloca  |
| 31 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Security       | uEmu.GPSTracker | [run.sh](31/run.sh) | Unchecked parsing     |
| 32 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Security       | XML_Parser      | [run.sh](32/run.sh) | Double free           |
| 33 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Security       | XML_Parser      | [run.sh](33/run.sh) | Stack buffer overflow |
| 34 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Security       | XML_Parser      | [run.sh](34/run.sh) | NULL pointer deref    |
| 35 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Security       | XML_Parser      | [run.sh](35/run.sh) | Format String         |
| 36 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Unchecked Init | 6LoWPAN_Receiver| [run.sh](36/run.sh) | Missing error handling|
| 37 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Unchecked Init | 6LoWPAN_Sender  | [run.sh](37/run.sh) | Missing error handling|
| 38 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Unchecked Init | RF_Door_Lock    | [run.sh](38/run.sh) | Recursion in init error handling |
| 39 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Unchecked Init | 3DPrinter       | [run.sh](39/run.sh) | Missing initialization|
| 40 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Unchecked Init | utasker_MODBUS  | [run.sh](40/run.sh) | Missing initialization|
| 41 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Unchecked Init | utasker_MODBUS  | [run.sh](41/run.sh) | Missing initialization|
| 42 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Unchecked Init | utasker_MODBUS  | [run.sh](42/run.sh) | Missing initialization|
| 43 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Unchecked Init | Zepyhr_SocketCan| [run.sh](43/run.sh) | Missing error handling|
| 44 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | Unchecked Init | Zepyhr_SocketCan| [run.sh](44/run.sh) | Initialization race   |
| 45 | [uEmu](../02-comparison-with-state-of-the-art/uEmu)              | False Positive | utasker_USB     | [run.sh](45/run.sh) | Hardware assumption   |
| 46 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | Security       |                 | [run.sh](46/run.sh) | CVE-2020-10064        |
| 47 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | Security       |                 | [run.sh](47/run.sh) | CVE-2020-10065        |
| 48 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | Security       |                 | [run.sh](48/run.sh) | CVE-2020-10066        |
| 49 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | Security       |                 | [run.sh](49/run.sh) | CVE-2021-3319         |
| 50 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | Security       |                 | [run.sh](50/run.sh) | CVE-2021-3320         |
| 51 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | Security       |                 | [run.sh](51/run.sh) | CVE-2021-3321         |
| 52 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | Security       |                 | [run.sh](52/run.sh) | CVE-2021-3322         |
| 53 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | Security       |                 | [run.sh](53/run.sh) | CVE-2021-3323         |
| 54 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | Security       |                 | [run.sh](54/run.sh) | CVE-2021-3329         |
| 55 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | Security       |                 | [run.sh](55/run.sh) | CVE-2021-3330         |
| 56 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | False Positive |                 | [run.sh](56/run.sh) | Zephyr omitted watchdog check |
| 57 | [Zephyr](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples)            | False Positive |                 | [run.sh](57/run.sh) | Zephyr omitted radio frame size check |
| 58 | [Contiki-NG](../03-fuzzing-new-targets/contiki-ng/prebuilt_samples)        | Security       |                 | [run.sh](58/run.sh) | CVE-2020-12140        |
| 59 | [Contiki-NG](../03-fuzzing-new-targets/contiki-ng/prebuilt_samples)        | Security       |                 | [run.sh](59/run.sh) | CVE-2020-12141        |
| 60 | [Contiki-NG](../03-fuzzing-new-targets/contiki-ng/prebuilt_samples)        | Security       |                 | [run.sh](60/run.sh) | HALucinator 2019 CVE  |
| 61 | [Contiki-NG](../03-fuzzing-new-targets/contiki-ng/prebuilt_samples)        | Security       |                 | [run.sh](61/run.sh) | HALucinator 2019 CVE  |

## Groundtruth
Within a `fuzzware-project` that results from a `fuzzware pipeline` run, we can find crashing inputs in the regular afl crash directory under `main*/fuzzers/fuzzer*/crashes/id*`. We can replay these crashes by using the `fuzzware replay` utility. A sample invocation of `fuzzware replay` for a crash which shows the crash context is:

```
fuzzware replay -v main003/fuzzers/fuzzer1/crashes/id:000000*
```
This prints the crash reason, as well as the crashing register state to stdout. For examples of how to replay a crashing input outside the directory, also see the [CVE reproduction POCs](../03-fuzzing-new-targets/zephyr-os/prebuilt_samples/CVE-2020-10065/POC/run.sh).

Note that many bugs give an attacker high degrees of control over the crash context. This means that based on fuzzing input, the same bug may lead to very different crash contexts. For example, consider a buffer overflow in the global data section which corrupts operating system-internal data structures (such as task structs, timer pointers, and driver state structures). Based on the exact corruption and interrupt context switch timings relative to the corruption, the same bug may lead to very different crashing states. For example, a task switch after the corruption may operate on a corrupted kernel struct and crash in the kernel scheduling logic, a handler of an external interrupt may use a corrupted driver state struct after the corruption occurred, and crash in the ISR, and so on. At the same time, two different bugs which both corrupt the data section may cause similar-looking crashing states.

## Test Procedure
The experiment was performed manually based on the output of the fuzzing runs from the previous experiments.
1. Run fuzzers (`fuzzware pipeline`) for each target sample, followed by crash context generation (`fuzzware genstats crashcontexts`). See the previous experiments for resulting `fuzzware-project` directories.
2. Refer to `fuzzware-project/stats/crash_contexts.txt`. Replay the crashing inputs from previous fuzzing runs. Any crashes can be found in `fuzzware-project*/main*/fuzzers/fuzzer*/crashes` of the different targets.
3. Manual step: Perform a manual root cause analysis of the crashes.
