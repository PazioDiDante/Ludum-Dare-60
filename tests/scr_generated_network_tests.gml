// Run generated_network_tests() in an isolated project copy.
function network_assert(_ok,_message) {
    if (!_ok) throw "GENERATED_NETWORK_FAILURE: "+_message;
    global.network_passes++;
}
function network_fixture(_shapes) {
    var d=instance_create_depth(850,375,0,par_device);
    d.module_min=0;d.module_max=0;d.board_shape=[[1,1,1,1,1,1,1,1]];
    with(d) device_build();
    for(var i=0;i<array_length(_shapes);++i) {
        var item=instance_create_depth(0,0,-10,par_module);
        item.device=d;item.shape=[[_shapes[i]]];item.stats={energy:1,weight:1,heat:0,stability:0};
        board_place(item,i,0);array_push(d.children,item);
    }
    device_wire_generated(d);return d;
}
function network_validate(_d) {
    for(var i=0;i<array_length(_d.wires);++i) {
        var w=_d.wires[i];
        network_assert(!is_undefined(port_current(w.a))&&!is_undefined(port_current(w.b)),"both wire endpoints exist");
        network_assert(port_device(w.a)==_d&&port_device(w.b)==_d&&w.a.module!=w.b.module,"wires stay inside donor and connect different owners");
        network_assert(wire_for_port(_d,w.a)==i&&wire_for_port(_d,w.b)==i,"one wire per contact");
        var sides=[w.a,w.b];
        for(var side=0;side<2;++side) {
            var matches=0,endpoint=sides[side];
            for(var j=0;j<array_length(endpoint.module.connections);++j) {
                var c=endpoint.module.connections[j];
                if(port_equal(c.own_port,endpoint)&&port_equal(c.other_port,sides[1-side])) matches++;
            }
            network_assert(matches==1,"connection is recorded once at each end");
        }
    }
}
function generated_network_tests() {
    global.network_passes=0;
    var g=instance_find(obj_game,0),kinds=[obj_remote,obj_radio];
    for(var kind=0;kind<2;++kind) for(var seed=0;seed<15;++seed) {
        random_set_seed(seed);
        var d=campaign_create_device(kinds[kind]);d.campaign=true;
        if(seed<2) d.campaign_loot_types=seed==0
            ?[obj_module_battery,obj_module_battery,obj_module_cooler,obj_module_stabilizer]
            :[obj_module_double_battery,obj_module_coil,obj_module_universal];
        d.open_cover();network_validate(d);
        network_assert(d.installed_count>0&&d.powered_count==d.installed_count,"all real donor modules receive power");
        network_assert(d.circuit_connected,"real donors have a closed circuit");
        network_assert(!d.user_wired&&!campaign_can_sell(g,d),"automatic wiring does not count as player repair");
        var wires=json_stringify(d.wires),count=instance_number(par_module);
        d.open_cover();device_wire_generated(d);
        network_assert(json_stringify(d.wires)==wires&&instance_number(par_module)==count,"reopening preserves existing wiring and loot");
        campaign_open(g,d);campaign_table(g);campaign_open(g,d);
        network_assert(json_stringify(d.wires)==wires,"table return preserves network");
        if(seed==0&&kind==0) {
            var target=surface_create(1280,720);surface_set_target(target);draw_clear(c_black);
            draw_sprite_stretched(spr_table,0,0,0,1280,720);
            with(d) event_perform(ev_draw,0);
            with(par_module) if(device==d) event_perform(ev_draw,0);
            board_ports_draw(d);wire_draw(d);
            surface_reset_target();surface_save(target,"generated-network-preview.png");surface_free(target);
        }
        var installed=d.installed_count;
        campaign_table(g);instance_destroy(d);
        network_assert(instance_number(par_module)==count-installed,"destroying donor leaves no generated parts");
    }
    var empty=network_fixture([]);
    network_assert(array_length(empty.wires)==0&&empty.powered_count==0,"empty donor stays empty");instance_destroy(empty);
    var noports=network_fixture([Cell.Solid]);
    network_assert(array_length(noports.wires)==0&&noports.powered_count==0,"portless module is safely skipped");instance_destroy(noports);
    var single=network_fixture([Cell.L,Cell.R,Cell.Solid]);network_validate(single);
    network_assert(single.powered_count==1&&!single.circuit_connected,"single-port-only donor still powers one module");instance_destroy(single);
    var partial=network_fixture([Cell.LR,Cell.L,Cell.R]);network_validate(partial);
    network_assert(partial.powered_count==1&&partial.circuit_connected,"limited ports keep a working circuit");instance_destroy(partial);
    var branch=network_fixture([Cell.LURD,Cell.L,Cell.R]);network_validate(branch);
    network_assert(branch.powered_count==3&&branch.circuit_connected,"spare trunk ports power single-port branches");
    var removed=branch.children[0];module_detach(removed);instance_destroy(removed);
    network_assert(array_length(branch.wires)==0&&branch.powered_count==0,"detaching trunk cleans all network wires");instance_destroy(branch);
    network_assert(array_length(g.generator.wires)==0&&array_length(g.order_device.wires)==0,"generator and empty order retain their setup");
    // Robot must detach the generated network before moving parts into storage.
    campaign_table(g);g.money=1000;shop_buy(g,"dismantle_robot");
    var robot=g.robots[array_length(g.robots)-1];robot_assign_power(g,robot);
    network_assert(robot_start(g,robot),"robot reserves donor");
    var donor=robot.target_device;donor.open_cover();var parts=[];
    for(var i=0;i<array_length(donor.children);++i) {
        var item=donor.children[i];
        if(instance_exists(item)&&item.object_index!=obj_screw) array_push(parts,item);
    }
    network_assert(donor.powered_count>0,"robot donor uses generated network");robot_finish(g,robot);
    for(var i=0;i<array_length(parts);++i)
        network_assert(instance_exists(parts[i])&&parts[i].in_inventory&&array_length(parts[i].connections)==0,"robot output has no stale wire connections");
    show_debug_message("GENERATED_NETWORK_RESULT passes="+string(global.network_passes)+" failures=0");game_end();
}
