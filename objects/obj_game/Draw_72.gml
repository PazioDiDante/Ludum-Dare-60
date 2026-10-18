// Clear the previous frame before background layers and ordinary Draw events.
// spr_table is transparent outside the tabletop; those pixels must be cleared too.
draw_clear(c_black);
