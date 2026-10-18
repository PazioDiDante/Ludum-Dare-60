event_inherited();
scrap_cost = 2; // Assembly cost; recycler returns half.

// Configuration for this module type. Edit all values here.
module_name = "Cooler";
interaction_label = module_name;
drop_weight = 1; // Relative drop frequency; 0 disables drops.
stats.energy = -1;
stats.weight = 1;
stats.heat = -3;
stats.stability = 0;
module_color = make_color_rgb(75, 165, 210);

// 0 = empty, 1 = body; "L_1" / "R_1" specify port directions and type.
shape = [["U_1", 1], [1, "D_1"]];

stats.efficiency = 0;
stats.accuracy = 0;
stats.wear = 0;
stats.speed = 0;
