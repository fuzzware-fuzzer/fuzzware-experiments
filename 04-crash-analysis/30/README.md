# uEmu.GPSTracker
`USB_SendStringDescriptor` (mangled symbol `_ZL24USB_SendStringDescriptorPKhi`) takes a string as well as a length. To prepare a buffer with metadata, the function allocates a buffer on the stack (via `SUB.W   SP, SP, R3` at pc `0x8425E`). However, no check is performed on the size of the string to be copied.

When `USB_SendStringDescriptor` is called from `USB_ISR`, USB-provided data is interpreted as a length without bounds checks. For a large size value, `USB_SendStringDescriptor` will allocate more stack space than available. On the embedded system, this means that the stack grows into the global data section, and then corrupts global variables. This leads to crashes of different variations.

The given crash occurs in `UARTClass::read` due to corrupted rx buffer metadata.

There are different known crash contexts that are manifestations of the same bug. While not exhaustive, previously seen lr values are:
1. 0x00084415
2. 0x00083e07
3. 0x00080a35
4. 0x00083d87
5. 0x00083c11