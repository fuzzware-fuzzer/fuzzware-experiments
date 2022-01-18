# RF_Door_Lock
This crash occurs due to an infinite recursion which can occur in case an assertion is raised during initialization of the serial interface. The infinite recursion is caused for the combination of the following two reasons:
1. as an assertion requires the serial interface to be initialized
2. and at the same time, serial interface initialization can trigger an assertion via GPIO PIN functions as well

The recursion is triggered repeatedly for every time serial interface initialization fails.

This recursion causes the stack too overflow into the global data section, causing a corruption of global variables, which in turn causes a crash.

## Details
Crash message
```
Basic Block: addr= 0x000000000000114a (lr=0x709)
        >>> Read: addr= 0x20000f00[SP:+00a0] size=4 data=0x00007002 (pc 0x0000114a)
        >>> Read: addr= 0x0000000000007006 size=4 data=0xf002fa23 (pc 0x0000114c)
Basic Block: addr= 0x0000000000001152 (lr=0x709)
        >>> Write: addr= 0x0000000000007022 size=4 data=0x0000006d (pc 0x00001152)
        >>> [ 0x00001152 ] INVALID Write: addr= 0x0000000000007022 size=4 data=0x000000000000006d
Execution failed with error code: 12 -> Write to write-protected memory (UC_ERR_WRITE_PROT)

==== UC Reg state ====
r0: 0x20000efc
r1: 0x0000006d
r2: 0x23000000
r3: 0x00007002
r4: 0x00000001
r5: 0x000000c4
r6: 0x20000efc
r7: 0x00007003
r8: 0x00007003
r9: 0x00007002
r10: 0x00002580
r11: 0x00000000
r12: 0x00000000
lr: 0x00000709
pc: 0x00001152
xpsr: 0x01000000
sp: 0x20000fa0
other_sp: 0x00000000
```

At `0x20000f00`, a global stdio struct is located. We can find a write here:
```
Basic Block: addr= 0x000000000000512c (lr=0x37fb)
        >>> Write: addr= 0x20000eec[SP:+0024] size=4 data=0x0000007f (pc 0x0000512c)
        >>> Write: addr= 0x20000ef0[SP:+0020] size=4 data=0x20000228 (pc 0x0000512c)
        >>> Write: addr= 0x20000ef4[SP:+001c] size=4 data=0x0000ffff (pc 0x0000512c)
        >>> Write: addr= 0x20000ef8[SP:+0018] size=4 data=0x00007003 (pc 0x0000512c)
        >>> Write: addr= 0x20000efc[SP:+0014] size=4 data=0x00007003 (pc 0x0000512c)
        >>> Write: addr= 0x20000f00[SP:+0010] size=4 data=0x00007002 (pc 0x0000512c)
```
This is a stack push of `svfprintf_r`.

Looking at this further, we can find recursive assert calls.

The call chain is mbed_assert_internal->mbed_error_printf->mbed_error_vfprintf->vsnprintf->vsnprintf_r->svfprintf_r

The initial assertion is triggered by `pin_function`, where the following condition is not met:
```
mbed_assert_internal("(*obj->reg_ack & obj->ack_mask) == obj->req_val", 0x887F, 58);
```
The entry pc value which signals the assertion failure is pc = `00000E4C`.

The issue now is that the assertion failure function requires an initialized serial interface. So the following is called:
```
void __fastcall mbed_error_vfprintf(const unsigned __int8 *a1, va_list a2)
{
  int v4; // r5
  int i; // r4
  int v6; // r1
  unsigned __int8 v7[144]; // [sp+0h] [bp-90h] BYREF

  core_util_critical_section_enter();
  v4 = vsnprintf(v7, 0x80u, a1, a2);
  if ( v4 > 0 )
  {
    if ( !stdio_uart_inited )
      serial_init((int *)&stdio_uart, 0x7003u, 0x7002u, stdio_uart_inited);
```

However, looking at serial_init:
```
void __fastcall serial_init(int *a1, unsigned int a2, unsigned int a3, int a4)
{
  unsigned int v7; // r0
  unsigned int v8; // r5
  _DWORD *v9; // r3

  pinmap_peripheral();
  pinmap_peripheral();
  pinmap_merge();
  v8 = v7;
  if ( v7 == -1 )
    mbed_assert_internal("uart != (UARTName)NC", 35097, 69);
  *a1 = (v7 >> 12) & 1;
  a1[1] = v7;
  pinmap_pinout(a2, PinMap_UART_TX);
```

And following `pinmap_pinout`:
```
void __fastcall pinmap_pinout(unsigned int a1, _DWORD *a2)
{
  if ( a1 != -1 )
  {
    while ( *a2 != -1 )
    {
      if ( a1 == *a2 )
      {
        pin_function(a1, a2[2]);
```

We see that this again calls the pin function, which itself can have an assertion fail.

This leads to recursive stack frames of `pin_function->mbed_assert_internal->mbed_error_printf->mbed_error_vfprintf->serial_init->pinmap_pinout->pin_function`.

This recursion can repetedly create `mbed_assert_internal` frames. This leads to the stack pointer moving into the data section, causing a corruption there during a function prologue's stack push.

As the end result, eventually the stdio structs in the global data section are corrupted, such that `serial_putc` crashes while trying to dereference a corrupted stdio ptr.