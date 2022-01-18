# Thermostat
The crash occurs due to a stack-based buffer overflow in `get_new_temp`.

The crash itself is triggered `get_new_temp` itself, which corrupts its own stack frame and crashes during function return in the function epilogue.