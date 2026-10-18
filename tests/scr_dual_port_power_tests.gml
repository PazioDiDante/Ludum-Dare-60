function dual_power_assert(_ok,_message) {
    if(!_ok) throw "DUAL_PORT_POWER_FAILURE: "+_message;
    global.dual_power_passes++;
}
function dual_port_power_tests() {
    global.dual_power_passes=0;
    // Mirror the connection order to ensure neither contact is privileged.
    for(var start=0;start<2;++start) {
        var d=instance_create_depth(850,375,0,par_device);
        d.is_order=true;d.module_min=0;d.module_max=0;
        d.board_shape=[[1,1,1,1,1,1,1,1]];
        d.stats_min={energy:1};d.stats_max={};
        with(d) device_build();
        var parts=[];
        for(var i=0;i<4;++i) {
            var item=instance_create_depth(0,0,-10,par_module);
            item.device=d;item.shape=[[Cell.LURD]];
            item.stats={energy:i+1,heat:i+2,stability:i+3,weight:1};
            dual_power_assert(board_place(item,i,0),"place fixture module");
            array_push(d.children,item);array_push(parts,item);
        }
        var a=board_port_reference(d,start),b=board_port_reference(d,1-start);
        dual_power_assert(wire_connect(d,a,port_reference(parts[0],0,0,Cell.L)),"connect first contact");
        dual_power_assert(parts[0].circuit_powered&&d.powered_count==1&&d.current_stats.energy==1,"either contact powers a single branch immediately");
        dual_power_assert(!d.circuit_connected&&!d.requirements_met,"open branch cannot complete order");
        dual_power_assert(wire_connect(d,port_reference(parts[0],0,0,Cell.R),port_reference(parts[2],0,0,Cell.L)),"extend first branch");
        dual_power_assert(d.powered_count==2&&parts[2].circuit_powered&&d.current_stats.energy==4,"power propagates through open branch");
        dual_power_assert(wire_connect(d,b,port_reference(parts[1],0,0,Cell.R)),"connect opposite contact");
        dual_power_assert(d.powered_count==3&&parts[1].circuit_powered&&d.current_stats.energy==6&&d.current_stats.heat==9&&d.current_stats.stability==12,"disjoint branches both contribute all active stats");
        dual_power_assert(!parts[3].circuit_powered&&d.current_stats.weight==4,"isolated module contributes only weight");
        dual_power_assert(!d.circuit_connected&&!d.requirements_met,"two powered branches still need a connecting path");
        dual_power_assert(wire_connect(d,port_reference(parts[2],0,0,Cell.R),port_reference(parts[1],0,0,Cell.L)),"join branches");
        dual_power_assert(d.circuit_connected&&d.requirements_met&&d.powered_count==3&&d.current_stats.energy==6,"closed circuit counts each module once");
        wire_disconnect(d,array_length(d.wires)-1);
        dual_power_assert(!d.circuit_connected&&!d.requirements_met&&d.powered_count==3&&d.current_stats.energy==6,"splitting circuit retains power from both ends");
        wire_disconnect(d,wire_for_port(d,a));
        dual_power_assert(!parts[0].circuit_powered&&!parts[2].circuit_powered&&parts[1].circuit_powered&&d.powered_count==1&&d.current_stats.energy==2,"disconnecting one contact disables only its detached branch");
        wire_disconnect(d,wire_for_port(d,b));
        dual_power_assert(d.powered_count==0&&d.current_stats.energy==0&&d.current_stats.heat==0&&d.current_stats.stability==0&&d.current_stats.weight==4,"fully detached network loses active stats and preserves mass");
        // Both contacts on one module must also avoid duplicate traversal.
        wire_connect(d,a,port_reference(parts[1],0,0,Cell.L));
        wire_connect(d,b,port_reference(parts[1],0,0,Cell.R));
        dual_power_assert(d.circuit_connected&&d.powered_count==1&&d.current_stats.energy==2,"shared seed module counts once");
        instance_destroy(d);
    }
    show_debug_message("DUAL_PORT_POWER_RESULT passes="+string(global.dual_power_passes)+" failures=0");
}
