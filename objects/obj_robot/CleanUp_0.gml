if(instance_exists(target_device)) instance_destroy(target_device);
if(instance_exists(target_module)) instance_destroy(target_module);
if(instance_exists(board_device)) instance_destroy(board_device);
for(var i=0;i<array_length(outputs);++i)
    if(instance_exists(outputs[i])) instance_destroy(outputs[i]);
