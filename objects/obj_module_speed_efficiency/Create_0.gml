event_inherited();
scrap_cost = 4; // Assembly cost; recycler returns half.
module_name = "Speed and efficiency";
interaction_label = module_name;
unlock_after_orders = 3;
module_color = make_color_rgb(80, 185, 215);
// Temporary board footprint; values imported from the supplied balance copy.
shape = [["L_2", 1, 0], [0, 1, "R_1"]];
drop_weight = 1;
stats.energy = -3;
stats.heat = 1;
stats.stability = 0;
stats.weight = 2;
stats.speed = 2;
stats.efficiency = 2;
stats.accuracy = 0;
stats.wear = 0;
