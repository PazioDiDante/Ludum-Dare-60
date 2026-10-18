event_inherited();
device_name = "Remote control";
source_cell_size = 16;
board_scale = 3;
screw_positions = [[-190,-135],[190,-135],[-190,135],[190,135]];
board_shape = [
    [1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1]
];
// To derive the board from your art, import a sprite and uncomment:
board_mask_sprite = spr_remote_board; // Collision Mask -> Precise
board_sprite = spr_remote_board;      // Same sprite may be used for art.
cover_sprite = asset_get_index("spr_remote_cover"); // Optional art; use the standard cover when absent.
module_pool = [obj_module_battery,obj_module_cooler];
module_min = 3; module_max = 6;
// Device base stats and requirements for the assembled circuit.
// Edit these values here; lab JSON does not override them.
stats_base = {energy:0, heat:0, stability:0, weight:0};
stats_min =  {energy:4}
stats_max =  {energy:6, weight:2}

device_build(); // Must be last: all configuration is now ready.
