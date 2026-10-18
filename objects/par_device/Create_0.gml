event_inherited();
// Defaults. Each child overrides these and calls device_build() LAST in Create.
device_name = "Device";
half_w = 220; half_h = 160;
source_cell_size = 16; // Pixels per cell in the original sprite.
board_scale = 3;       // Desired enlargement; reduced automatically to fit the screen.
draw_scale = 1;        // Calculated by device_build().
cell_size = 16;        // Calculated screen/world size; do not configure directly.
screw_positions = [];
board_shape = [[1]];
board_mask_sprite = -1; // Optional precise collision mask; overrides board_shape.
board_sprite = -1;      // Optional visible PCB art, same canvas as mask.
cover_sprite = -1;      // Optional cover art, origin at the device centre.
small_sprite = -1;      // Thumbnail on the table; orders store it on each instance.
board_offset = [0,0];   // Board centre offset relative to the device.
module_pool = [obj_module_battery,obj_module_cooler];
module_min = 2; module_max = 4;
layout_seed = -1;       // -1: fresh random layout, >=0: reproducible layout.

campaign=false;is_order=false;completed=false;
campaign_loot_types=[]; // Fixed starter contents; empty uses the normal weighted loot.
is_generator=false;
is_recycler=false;robot_owner=noone;
is_assembler=false;
automation_owner=noone;
repair_price=40; // Sale price of a repaired small device.
user_wired=false; // Only manually connected wires count as player repair work.
order_reward=0; // The reward is set in the specific order Create event.
order_tier=1;
// Shared model for the remote, radio, drone and future devices.
stats_base = {energy:0, heat:0, stability:0, weight:0};
stats_min = {}; // A missing field means no requirement. Zero is an actual bound.
stats_max = {};
requirements_met=false;installed_count=0;powered_count=0;
current_stats={energy:0,weight:0,heat:0,stability:0};
children = [];
selected_module = noone;
wires = [];
circuit_connected = false; // True when board ports 0 and 1 are linked through modules.
circuit_check_count = 0; // Debug counter: only actual connection edits increment it.
board_ports = []; // Two fixed contacts, generated once when the cover opens.
board_port_types = [1,1]; // Set in a child device, e.g. [1,2] for different types.
board_ports_enabled=true;
connections = []; // Same connection records as modules.
wire_start = undefined;
wire_draft = undefined;
hover_port = undefined;
wire_snap_radius = 28; // Wire attachment snap radius in game pixels.
wire_pick_radius = 14; // Smaller first-click radius keeps small module centers accessible.
wire_mouse_x = 0; wire_mouse_y = 0;
cover_open = false;
// Cosmetic progress only: board coordinates and click targets stay fixed.
arrival_progress = 1; arrival_seconds = 0.35; arrival_offset = 20;
cover_flight_progress = 1; cover_flight_seconds = 0.65;
cover_flight_distance = 200; cover_flight_angle = -12;
if(!variable_instance_exists(id,"work_layout")) work_layout=false;
built = false;
remaining = 0;
requested_modules = 0; placed_modules = 0;
adapter_bonus_rolled=false;adapter_bonus_added=false;
interaction_label = device_name;
primary_hint = "Check cover";
open_cover = function() {
    if (cover_open) return;
    cover_open = true;
    if (array_length(screw_positions) > 0) {
        cover_flight_progress = 0;
    }
    interaction_label = device_name + " / board";
    primary_hint = "Place module";
    device_generate_modules();
    board_ports_generate(id);
    device_wire_generated(id);
    if (placed_modules < requested_modules)
        notice_show("Not enough room: placed " + string(placed_modules) + "/" + string(requested_modules) + " modules.");
    else notice_show("Pick up a module, move the mouse, click to place. RMB: rotate. Q/MMB: cancel.");
};

on_primary = function() { return board_drop(id); };
on_secondary = function() { return board_rotate(id); };
