# Crash Analysis Disclaimer
Disclaimer: As we compiled an earlier version, the compiled sample contains many of the bugs of the later CVEs, and unrelated crashes may occur. One of the unrelated, but expected crashes occurs with a NULL pointer de-reference at 0x0040460e, which corresponds to the bug of CVE-2021-3320 (non-handled ACK frame packet type).

> **Note**
> To replay the inputs in this directory, you may need to use the initial version of `fuzzware-emulator` and rebuild fuzzware. For instructions, see [here](https://github.com/fuzzware-fuzzer/fuzzware-experiments/tree/main/04-crash-analysis).

# Analyzing the Crash
The crash occurs during an interrupt context switch in `z_arm_pendsv`, where an already corrupted data section leads to a crashing interrupt context restore.

The overwrite itself is triggered by an underflowed packet size, which results in a large-sized `memmove` call, which was invoked by `ieee802154_reassemble->net_6lo_uncompress->(get_ihpc_inlined_size|net_buf_simple_tailroom|net_buf_simple_add)`.

To observe this large copy operation, we can set a breakpoint at `memmove` and check its `size` argument (third argument, register `r2`). We do this via:

```
./run.sh -b memmove
```

```
ipdb> uc.regs
Unicorn Registers:
----------------
r0: 0x2000a585
r1: 0x2000a569
r2: 0xfffffffb
r3: 0x0000fffb
r4: 0x0000000c
r5: 0x0000001c
r6: 0x2000a585
r7: 0x20007c80
r8: 0x00006a6a
r9: 0x200073e0
r10: 0x00000000
r11: 0x00000000
r12: 0x2000a55b
sp: 0x20005ac8
lr: 0x00407987
pc: 0x0040daba
fpscr: 0x00000000
basepri: 0x00000000
primask: 0x00000000
control: 0x00000002
```