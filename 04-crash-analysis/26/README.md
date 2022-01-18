# P2IM Reflow Oven
In the function `HAL_UART_TxCpltCallback` the pointer `tx_callback` can be uninitialized, resulting in a branch to address 0.
The callback will be set in `uart_attach_tx_callback` which is called by `HardwareSerial::write` if a check calling `serial_tx_active` returns false.
Thus the _read_ callback is only set if the serial has already been written before.
However an interrupt handler for receiving from UART can be triggered before the firmware had the chance to write to the UART, triggering the invalid callback.

