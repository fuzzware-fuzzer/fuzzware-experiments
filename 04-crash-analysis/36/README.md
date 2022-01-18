# 6LoWPAN_Receiver
The crash occurs due to an improper handling of initialization errors: The firmware logic does not check the return value of `spi_init` (which can set `module->hw = 0`).

This leads to a NULL pointer dereference, resulting in a crash.