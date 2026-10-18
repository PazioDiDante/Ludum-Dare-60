event_inherited();
scrap_cost = 2; // Assembly cost; recycler returns half.

// Configuration for this module type. Edit all values here.
module_name = "Coil";
interaction_label = module_name;
drop_weight = 1; // Relative drop frequency; 0 disables drops.
stats.energy = -2;
stats.weight = 1;
stats.heat = 0;
stats.stability = 5;
module_color = make_color_rgb(155, 100, 190);

// 0 = empty, 1 = body; "L_1" / "R_1" specify port directions and type.
shape = [[0, "U_1"], ["L_1", 1]];

stats.efficiency = 0;
stats.accuracy = 0;
stats.wear = 0;
stats.speed = 0;
