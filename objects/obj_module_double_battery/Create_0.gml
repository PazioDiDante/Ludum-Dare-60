event_inherited();
scrap_cost = 4; // Assembly cost; recycler returns half.

module_name = "Double battery";
interaction_label = module_name;
drop_weight = 1;
module_color = make_color_rgb(215, 170, 65);

// Placeholder shape: edit cells and ports here; no separate sprite is required.
shape = [["L_1", 1], [1, "R_1"]];

stats.energy = 6;
stats.heat = 3;
stats.stability = -3;
stats.weight = 2;
stats.efficiency = 0;
stats.accuracy = 0;
stats.wear = 0;
stats.speed = 0;
