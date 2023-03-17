# Analyzing the Crash
The crash occurs in `bt_recv->net_buf_put(&_data_ram_start.rx_queue, buf)->k_queue_append_list->z_handle_obj_poll_events` as the global data section which includes `_data_ram_start.rx_queue` has been overwritten.

The overwrite itself was triggered by an unchecked length argument to `net_buf_simple_add_mem`.

> **Note**
> To replay the inputs in this directory, you may need to use the initial version of `fuzzware-emulator` and rebuild fuzzware. For instructions, see [here](https://github.com/fuzzware-fuzzer/fuzzware-experiments/tree/main/04-crash-analysis).

## Interactive Bug Triaging with known Bug
To interactively see this, set a breakpoint in net_buf_simple_add_mem and observe the large argument:
```
./run.sh -b net_buf_simple_add_mem
```

Check the length argument register (third argument: `r2`) and continue execution until `net_buf_simple_add_mem` shows a large argument (after two continuations, the large-sized copy occurs):

```
ipdb> uc.regs.r2
4
ipdb> c
ipdb> uc.regs.r2
4
ipdb> c
ipdb> uc.regs.r2
0x6464
```

## Trace-based Bug Triaging without known Bug
To analyze the crash without knowing the bug a-priory, we can also follow the memory write log to find the initial corruption. After seeing the crash cause:

```
Basic Block: addr= 0x000000000800b63e (lr=0x800af2f)
        >>> Read: addr= 0x0000000020002f74 size=4 data=0x00000000 (pc 0x0800b640)
Basic Block: addr= 0x000000000800b646 (lr=0x800af2f)
        >>> [ 0x0800b646 ] INVALID READ: addr= 0x0000000000000000 size=4 data=0x0000000000000000
Execution failed with error code: 6 -> Invalid memory read (UC_ERR_READ_UNMAPPED)
```

We can realize that that the read from `0x0000000020002f74` represents an address within the data section which is supposed to contain a pointer. As it does not, we can see further up the trace why the global variable has been overwritten.

Following this logic, we find the following write:
```
Basic Block: addr= 0x000000000800894c (lr=0x8001355)
        >>> Read: addr= 0x20000d12[SP:-008e] size=1 data=0x00000000 (pc 0x0800894c)
        >>> Write: addr= 0x0000000020002f74 size=1 data=0x00000000 (pc 0x08008950)
```
This occurs within `memcpy` (pc: 0x0800894c), which is called originating from `net_buf_simple_add_mem`.