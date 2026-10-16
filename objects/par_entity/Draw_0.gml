draw_set_alpha(1);
draw_set_color(debug_color);
// Base sprites preview the geometry in the Room Editor; runtime color can change.
var base_preview = sprite_index == spr_base_wall || sprite_index == spr_base_player
    || sprite_index == spr_base_switch;
if (sprite_exists(sprite_index) && !base_preview) draw_self();
else draw_rectangle(x-half_w, y-half_h, x+half_w, y+half_h, false);
if (global.debug_enabled) {
    draw_set_color(c_lime);
    draw_rectangle(x-half_w, y-half_h, x+half_w, y+half_h, true);
}
draw_set_color(c_white);
