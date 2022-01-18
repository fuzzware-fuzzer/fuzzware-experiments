# XML_Parser
WYCINWYC injected stack-based BOF bug:
```
case 1222:
    memcpy(overflowable, s, 1222u);
    LOBYTE(v10) = puts(overflowable);
    return (char)v10;
```
This corresponds to basic block `0x0800B682` being hit in firmware code.

Running the following will confirm the hit:
```
./run.sh -b 0x0800B682
```