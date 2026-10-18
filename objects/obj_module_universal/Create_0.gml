event_inherited();
scrap_cost = 4; // Assembly cost; recycler returns half.

module_name = "Universal block";
interaction_label = module_name;
drop_weight = 1;
module_color = make_color_rgb(120, 150, 215);

// Placeholder shape: edit cells and ports here; no separate sprite is required.
shape = [["LR_1"]];

stats.energy = 1;
stats.heat = -1;
stats.stability = 1;
stats.weight = 1;
stats.efficiency = 0;
stats.accuracy = 0;
stats.wear = 0;
stats.speed = 0;
