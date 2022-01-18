# XML_Parser
WYCINWYC injected double free bug:
```
if ( len == 1221 )
{
    ((void (*)(void))parser->m_mem.free_fcn)();
    parser->m_mem.free_fcn(v17);
}
```
This corresponds to basic block `0x0800B55A` being hit in firmware code.

Running the following will confirm the hit:
```
./run.sh -b 0x0800B55A
```