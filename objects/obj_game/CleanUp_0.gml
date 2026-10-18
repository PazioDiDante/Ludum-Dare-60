
sfx_screw_stop(id);
sfx_solder_stop(id);
game_font_delete(circuit_font);

game_font_delete(ui_font);
if(instance_exists(shop)) instance_destroy(shop);
for(var i=0;i<array_length(robots);++i) if(instance_exists(robots[i])) instance_destroy(robots[i]);
if(instance_exists(generator)) instance_destroy(generator);
if(instance_exists(order_device)) instance_destroy(order_device);
for(var i=0;i<array_length(table_devices);++i) if(instance_exists(table_devices[i])) instance_destroy(table_devices[i]);
for(var i=0;i<array_length(inventory);++i) if(instance_exists(inventory[i])) instance_destroy(inventory[i]);
