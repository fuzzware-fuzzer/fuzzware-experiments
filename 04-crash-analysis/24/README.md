# P2IM Gateway
HAL_UART_IRQHandler does not check whether its UART instance is actually initialized, leading to a NULL pointer de-reference.

Upon re-inspecting the crash reason, the source of the UART instance state seems to stem from a previous OOB access (the Gateway security issue).

```
Basic Block: addr= 0x0000000008008820 (lr=0x8008821)
        >>> Read: addr= 0x000000000800882c size=4 data=0x200006bc (pc 0x08008820)
        >>> Read: addr= 0x00000000200006c0 size=4 data=0x00000000 (pc 0x08008822)
Basic Block: addr= 0x00000000080069f0 (lr=0x8008829)
        >>> Write: addr= 0x20004fb8[SP:+0008] size=4 data=0x00000002 (pc 0x080069f0)
        >>> Write: addr= 0x20004fbc[SP:+0004] size=4 data=0x08008829 (pc 0x080069f0)
        >>> [ 0x080069f4 ] INVALID READ: addr= 0x0000000000000000 size=4 data=0x0000000000000000
```
Line `>>> Read: addr= 0x00000000200006c0 size=4 data=0x00000000 (pc 0x08008822)` shows the access of the UART instance pointer.

Following previous writes to address `0x00000000200006c0` back in the log, we can see the following:
```
Basic Block: addr= 0x0000000008002fc6 (lr=0x8000737)
        >>> Write: addr= 0x00000000200006c0 size=4 data=0x00000000 (pc 0x08002fc8)
```
The `pc` for this write corresponds to `firmata::FirmataClass::setPinState`, which suffers from an OOB write issue.

We have been unaware of this fact during our initial assessment. The crash itself could be avoided by an additional check in the ISR, however, so we keep this POC here.
