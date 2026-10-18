event_inherited();
scrap_cost = 2; // Assembly cost; recycler returns half.

// Configuration for this module type. Edit all values here.
module_name = "Stabilizer";
interaction_label = module_name;
drop_weight = 1; // Relative drop frequency; 0 disables drops.
stats.energy = -1;
stats.weight = 0;
stats.heat = 1;
stats.stability = 4;
module_color = make_color_rgb(100, 180, 105);

// 0 = empty, 1 = body; "L_1" / "R_1" specify port directions and type.
shape = [["L_1", 1, "R_1"]];

stats.efficiency = 0;
stats.accuracy = 0;
stats.wear = 0;
stats.speed = 0;
