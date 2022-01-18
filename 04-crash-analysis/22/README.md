# P2IM Gateway
The variable `hi2c->pBuffPtrc` can be uninitialized in the call to `I2C_ITError`.
This member is guarded by `hi2c->XferCount`, but the value is not checked before accessing the buffer pointer.
