draw_set_alpha(1); draw_set_font(-1);
draw_set_halign(fa_left); draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text(24, 16, "BASE PROJECT  /  neutral test room");
draw_text(24, 38, "WASD / arrows: move    E / Space: interact    Esc / P: pause    F1: debug");
var p = instance_find(obj_player, 0);
if (game_running() && instance_exists(p)) {
    var target = p.interaction_target;
    if (instance_exists(target)) draw_text(24, 64, "[E / Space] " + target.interaction_label);
}
if (global.notice_time > 0) draw_text(560, 64, global.notice);
if (global.debug_enabled && instance_exists(p)) {
    draw_text(24, 116, "DEBUG | FPS: " + string(fps_real) + " | F5: reset");
    draw_text(24, 136, "x: " + string_format(p.x, 0, 2) + " y: " + string_format(p.y, 0, 2));
    draw_text(24, 156, "Interact down/pressed/released: " + string(input_down(Action.Interact))
        + "/" + string(input_pressed(Action.Interact)) + "/" + string(input_released(Action.Interact)));
}
if (global.mode != GameMode.Play) {
    draw_set_color(c_black); draw_set_alpha(0.8);
    draw_rectangle(240, 175, 720, 420, false);
    draw_set_alpha(1); draw_set_color(c_white);
    draw_set_halign(fa_center);
    if (global.mode == GameMode.Menu) {
        draw_text(480, 220, "GAMEMAKER BASE");
        draw_text(480, 270, "Enter - start / continue test");
        draw_text(480, 320, "No theme, objectives, art or sound.");
    } else {
        draw_text(480, 210, "PAUSED");
        var labels = ["Resume", "Reset test room", "Main menu"];
        for (var i = 0; i < array_length(labels); ++i) {
            draw_set_color(i == menu_index ? c_yellow : c_white);
            draw_text(480, 255 + i * 32, (i == menu_index ? "> " : "") + labels[i]);
        }
        draw_set_color(c_white);
        draw_text(480, 375, "Up / Down + Enter   |   Esc - resume");
    }
}
draw_set_halign(fa_left); draw_set_valign(fa_top);
draw_set_color(c_white); draw_set_alpha(1);
