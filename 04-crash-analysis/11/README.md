# CNC
The crash occurs as `printFloat` considers, but does not bounds check the decimal precision (`settings.decimal_places`), leading to out-of-bounds writes on the stack.

User input is used in function `settings_store_global_setting` (which is called from `protocol_execute_line`) to set `settings.decimal_places` without bounds checks.

In the given POC, the following write causes `settings.decimal_places` to be set to a large value (`0x50 == 80`)
```
Basic Block: addr= 0x0000000008004f84 (lr=0x8004f85)
        >>> Read: addr= 0x0000000008005150 size=4 data=0x20000ebc (pc 0x08004f88)
        >>> Write: addr= 0x0000000020000ef9 size=1 data=0x00000050 (pc 0x08004f8a)
```

Later, the setting is used in `printFloat` and corrupts stack memory:
```
Basic Block: addr= 0x000000000800392c (lr=0x800392d)
        >>> Write: addr= 0x2001ff97[SP:-0018] size=4 data=0x00000000 (pc 0x0800392e)
        >>> Read: addr= 0x0000000008003a04 size=4 data=0x20000ebc (pc 0x08003930)
        >>> Read: addr= 0x0000000020000ef9 size=1 data=0x00000050 (pc 0x08003932)
        >>> Write: addr= 0x2001ffdb[SP:-005c] size=1 data=0x0000002e (pc 0x0800393e)
```