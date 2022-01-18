# P2IM Heat Press
In the method `get_FC3` from `Modbus`, the bounds check is performed with user controlled data.
This allows an attacker to overwrite data following the `au16regs`.
```C
void Modbus::get_FC3()
{
    uint8_t u8byte, i;
    u8byte = 3;

    for (i=0; i< au8Buffer[ 2 ] /2; i++)
    {
        au16regs[ i ] = word(
                            au8Buffer[ u8byte ],
                            au8Buffer[ u8byte +1 ]);
        u8byte += 2;
    }
}
```

In the provided input the `port` field of the modbus struct is overwritten, resulting in a crash while loading the pointer.
For an attacker it would be possible to set the pointer to a location with controlled data and thus allows arbitrary control over the instruction pointer.
