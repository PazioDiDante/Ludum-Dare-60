event_inherited();
scrap_cost = 2; // Assembly cost; recycler returns half.

// Configuration for this module type. Edit all values here.
module_name = "Battery";
interaction_label = module_name;
drop_weight = 2; // Relative drop frequency; 0 disables drops.
stats.energy = 3;
stats.weight = 1;
stats.heat = 2;
stats.stability = -2;
module_color = make_color_rgb(190, 150, 60);

// 0 = empty, 1 = body; "L_1" / "R_1" specify port directions and type.
// spr_battary: 32x16 pixels = two 16x16 grid cells.
shape = [["L_1", "R_1"]];

stats.efficiency = 0;
stats.accuracy = 0;
stats.wear = 0;
stats.speed = 0;
