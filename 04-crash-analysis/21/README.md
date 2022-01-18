# P2IM Gateway
The variable `tx_callback` can be uninitialized in the call to `HAL_UART_TxCpltCallback`.
The vale is loaded and used as jump target without checking if it is null, resulting in a jump to address 0x0.
