event_inherited();
device_name = "Radio";
half_w = 200; half_h = 160;
source_cell_size = 16;
board_scale = 3;
screw_positions = [[-170,-130],[170,-130],[0,135]];
// Non-rectangular board with a notch and a hole.
board_shape = [
    [0,0,1,1,1,1,1,1,0,0],
    [0,1,1,1,1,1,1,1,1,0],
    [1,1,1,1,0,0,1,1,1,1],
    [1,1,1,1,0,0,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1],
    [0,1,1,1,1,1,1,1,1,0],
    [0,0,1,1,1,1,1,1,0,0]
];
module_pool = [obj_module_battery,obj_module_cooler,obj_module_coil];
module_min = 4; module_max = 8;
// Device base stats and requirements for the assembled circuit.
// Edit these values here; lab JSON does not override them.
stats_base = {energy:0, heat:0, stability:0, weight:0};
stats_min =  {energy:2, stability:3}
stats_max =  {}

device_build();
