// Run only in an isolated copy. Exercise real placements, typed wires and delivery.
function release_assert(_ok,_label) {
    if(!_ok) throw "RELEASE_FAILURE: "+_label;
    global.release_passes++;
}
function release_assemble(_g,_d,_types) {
    campaign_open(_g,_d);
    var previous=board_port_reference(_d,0);
    for(var i=0;i<array_length(_types);++i) {
        var item=instance_create_depth(0,0,-10,_types[i]);item.device=_d;
        var placed=false;
        for(var turn=0;turn<4&&!placed;++turn) {
            for(var row=0;row<_d.rows&&!placed;++row) for(var col=0;col<_d.cols&&!placed;++col)
                placed=board_place(item,col,row);
            if(!placed) {item.shape=orders_rotate(item.shape);item.rotation_steps=(item.rotation_steps+1) mod 4;}
        }
        release_assert(placed,"recipe fits the actual board");array_push(_d.children,item);
        var ports=[];
        for(var row=0;row<array_length(item.shape);++row) for(var col=0;col<array_length(item.shape[row]);++col) {
            var dirs=cell_directions(item.shape[row][col]);
            for(var p=0;p<array_length(dirs);++p) array_push(ports,port_reference(item,col,row,dirs[p]));
        }
        var previous_type=struct_exists(previous,"board_port")?_d.board_port_types[previous.board_port]:previous.port_type;
        var incoming=ports[0].port_type==previous_type?0:1;
        release_assert(wire_connect(_d,previous,ports[incoming]),"matching port types form a working chain");
        previous=ports[1-incoming];
    }
    release_assert(wire_connect(_d,previous,board_port_reference(_d,1)),"chain closes between both board contacts");
    device_stats_update(_d);
    release_assert(_d.requirements_met,"real powered stats satisfy order requirements");
}
function release_tests() {
    global.release_passes=0;
    var g=instance_find(obj_game,0);
    release_assert(g.money==50&&g.scrap==0&&array_length(g.table_devices)==1,"normal starting economy and free donor");
    release_assert(!variable_instance_exists(g,"debug_tools")&&!variable_global_exists("debug_enabled"),"debug state removed");
    release_assert(!variable_instance_exists(g,"order_system"),"unused background order generator removed");
    var stock=0;for(var i=0;i<array_length(g.inventory);++i) if(instance_exists(g.inventory[i])) stock++;
    release_assert(stock==0,"inventory has no free debug catalog");
    var types=[obj_order,obj_order_2,obj_order_3,obj_order_4,obj_order_5,obj_order_6,obj_big_order,obj_big_order];
    var names=["Microwave","Player","Boombox","Telephone","Game","Computer","Big order / Tier 2","Big order / Tier 2"];
    var rewards=[100,125,150,300,300,300,300,300];
    var recipes=[
        [obj_module_stabilizer,obj_module_double_battery],
        [obj_module_battery,obj_module_stabilizer,obj_module_accumulator,obj_module_universal],
        [obj_module_battery,obj_module_coil,obj_module_double_battery],
        [obj_module_battery,obj_module_battery,obj_module_stabilizer,obj_module_adapter,obj_module_little_speed,obj_module_adapter],
        [obj_module_stabilizer,obj_module_accumulator,obj_module_adapter,obj_module_big_boy,obj_module_adapter],
        [obj_module_accumulator,obj_module_universal,obj_module_universal,obj_module_adapter,obj_module_little_speed,obj_module_big_boy,obj_module_adapter],
        [obj_module_battery,obj_module_battery,obj_module_stabilizer,obj_module_adapter,obj_module_little_speed,obj_module_adapter],
        [obj_module_battery,obj_module_battery,obj_module_stabilizer,obj_module_adapter,obj_module_little_speed,obj_module_adapter]
    ];
    for(var i=0;i<array_length(types);++i) {
        var d=g.order_device;
        release_assert(d.object_index==types[i]&&d.device_name==names[i]&&d.order_reward==rewards[i],"authored order identity and reward "+string(i));
        release_assert(d.cover_open&&array_length(d.board_ports)==2&&d.placed_modules==0,"order starts empty with two board contacts");
        release_assemble(g,d,recipes[i]);
        var cash=g.money;
        release_assert(campaign_complete(g)&&g.money==cash+rewards[i]&&g.order_index==i+1,"delivery advances and pays exactly once");
        release_assert(!campaign_complete(g)&&g.order_index==i+1,"repeat delivery cannot skip next order");
    }
    show_debug_message("RELEASE_RESULT passes="+string(global.release_passes)+" failures=0");game_end();
}
