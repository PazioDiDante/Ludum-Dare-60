event_inherited();
is_order=true;campaign=true;
orders_apply(id,orders_tier2_definition());
device_name="Telephone";
small_sprite=spr_telephone;
board_sprite=spr_telephone_board;board_mask_sprite=spr_telephone_board;
cover_sprite=-1; // Orders start open; no separate cover asset was supplied.
module_min=0;module_max=0;screw_positions=[];
device_build();device_stats_update(id);
