event_inherited();
is_generator=true;
device_name="Generator";
board_sprite=spr_generator_board;
board_mask_sprite=spr_generator_board;
module_min=0;module_max=0;screw_positions=[];
// The built-in core works without an external circuit. Wired modules modify it.
stats_base={energy:2,heat:0,stability:1,weight:0};
stats_min={stability:1};stats_max={};
running=true;
broken=false;burning=false;
repair_seconds=5;repair_remaining=0;
shutdown_reason="";
power_hint="";power_hint_remaining=0;power_hint_elapsed=0;
heat_failure_rate=0.01; // Hazard per second per positive heat unit.
failure_remaining=-ln(max(0.000001,random(1)));
device_build();
