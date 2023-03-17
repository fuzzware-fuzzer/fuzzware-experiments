# Analyzing the Crash
The crash occurs in `add_to_waitq_locked` at `pc=0x0000af7c` while trying to give on a semaphore which is not initialized.

> **Note**
> To replay the inputs in this directory, you may need to use the initial version of `fuzzware-emulator` and rebuild fuzzware. For instructions, see [here](https://github.com/fuzzware-fuzzer/fuzzware-experiments/tree/main/04-crash-analysis).

The underlying issue is the assumption about the handling of the `mtu` handshake. The bluetooth stack, upon receiving an `mtu` value of zero, assumed that parts of the initialization (including the semaphore `le.pkts`) are postponed to another stage, which was however only included in certain build types (CONFIG_BT_BREDR). However, no check was performed that the BREDR component was actually included in the build.

While this particular issue has since been fixed, the given build seems to contain other crashes with seemingly similar, but different root causes. However, the analysis of further crashes is outside the scope of this analysis.

For the crash itself, we can use some manual debug hooks to see this effect:
```
z_impl_k_sem_take(0x20002f7c)
        >>> [ 0x0000af7c ] INVALID Write: addr= 0x0000000000000000 size=4 data=0x00000000200002b0
Execution failed with error code: 12 -> Write to write-protected memory (UC_ERR_WRITE_PROT)

==== UC Reg state ====
r0: 0x00000000
r1: 0x00000000
r2: 0x20000714
r3: 0x00000000
r4: 0x200002b0
r5: 0x20002f7c
r6: 0x200002b0
r7: 0x00000020
r8: 0x20003058
r9: 0x00000000
r10: 0x0000c11d
r11: 0x20002f98
r12: 0x00000000
lr: 0x00006c81
pc: 0x0000af74
xpsr: 0x61000000
sp: 0x20001768
other_sp: 0x20001c18
```

Here, we see that the semaphore at address `0x20002f7c` is being taken. This semaphore corresponds to `le.pkts`. At the same time, we can check that the initialization of this semaphore is never actually taken (the code initializing this semaphore in `bt_init` is `pc=0x00002CE4`).

We can do this either by setting a breakpoint which will not get hit:
```
./run.sh -b 0x00002CE4
```

... or by outputting its basic block set:
```
./run.sh --bb-trace-out=bb_trace.txt && grep -i 2CE4 bb_trace
```

... or by checking the debug output:
```
./run.sh -M -t
```