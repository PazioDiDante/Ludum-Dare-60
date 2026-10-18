event_inherited();
is_order=true;campaign=true;
orders_apply(id,orders_tier2_definition());

// Requirements from balance_settings.json; edit this order here.
stats_base = {energy:0, heat:0, stability:0, weight:0, efficiency:0, accuracy:0, wear:0, speed:0};
stats_min = {energy:4, heat:0, stability:0, efficiency:1, speed:3};
stats_max = {energy:5, heat:3, stability:3, efficiency:3, speed:5};
device_name="Computer";
small_sprite=spr_computer_small;
board_sprite=spr_computer_board;board_mask_sprite=spr_computer_board;
cover_sprite=-1;
module_min=0;module_max=0;screw_positions=[];
device_build();device_stats_update(id);
