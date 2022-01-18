# XML_Parser
WYCINWYC injected bug:
```
if ( len == 1224 )
    printf((const unsigned __int8 *)buffer);
```
This corresponds to basic block `0x0800B6CC` being hit in firmware code.

Running the following will confirm the hit:
```
./run.sh -b 0x0800B6CC
```

Different from the other crash triggers of this sample, just covering this location does not mean that firmware will crash. A format string has to contain operations which lead to an actual crash ("%n", for example).

In this case, `%n` is indeed part of the input format string as we can see from the crash location: `0x0800faac` (which corresponds to printf `if ( code == 'n' )` logic).

Note that crashing the firmware via this bug is way harder for the fuzzer to trigger than crashing the firmware via the other bugs. Thus, triggers of this bug are far and between (in our evaluation, we had two such crashes within 5 24-hour runs).

For an automated way to identify such occurrences among crashes within fuzzware project directories, we can use some scripting to generate basic block traces for the crashing inputs of runs. We can then filter the basic block coverage for each crash to find crashing samples that visit the format string parsing, but do not visit any one of the other crashing locations (see other README's for these addresses):

```
# First, generate traces:
```
(for i in fuzzware-project-run-0*/main*/fuzzers/fuzzer*/crashes/id*; do echo "mkdir -p $(dirname $i)/traces; fuzzware replay --bb-set-out=$(dirname $i)/traces/bbset_$(basename $i) $i"; done ) | xargs -I{} --max-procs 8 bash -c "{}"
```

# Finding crashes which exclude other triggers
1. Double free
grep -iL '800B6CC\|800B682\|800B6BA\|800B6A4' $(grep -ril 800B55A fuzzware-project-run-*/main*/fuzzers/fuzzer*/crashes/traces)

2. SBOF
grep -iL '800B55A\|800B6CC\|800B6BA\|800B6A4' $(grep -ril 800B682 fuzzware-project-run-*/main*/fuzzers/fuzzer*/crashes/traces)

3. NULL Pointer Deref
grep -iL '800B55A\|800B6CC\|800B682\|800B6A4' $(grep -ril 800B6BA fuzzware-project-run-*/main*/fuzzers/fuzzer*/crashes/traces)

4. Heap-Based Buffer Overflow
grep -iL '800B55A\|800B682\|800B6BA\|800B6CC' $(grep -ril 800B6A4 fuzzware-project-run-*/main*/fuzzers/fuzzer*/crashes/traces)

5 format string
grep -iL '800B55A\|800B682\|800B6BA\|800B6A4' $(grep -ril 800B6CC fuzzware-project-run-*/main*/fuzzers/fuzzer*/crashes/traces)
```