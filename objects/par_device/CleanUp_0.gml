// Return a module held from inventory before destroying the device.
if (instance_exists(selected_module) && selected_module.inventory_origin >= 0) inventory_return(id);
// Switching devices and restarting the room also remove all their parts.
for (var i = 0; i < array_length(children); ++i)
    if (instance_exists(children[i])) instance_destroy(children[i]);
