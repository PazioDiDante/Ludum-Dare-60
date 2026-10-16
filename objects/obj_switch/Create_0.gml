event_inherited();
blocks_motion = true;
is_on = false;
debug_color = c_orange;
interaction_label = "Toggle test object";
interact = function(_actor) {
    if (!can_interact(_actor)) return false;
    is_on = !is_on;
    debug_color = is_on ? c_aqua : c_orange;
    global.notice = is_on ? "Test object: ON" : "Test object: OFF";
    global.notice_time = 2;
    if (global.debug_enabled) show_debug_message(global.notice);
    return true;
};
