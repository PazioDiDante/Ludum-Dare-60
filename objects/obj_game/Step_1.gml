input_update();
global.dt = min(delta_time * 0.000001, 0.05);
global.hover_target = noone;
if (instance_exists(active_device)) active_device.hover_port = undefined;
if (!window_has_focus()) {
    if (global.mode == GameMode.Play) { global.mode = GameMode.Pause; menu_index = 0; }
    pointer_ready = false;
    exit;
}
if (!input_down(Action.Primary) && !input_down(Action.Secondary) && !input_down(Action.Cancel)) pointer_ready = true;
screw_tick(id,global.dt);
// Campaign workpieces cannot be rerolled via restart.
campaign_tick(id,delta_time*0.000001);
generator_tick(id,global.dt);
robots_tick(id,global.dt);
if (input_pressed(Action.Pause)) {
    sfx_play(snd_click);
    if (global.mode == GameMode.Play) { global.mode = GameMode.Pause; menu_index = 0; }
    else if (global.mode == GameMode.Pause) global.mode = GameMode.Play;
    pointer_ready = false;
    exit;
}
var campaign_gx=device_mouse_x_to_gui(0),campaign_gy=device_mouse_y_to_gui(0);
if(pointer_ready && input_pressed(Action.Primary) && instance_exists(shop) && shop_click(shop,campaign_gx,campaign_gy)) exit;
if(pointer_ready && !input_pressed(Action.Primary) && input_pressed(Action.Secondary) && global.mode==GameMode.Menu) {
    // An open shop owns this area; right clicks must not reach covered robots.
    if(instance_exists(shop) && shop.open) exit;
    if(sfx_ui(robots_click(id,campaign_gx,campaign_gy,mb_right))) exit;
}
if(pointer_ready && input_pressed(Action.Primary) && sfx_ui(robots_click(id,campaign_gx,campaign_gy))) exit;
var gui_sound=global.mode==GameMode.Menu&&campaign_hit(campaign_gx,campaign_gy,[24,20,240,58])?snd_coin:snd_click;
if(pointer_ready && input_pressed(Action.Primary) && sfx_ui(campaign_gui_click(id,campaign_gx,campaign_gy),gui_sound)) exit;
// Menu mode is now the table: only a click on its device starts disassembly.
if (global.mode == GameMode.Menu) {
    if (pointer_ready && input_pressed(Action.Primary)) sfx_ui(table_click(mouse_x,mouse_y));
    exit; // Never pass the opening click to screws or modules.
}
if (global.mode == GameMode.Pause) {
    var count = 2;
    var change = input_pressed(Action.Down) - input_pressed(Action.Up);
    menu_index = (menu_index + change + count) mod count;
    var hovered = ui_item_at(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), count);
    if (hovered >= 0) menu_index = hovered;
    if (input_pressed(Action.Confirm) || (pointer_ready && hovered >= 0 && input_pressed(Action.Primary))) {
        sfx_play(snd_click);
        if (menu_index == 0) global.mode = GameMode.Play;
        else {
            show_table();
        }
        pointer_ready = false;
    }
    exit; // A menu click can never reach the world this frame.
}
global.notice_time = max(0,global.notice_time-global.dt);
if(sfx_ui(assembler_input(id,device_mouse_x_to_gui(0),device_mouse_y_to_gui(0)))) exit;
// Update a held module even over empty space; menu actions still take priority.
if (instance_exists(active_device)) board_drag_update(active_device,mouse_x,mouse_y);
// A draft wire can be cancelled anywhere, including over the pause button.
if (instance_exists(active_device) && !is_undefined(active_device.wire_start)
    && pointer_ready && (input_pressed(Action.Secondary) || input_pressed(Action.Cancel))) {
    wire_cancel(active_device);
    exit;
}
// Clickable pause button has priority over the world.
var gx = device_mouse_x_to_gui(0), gy = device_mouse_y_to_gui(0);
if (gx >= (room_width-120) && gx <= (room_width-24) && gy >= 16 && gy <= 50) {
    if (pointer_ready && input_pressed(Action.Primary)) {
        sfx_play(snd_click);
        global.mode = GameMode.Pause; menu_index = 0; pointer_ready = false;
    }
    exit;
}
// The assembler has no storage or board input; invisible inventory cannot be picked.
if(instance_exists(active_device) && (active_device.is_assembler||active_device.completed)) exit;
// A held module owns the click, even outside the device or over another module.
if (instance_exists(active_device) && instance_exists(active_device.selected_module)) {
    if (pointer_ready) {
        if (input_pressed(Action.Cancel)) board_cancel(active_device);
        else if (input_pressed(Action.Primary)) {
            if (inventory_slot(id,mouse_x,mouse_y) >= 0) sfx_action(storage_drop(id,mouse_x,mouse_y));
            else sfx_action(board_drop(active_device));
        }
        else if (input_pressed(Action.Secondary)) board_rotate(active_device);
    }
    exit; // Do not immediately pick up the module again on the same click.
}

// Storage slots consume clicks; a draft wire cannot pick up inventory items.
var slot = inventory_slot(id,mouse_x,mouse_y);
if (slot >= 0 && instance_exists(active_device)) {
    if (is_undefined(active_device.wire_start) && pointer_ready && input_pressed(Action.Primary)) inventory_pick(id,slot,mouse_x,mouse_y);
    exit;
}

// Contacts take priority over picking up the body of a module.
if (instance_exists(active_device)) {
    if (wire_input(active_device,mouse_x,mouse_y,
        pointer_ready && input_pressed(Action.Primary),
        pointer_ready && input_pressed(Action.Cancel),
        pointer_ready && input_pressed(Action.Secondary))) exit;
}
global.hover_target = pointer_find(mouse_x,mouse_y);
if (pointer_ready && instance_exists(global.hover_target)) {
    // If both buttons are pressed together, primary wins. Never dispatch twice.
    if (input_pressed(Action.Primary)) pointer_dispatch(global.hover_target,mb_left);
    else if (input_pressed(Action.Secondary)) pointer_dispatch(global.hover_target,mb_right);
    if (!instance_exists(global.hover_target)) global.hover_target = noone;
}
