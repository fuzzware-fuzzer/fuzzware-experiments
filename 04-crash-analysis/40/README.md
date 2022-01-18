# utasker_MODBUS
The crash occurs as it is not ensured that all `SerialHandle` entries are initialized before they are being used.

The crash itself happens in `fnFlush`, where a serial handle is being flushed which has not yet been initialized.