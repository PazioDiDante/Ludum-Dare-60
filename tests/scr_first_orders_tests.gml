// Isolated Room1 suite: artwork, actual board masks, physical solutions and delivery.
function first_order_assert(_ok,_label) {
    if(!_ok) throw "FIRST_ORDERS_FAILURE: "+_label;
    global.first_order_passes++;
}
function first_order_capture(_g,_name) {
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    if(instance_exists(_g.active_device)) {
        var d=_g.active_device;with(d) event_perform(ev_draw,0);
        with(par_module) if(device==d&&visible) event_perform(ev_draw,0);
    }
    with(_g) event_perform(ev_draw,0);
    campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    surface_reset_target();surface_save(sf,environment_get_variable("FIRST_ORDERS_OUTPUT")+"/"+_name+".png");surface_free(sf);
}
function first_order_assemble_tier2(_g,_d) {
    campaign_open(_g,_d);
    var types=[obj_module_battery,obj_module_battery,obj_module_stabilizer,obj_module_adapter,obj_module_little_speed,obj_module_adapter];
    var previous=board_port_reference(_d,0);
    for(var i=0;i<array_length(types);++i) {
        var item=instance_create_depth(0,0,-10,types[i]);item.device=_d;
        var placed=false;
        for(var turn=0;turn<4&&!placed;++turn) {
            for(var row=0;row<_d.rows&&!placed;++row) for(var col=0;col<_d.cols&&!placed;++col) placed=board_place(item,col,row);
            if(!placed) {item.shape=orders_rotate(item.shape);item.rotation_steps=(item.rotation_steps+1) mod 4;}
        }
        first_order_assert(placed,"tier-two module physically fits new board");array_push(_d.children,item);
        var ports=[];
        for(var row=0;row<array_length(item.shape);++row) for(var col=0;col<array_length(item.shape[row]);++col) {
            var dirs=cell_directions(item.shape[row][col]);
            for(var p=0;p<array_length(dirs);++p) array_push(ports,port_reference(item,col,row,dirs[p]));
        }
        var previous_type=struct_exists(previous,"board_port")?_d.board_port_types[previous.board_port]:previous.port_type;
        var incoming=ports[0].port_type==previous_type?0:1;
        first_order_assert(wire_connect(_d,previous,ports[incoming]),"real matching-type chain through new board");
        previous=ports[1-incoming];
    }
    first_order_assert(wire_connect(_d,previous,board_port_reference(_d,1)),"tier-two chain closes actual contacts");
    device_stats_update(_d);
    first_order_assert(_d.requirements_met&&_d.current_stats.speed==2,"new order meets real tier-two stats with speed");
}
function first_orders_tests() {
    global.first_order_passes=0;global.order_test_passes=0;
    var g=instance_find(obj_game,0),s=g.order_system;
    first_order_assert(g.order_index==0&&g.order_device.object_index==obj_order,"startup begins with first order");
    var types=[obj_order,obj_order_2,obj_order_3,obj_order_4,obj_order_5,obj_order_6];
    var names=["Microwave","Player","Drone","Telephone","Game","Computer"],rewards=[100,125,150,300,300,300];
    var thumbnails=[spr_microwave_small,spr_player_small,spr_drone_small,spr_telephone,spr_game_small,spr_computer_small];
    var boards=[spr_microwave_board,spr_player_board,spr_drone_board,spr_telephone_board,spr_game_board,spr_computer_board];
    var covers=[spr_microwave_cover,spr_player_cover,spr_drone_cover,-1,-1,-1];
    while(s.cache.phase=="count") lab_count_step(s.cache,1000);
    for(var i=0;i<array_length(types);++i) {
        var d=g.order_device;
        first_order_assert(d.object_index==types[i]&&d.device_name==names[i],"authored order identity "+string(i));
        first_order_assert(d.small_sprite==thumbnails[i]&&d.board_sprite==boards[i]&&d.board_mask_sprite==boards[i]&&d.cover_sprite==covers[i],"all supplied artwork assigned "+string(i));
        first_order_assert(d.order_reward==rewards[i],"original reward retained "+string(i));
        first_order_assert(d.cover_open&&array_length(d.board_ports)==2&&d.placed_modules==0,"empty order has two actual contacts "+string(i));
        var expected=board_shape_from_sprite(boards[i],16),occupied=0;
        for(var row=0;row<d.rows;++row) for(var col=0;col<d.cols;++col) if(d.board_shape[row][col]) occupied++;
        first_order_assert(json_stringify(expected)==json_stringify(d.board_shape)&&occupied>0,"actual mask matches new board artwork "+string(i));
        campaign_table(g);first_order_capture(g,"order-"+string(i+1)+"-table");
        var rect=campaign_order_rect();
        first_order_assert(campaign_table_click(g,rect[0]+48,rect[1]+48)&&g.active_device==d,"thumbnail opens corresponding order "+string(i));
        if(i<3) {
        // Packing must use this order's own mask, including the player's holes.
        s.cells=d.rows*d.cols;s.fits=[];s.placements=[];
        for(var t=0;t<array_length(s.model.items);++t) {
            var probe=instance_create_depth(0,0,0,s.model.items[t].object_type);
            array_push(s.placements,orders_placements(probe.shape,d.board_shape));instance_destroy(probe);
        }
        var counts=order_test_recipe(s,d);order_test_assemble(g,d,counts);
        } else {
            var definition=orders_tier2_definition();
            first_order_assert(d.order_tier==2&&json_stringify(d.stats_min)==json_stringify(definition.min)&&json_stringify(d.stats_max)==json_stringify(definition.max),"new authored order retains tier-two bounds");
            first_order_assemble_tier2(g,d);
        }
        first_order_assert(d.requirements_met,"new board can physically satisfy original requirements "+string(i));
        first_order_capture(g,"order-"+string(i+1)+"-board");
        var cash=g.money;first_order_assert(campaign_complete(g)&&g.money==cash+rewards[i]&&g.order_index==i+1,"real delivery advances and pays once "+string(i));
        first_order_assert(!campaign_complete(g)&&g.order_index==i+1,"repeat delivery cannot skip next order "+string(i));
    }
    first_order_assert(g.order_index==6&&g.order_device.object_index==obj_big_order&&g.order_device.order_tier==2&&g.order_device.order_reward==300,"seventh order continues the generic tier-two flow");
    show_debug_message("FIRST_ORDERS_RESULT passes="+string(global.first_order_passes)+" physical_solution_passes="+string(global.order_test_passes)+" failures=0");game_end();
}
