# Zepyhr_SocketCan
The crash occurs due to the fact that in case device initialization functions fail, the device's API pointer is set to NULL. At the same time, later code does not properly check the API pointer for being non-NULL.

Here, the crash occurs in `z_impl_can_attach_msgq`, as `dev->driver_api` has not been initialized.

The underlying issue has since been fixed by Zephyr, for example in commit: https://github.com/zephyrproject-rtos/zephyr/commit/aac9e2c5e33d1b9d17ca9a7a392e890f91475c38#diff-64740803f7fd17de4e55e4bfec0aea28c71bfd71762a5188df5deb479003641aL250