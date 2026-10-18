// Update after pointer movement and module placement; drawing stays read-only.
sfx_screw_update(id);
sfx_solder_update(id);
sfx_ready_update(id);
device_visual_tick(global.dt);
if(instance_exists(active_device)) wire_visual_update(active_device,global.dt);
