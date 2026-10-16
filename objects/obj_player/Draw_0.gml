event_inherited();
if (global.debug_enabled) {
    draw_set_color(c_yellow);
    draw_circle(x, y, interaction_range, true);
    if (instance_exists(interaction_target))
        draw_line(x, y, interaction_target.x, interaction_target.y);
    draw_set_color(c_white);
}
