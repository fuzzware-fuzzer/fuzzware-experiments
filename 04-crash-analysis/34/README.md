# XML_Parser
WYCINWYC injected bug:
```
case 1223:
    buffer = 0;
    break;
```
This corresponds to basic block `0x0800B6BA` being hit in firmware code.

Running the following will confirm the hit:
```
./run.sh -b 0x0800B6BA
```