# utasker_USB
The crash occurs due to a buffer OOB write of USB-supplied data.

Data read from the receive FIFO in `fnExtractFIFO` is written to a too small buffer.

This leads to an out-of-bounds write in the data section, and a corruption of the `usb_endpoints` pointers.

As a result, a crash occurs in `fnSendUSB_data` while accessing a corrupted endpoint pointer.
