event_inherited();
scrap_cost = 4; // Assembly cost; recycler returns half.

module_name = "Balancer";
interaction_label = module_name;
drop_weight = 1;
module_color = make_color_rgb(65, 175, 160);

// Placeholder shape: edit cells and ports here; no separate sprite is required.
shape = [[0, 1, "R_1"], ["L_1", 1, 0]];

stats.energy = -3;
stats.heat = -3;
stats.stability = 3;
stats.weight = 2;
stats.efficiency = 0;
stats.accuracy = 0;
stats.wear = 0;
stats.speed = 0;
