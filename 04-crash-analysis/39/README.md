# uEmu.3Dprinter
The crash occurs as a USBLIB entry at `0x2000057C` is not properly initialized (NULL) in the interrupt handler `_irq_usb_lp_can_rx0`.

Upon revisiting this, the type of this bug could be argued in different directions. An MMIO-derived index is used in the operation, and restricted via bitmask `0xf`. Depending on how we want to view this, the firmware does not initialize all possible entries, or relies on a specific hardware behavior, or exposes itself to risk via a misbehaving device.
