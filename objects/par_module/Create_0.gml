event_inherited();
device = noone; // Assigned by the device generator immediately after Create.
can_interact = function() { return interaction_enabled && !in_inventory && instance_exists(device); };
shape = [[1]];
// Shared properties. A child Create event calls event_inherited() first,
// then sets its own values. All module stats are stored in stats.
module_name = "Module";
drop_weight = 1;
scrap_cost = 2; // Scrap to assemble; recycling returns exactly half this value.
unlock_after_orders = 0; // Number of delivered big orders required for random drops.
catalog_revision = 1; // One-time lab catalog migration; not a gameplay stat.
stats = {
    energy: 0,
    weight: 0,
    heat: 0,
    stability: 0,
    speed: 0,
    efficiency: 0,
    accuracy: 0,
    wear: 0
};
catalog_index = -1;
removing = false;
in_inventory = false;
inventory_origin = -1; // Return slot while picked up from inventory.
debug_infinite_source = false; // Debug catalog specimen, never removed on pickup.
debug_inventory_source = noone; // A disposable copy taken from a catalog specimen.
connections = []; // { module, own_port, other_port } for each connection.
circuit_powered = false; // Cached by device_stats_update; Draw never walks wires.
grid_col = 0; grid_row = 0;
grab_col = 0; grab_row = 0;
preview_col = 0; preview_row = 0;
drop_valid = true;
rest_depth = depth;
rotation_steps = 0;
rest_rotation = 0;
rest_shape = shape;
module_color = make_color_rgb(75,135,195);
interaction_label = "Module";
primary_hint = "Select / place";
secondary_hint = "Rotate clockwise";
hit_test = function(_px,_py) {
    var sx = floor((_px-x)/device.cell_size);
    var sy = floor((_py-y)/device.cell_size);
    if (sy < 0 || sy >= array_length(shape)) return false;
    if (sx < 0 || sx >= array_length(shape[sy])) return false;
    return shape[sy][sx] != Cell.Empty;
};

on_primary = function() {
    if (instance_exists(device.selected_module)) return board_drop(device);
    return board_pick(id,mouse_x,mouse_y);
};
on_secondary = function() { return board_rotate(device); };
