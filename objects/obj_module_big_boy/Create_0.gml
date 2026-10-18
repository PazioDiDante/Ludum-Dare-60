event_inherited();
scrap_cost = 8; // Assembly cost; recycler returns half.
module_name = "Big boy";
interaction_label = module_name;
unlock_after_orders = 3;
module_color = make_color_rgb(170, 125, 220);
// Temporary board footprint; values imported from the supplied balance copy.
shape = [["L_2", 1, 1], [1, 1, "R_2"]];
drop_weight = 0.5;
stats.energy = -4;
stats.heat = -1;
stats.stability = 2;
stats.weight = 5;
stats.speed = 2;
stats.efficiency = 3;
stats.accuracy = 0;
stats.wear = 0;
