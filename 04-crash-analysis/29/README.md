# RF_Door_Lock
This crash occurs due to a stack-based buffer overflow in `set_code`, where user input is read into a small stack buffer.

The crash itself occurs in the function epilogue of `set_code` while trying to restore the stack frame.

From looking at the emulator output, we see the following crash context dump:
```
Basic Block: addr= 0x0000000000000448 (lr=0x2109)
        >>> Read: addr= 0x20007fe8[SP:+0000] size=4 data=0xfdffffff (pc 0x0000044a)
        >>> Read: addr= 0x20007fec[SP:-0004] size=4 data=0x00000400 (pc 0x0000044a)
Basic Block: addr= 0x0000000000000400 (lr=0x2109)
Execution failed with error code: 10 -> Invalid instruction (UC_ERR_INSN_INVALID)

==== UC Reg state ====
r0: 0x000000dd
r1: 0x000000dd
r2: 0x00000000
r3: 0x00000000
r4: 0xfdffffff
r5: 0x00000000
r6: 0x00000000
r7: 0x00000000
r8: 0x00000000
r9: 0x00000000
r10: 0x1fff8000
r11: 0x00000000
r12: 0x2000001e
lr: 0x00002109
pc: 0x00000400
xpsr: 0x60000000
sp: 0x20007ff0
other_sp: 0x00000000
```
pc `0x0000000000000448` corresponds to the function epilogue of `set_code`.

As we can see, the restored link register has an even value (although for thumb mode, the address would have to be uneven to be valid). This tells us that the restored return address is corrupted.

We can validate this assumption by checking the corresponding function prologue (the last invocation of set_code):

```
Basic Block: addr= 0x0000000000000410 (lr=0x499)
        >>> Write: addr= 0x20007fd8[SP:+0018] size=4 data=0x000000ff (pc 0x00000410)
        >>> Write: addr= 0x20007fdc[SP:+0014] size=4 data=0x20000f68 (pc 0x00000410)
        >>> Write: addr= 0x20007fe0[SP:+0010] size=4 data=0x20000f67 (pc 0x00000410)
        >>> Write: addr= 0x20007fe4[SP:+000c] size=4 data=0x000000ff (pc 0x00000410)
        >>> Write: addr= 0x20007fe8[SP:+0008] size=4 data=0x00000000 (pc 0x00000410)
        >>> Write: addr= 0x20007fec[SP:+0004] size=4 data=0x00000499 (pc 0x00000410)
```

For the stack push operation of the `set_code` prologue, we see that while storing to the frame, the link register `lr` is stored to `0x20007fec` with the value `0x00000499`.

Compared to the originally saved stack frame, this differs in the least significant byte (at address `0x20007fec`).

Checking back for writes to the corrupted address `0x20007fec`, we find the following.
```
Basic Block: addr= 0x000000000000042e (lr=0x212d)
        >>> Read: addr= 0x0000000000000458 size=4 data=0x2000000f (pc 0x00000436)
        >>> Write: addr= 0x20007fec[SP:-0014] size=1 data=0x00000000 (pc 0x00000438)
```

This write at `pc=0x00000438` corresponds to the line terminator newline-to-NULL byte overwrite in `set_code`. This signifies a stack buffer out-of-bounds write.