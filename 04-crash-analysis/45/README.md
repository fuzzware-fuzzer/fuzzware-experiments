# utasker_USB
The crash occurs due to an invalidated hardware assumption about the bounds of the number of USB channel indices.

An out-of-bounds access into an array of USB structs.

A mmio variable read at MMIO 0x50000020 constrained to [0, 0xf] at 0x0800dab8 is used in a call to the function `fnProcessInput` as the first parameter.

In `fnProcessInput`, the index is used as the third argument in the call to `fnUSB_handle_frame`
- call to `fnProcessInput` function @ 0x0800dbde
- call to `fnUSB_handle_frame` @ 0x0800d8de

In `fnUSB_handle_frame` the index is further passed to `fnEndpointData` as the first paramter @ 0x08010086.
Subsequently the index is used without a bounds check on a static ram array.