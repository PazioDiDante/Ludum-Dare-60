input_update();
global.dt = min(delta_time * 0.000001, 0.05);
if (input_pressed(Action.Debug)) global.debug_enabled = !global.debug_enabled;
if (input_pressed(Action.Restart) && global.debug_enabled) { room_restart(); exit; }
if (!window_has_focus() && global.mode == GameMode.Play) {
    global.mode = GameMode.Pause;
    menu_index = 0;
}
if (!window_has_focus()) exit;
if (input_pressed(Action.Pause)) {
    if (global.mode == GameMode.Play) { global.mode = GameMode.Pause; menu_index = 0; }
    else if (global.mode == GameMode.Pause) global.mode = GameMode.Play;
    exit;
}
if (global.mode == GameMode.Menu) {
    if (input_pressed(Action.Confirm)) global.mode = GameMode.Play;
} else if (global.mode == GameMode.Pause) {
    var change = input_pressed(Action.Down) - input_pressed(Action.Up);
    menu_index = (menu_index + change + 3) mod 3;
    if (input_pressed(Action.Confirm)) {
        switch (menu_index) {
            case 0: global.mode = GameMode.Play; break;
            case 1: room_restart(); break;
            case 2: global.mode = GameMode.Menu; break;
        }
    }
}
if (game_running()) global.notice_time = max(0, global.notice_time - global.dt);
