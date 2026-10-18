event_inherited();
scrap_cost = 4; // Assembly cost; recycler returns half.

// Configuration for this module type. Edit all values here.
module_name = "Accumulator";
interaction_label = module_name;
drop_weight = 1; // Relative drop frequency; 0 disables drops.
stats.energy = 8;
stats.weight = 5;
stats.heat = 5;
stats.stability = -3;
module_color = make_color_rgb(200, 95, 70);

// 0 = empty, 1 = body; "L_1" / "R_1" specify port directions and type.
shape = [["U_1", 1, "U_1"], [1, 1, 1]];

stats.efficiency = 0;
stats.accuracy = 0;
stats.wear = 0;
stats.speed = 0;
