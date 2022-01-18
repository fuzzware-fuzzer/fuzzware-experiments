# utasker_MODBUS
The crash occurs as it is not ensured that all `SerialHandle` entries are initialized before they are being used.

The crash itself happens in `fnDriver`, where a NULL function pointer is dereferenced.