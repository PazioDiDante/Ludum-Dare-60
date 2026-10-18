event_inherited();
is_order=true;campaign=true;
orders_apply(id,orders_tier2_definition());

// Same requirements as order 4, with efficiency instead of speed.
stats_base = {energy:0, heat:0, stability:0, weight:0, efficiency:0, accuracy:0, wear:0, speed:0};
stats_min = {energy:3, heat:0, stability:0, efficiency:2};
stats_max = {energy:7, heat:5, stability:5, efficiency:5};
device_name="Game";
small_sprite=spr_game_small;
board_sprite=spr_game_board;board_mask_sprite=spr_game_board;
cover_sprite=-1;
module_min=0;module_max=0;screw_positions=[];
device_build();device_stats_update(id);
