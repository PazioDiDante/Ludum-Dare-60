event_inherited();
scrap_cost = 6; // Assembly cost; recycler returns half.
module_name = "Productivity";
interaction_label = module_name;
unlock_after_orders = 3;
module_color = make_color_rgb(135, 195, 75);
// Temporary board footprint; values imported from the supplied balance copy.
shape = [["L_1", 1, 1], [0, 0, "D_1"]];
drop_weight = 1;
stats.energy = -2;
stats.heat = 0;
stats.stability = -3;
stats.weight = 3;
stats.speed = -1;
stats.efficiency = 4;
stats.accuracy = 0;
stats.wear = 0;
