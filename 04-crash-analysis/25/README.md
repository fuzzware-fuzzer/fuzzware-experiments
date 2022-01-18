# P2IM PLC
The cause of this crash is Uninitialized memory after `Reset_Handler` has been called.
Function pointer `tx_callback` in `HAL_UART_TxCpltCallback` is 0 and will crash the device.
The callback will be set in `uart_attach_tx_callback` which is called by `HardwareSerial::write` if a check calling `serial_tx_active` returns false.
Thus the _read_ callback is only set if the serial has already been written before.
However an interrupt handler for receiving from UART can be triggered before the firmware had the chance to write to the uart, triggering the invalid callback.

