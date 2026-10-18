event_inherited();
order_reward=100; // Coins awarded for completing this order.
is_order=true;campaign=true;device_name="Microwave";
board_mask_sprite = spr_microwave_board;
board_sprite = spr_microwave_board;
small_sprite = spr_microwave_small;
cover_sprite = spr_microwave_cover;
module_min=0;module_max=0;screw_positions=[];
// Device base stats and requirements for the assembled circuit.
// Edit these values here; lab JSON does not override them.
stats_base = {energy:0, heat:0, stability:0, weight:0};
stats_min = {energy:5, heat:0, stability:0};
stats_max = {energy:10, heat:4, weight:12};

device_build();
device_stats_update(id);
