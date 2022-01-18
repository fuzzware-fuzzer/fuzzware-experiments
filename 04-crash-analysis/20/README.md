# P2IM Robot
The hardware time interrupt is enabled before the value of `I2C_Read_Reg` is initialized.
If the interrupt is triggered before initialization the function `mpu6050_update` will branch to the function pointer.
This results in a crash, as no memory is mapped at address zero.
