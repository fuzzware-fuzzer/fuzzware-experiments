# P2IM Gateway
In the method `setPinState` of `FirmataClass`, the range for the `pin` argument is not checked.
This can lead to an out of bounds write in the data section.
In the given input one of the elements in `uart_handlers` is overwirtten.
Later this value is passed to the function `HAL_UART_GetState`, resulting in a crash.
