# P2IM Soldering Iron
This bug takes several steps to occur:
1. The function `HAL_I2C_Mem_Read` assigns a stack based buffer, from a function higher on the call stack, to the member `pBuffPtr` of the global I2C object. This reference is invalid once the function containing the buffer returns.
2. In another interrupt the function `MMA8652FC::getAxisReadings` calls, which then calls `FRToSI2C::Mem_Read`. It passes a stack based temporary buffer and the length of this buffer. Because in total six arguments are passed, the last two are stored on the stack, one of which is buffer length.
3. Inside of `FRToSI2C::Mem_Read` the hardware timer interrupt must be triggered before `HAL_I2C_Mem_Read` is called.
4. During handling of the interrupt the function `I2C_MasterReceive_BTF` is called. This function writes to `pBuffPtr` of the I2C object, which still points to the address set in step 1. But this address now contains the buffer length argument from step 2. The function will thus corrupt the argument and allows a buffer overflow of the stack buffer from `MMA8652FC::getAxisReadings`.
5. The return address from `MMA8652FC::getAxisReadings` is corrupted by the buffer overflow, giving an attacker arbitrary control over the instruction pointer. In the input, which was found by the fuzzer, the return address is invalid resulting in a crash.
