# P2IM Gateway
The function `pwm_start` uses stack-based timer object and registers it with `HAL_TIM_PWM_Init`, which saves it in the `timer_handles` array.
Once `pwm_start` returns, the reference becomes invalid, but will still be called by the timer subsystem.
For the given input, the value of `irqHandle` will be overwritten with 0x12.
This results in a crash, once the corrupted address is called.
