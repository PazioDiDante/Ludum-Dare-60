if(global.mode==GameMode.Menu) campaign_table_draw(id);
if (instance_exists(active_device)) {
    if(active_device.is_assembler) {assembler_draw(id,active_device);exit;}
    // Display cached state only: drawing never recalculates the circuit.
    draw_set_font(circuit_font);
    draw_set_halign(fa_center); draw_set_valign(fa_top); draw_set_alpha(1);
    draw_set_color(active_device.circuit_connected ? c_lime : c_red);
    if(!active_device.is_recycler&&!active_device.is_assembler)
        draw_text(active_device.x,min(active_device.y+active_device.half_h+10,room_height-30),
            active_device.circuit_connected ? "Connected" : "Disconnected");
    draw_set_font(game_font_default()); draw_set_color(c_white); draw_set_halign(fa_left);
    if(!active_device.completed) storage_draw(id);
    if(!active_device.completed) board_ports_draw(active_device);
    if(!active_device.completed) wire_draw(active_device);
    if (instance_exists(active_device.selected_module)) module_draw_held(active_device.selected_module);
    if(active_device.is_recycler) recycler_board_draw(id,active_device);
    // The departing lid stays above modules, contacts and wires.
    if (active_device.visible && active_device.cover_open && active_device.cover_flight_progress < 1)
        device_cover_draw(active_device);
}
