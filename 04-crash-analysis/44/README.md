# Zepyhr_SocketCan
The crash occurs as a lock is released in `log_backend_enable` before the global context variable is initialized in `shell_log_backend_enable`. This leads to small time period where global context is unitialized.

The crash occurs in `shell_write` which is called from `shell_log_backend_output_func` (which in turn originates from `shell_uart_log_output` pointer table).