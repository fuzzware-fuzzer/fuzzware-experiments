# uEmu.GPSTracker
The crash occurs while parsing an AT command to retrieve the `gsm_get_imei`. The parsing logic assumes the string `"AT+GSN\r\r\n"` to be present in the answer using `strstr`. However, parsing does not check whether the string is actually encountered.

As no check is performed on the `strstr` result, a NULL pointer is used in further processing, and a crash occurs in `strtok` which is called from `gsm_get_imei`.

Triggering this bug requires the fuzzer to pass the initial GSM setup stage, which includes AT command parsing. Most notably, `gsm_get_modem_status` expects a string `+CAP:` as an AT command. As this is based largely on string comparisons and AFL is not optimized for these comparisons, triggering this crash is highly non-deterministic. The crash triggered during our initial evaluation runs, but has not been reproduced by a fuzzer in our latest iteration.
