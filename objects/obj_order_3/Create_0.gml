event_inherited();
order_reward=150; // Coins awarded for completing this order.
is_order=true;campaign=true;device_name="Boombox";
board_mask_sprite = spr_drone_board;
board_sprite = spr_drone_board;
small_sprite = spr_drone_small;
cover_sprite = spr_drone_cover;
module_min=0;module_max=0;screw_positions=[];
// Device base stats and requirements for the assembled circuit.
// Edit these values in this Create event.
stats_base = {energy:0, heat:0, stability:0, weight:0};
stats_min = {energy:7,  stability:0};
stats_max = {energy:10, heat: 5, weight:12 ,stability:5};

device_build();
device_stats_update(id);
