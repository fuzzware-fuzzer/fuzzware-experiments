# Analyzing the Crash
The crash occurs in the L2CAP `input` implementation as the data section as well as the stack has been corrupted by an out-of-bounds memcpy.

The overwrite itself was triggered by an unchecked length argument to `memcpy` in `input_l2cap_frame_flow_channel`.

> **Note**
> To replay the inputs in this directory, you may need to use the initial version of `fuzzware-emulator` and rebuild fuzzware. For instructions, see [here](https://github.com/fuzzware-fuzzer/fuzzware-experiments/tree/main/04-crash-analysis).

## Trace-based Bug Triaging without known Bug
To analyze the crash without knowing the bug a-priory, we can inspect the debug output of the emulator run:

```
./run.sh > log.txt
```

Inspecting log.txt:
```
Basic Block: addr= 0x0000000000205c4c (lr=0x205b29)
        >>> Read: addr= 0x2000350c[SP:+0000] size=4 data=0x00000000 (pc 0x00205c4e)
        >>> Read: addr= 0x20003510[SP:-0004] size=4 data=0x00000000 (pc 0x00205c4e)
        >>> Read: addr= 0x20003514[SP:-0008] size=4 data=0x00000000 (pc 0x00205c4e)
        >>> Read: addr= 0x20003518[SP:-000c] size=4 data=0x00000000 (pc 0x00205c4e)
        >>> Read: addr= 0x2000351c[SP:-0010] size=4 data=0x00000000 (pc 0x00205c4e)
        >>> Read: addr= 0x20003520[SP:-0014] size=4 data=0x00000000 (pc 0x00205c4e)
        >>> Read: addr= 0x20003524[SP:-0018] size=4 data=0x00000000 (pc 0x00205c4e)
        >>> [ 0x00000000 ] INVALID FETCH: addr= 0x0000000000000000
Execution failed with error code: 8 -> Invalid memory fetch (UC_ERR_FETCH_UNMAPPED)

==== UC Reg state ====
r0: 0x200016d2
r1: 0x200106b5
r2: 0x80000000
r3: 0x00000004
r4: 0x00000000
r5: 0x00000000
r6: 0x00000000
r7: 0x00000000
r8: 0x00000000
r9: 0x00000000
r10: 0x00000000
r11: 0x00000000
r12: 0x200016d2
lr: 0x00205b29
pc: 0x00000000
xpsr: 0x20000000
sp: 0x20003528
other_sp: 0x00000000
```

We see that firmware code tries to jump to address 0 (`pc: 0x00000000`). From the last reads just before the crash we see that multiple NULL values have been read at address `0x00205c4e`.

Inspecting the firmware code, we see that the address of the memory read corresponds to the following instructions:
```
.text:00205C4C                 ADD     SP, SP, #0x14
.text:00205C4E                 POP.W   {R4-R9,PC}
```
This represents the function epilogue of the `input`, where different values which have previously been stored on the stack are restored. 

Following previous writes to address `0x2000350c`, we find:
```
Basic Block: addr= 0x000000000020aa92 (lr=0x205b29)
        >>> Write: addr= 0x200034fc[SP:-0004] size=4 data=0x00000000 (pc 0x0020aa92)
        >>> Read: addr= 0x200024e4[SP:+1014] size=4 data=0x00000000 (pc 0x0020aa94)
        >>> Write: addr= 0x20003500[SP:-0008] size=4 data=0x00000000 (pc 0x0020aa96)
        >>> Read: addr= 0x200024e8[SP:+1010] size=4 data=0x00000000 (pc 0x0020aa98)
        >>> Write: addr= 0x20003504[SP:-000c] size=4 data=0x00000000 (pc 0x0020aa9a)
        >>> Read: addr= 0x200024ec[SP:+100c] size=4 data=0x00000000 (pc 0x0020aa9c)
        >>> Write: addr= 0x20003508[SP:-0010] size=4 data=0x00000000 (pc 0x0020aa9e)
        >>> Read: addr= 0x200024f0[SP:+1008] size=4 data=0x00000000 (pc 0x0020aaa0)
        >>> Write: addr= 0x2000350c[SP:-0014] size=4 data=0x00000000 (pc 0x0020aaa2)
        >>> Read: addr= 0x200024f4[SP:+1004] size=4 data=0x00000000 (pc 0x0020aaa4)
        >>> Write: addr= 0x20003510[SP:-0018] size=4 data=0x00000000 (pc 0x0020aaa6)
```
This writes occurs within `memcpy` (pc: 0x0020aaa2), with a call return to `lr=0x205b29`. 

This return address corresponds to returning from the last memcpy of the following sequence:

```
        chan = &l2cap_channels[v3];
        ...

        memcpy(&len, v0, sizeof(len));
        memcpy(&chan->rx_buffer.sdu_length, v0 + 4, sizeof(chan->rx_buffer.sdu_length));
        v7 = len - 2;
        memcpy(&chan->rx_buffer, v0 + 6, (unsigned __int16)(len - 2));
        // ############ Return Address ############
        chan->rx_buffer.current_index = v7;
```

As we can see, the `len` variable is read and used as size for the `memcpy` operation without bounds checks. This leads to an out-of-bounds write into the channel object. As the `l2cap_channels` is located in the global data section, and the application stack memory is located at higher addresses (growing towards the data section), both the global data section as well as application stack get corrupted by this memcpy, leading to the corrupted stack frame.