While executing a CNC program, the firmware improperly validates the input program.

In `planner_recalculate->planner_recalculate_trapezoids`, `calculate_trapezoid_for_block` is called multiple times in a loop, based on the input program.

The situation is not checked where `block_buffer_tail == block_buffer_head`, where `block_buffer_head` is set in `mc_line->plan_buffer_line`.

This leads to a NULL pointer deref while accessing `next->entry_speed`, causing a crash in the firmware.