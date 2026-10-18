function debug_inventory_assert(_ok,_label) {
    if(!_ok) throw "DEBUG_INVENTORY_FAILURE: "+_label;
    global.debug_inventory_passes++;
}
function debug_inventory_sources(_g) {
    var result=[];
    for(var i=0;i<array_length(_g.inventory);++i) {
        var item=_g.inventory[i];if(instance_exists(item)&&item.debug_infinite_source) array_push(result,item);
    }
    return result;
}
function debug_inventory_pick_source(_g,_source) {
    _g.inventory_page=_source.storage_page;
    var occupied_col=0,occupied_row=0,found=false;
    for(var row=0;row<array_length(_source.shape)&&!found;++row) for(var col=0;col<array_length(_source.shape[row])&&!found;++col)
        if(_source.shape[row][col]!=Cell.Empty) {occupied_col=col;occupied_row=row;found=true;}
    var px=_g.inventory_x+(_source.storage_col+occupied_col)*_g.inventory_size+4;
    var py=_g.inventory_y+(_source.storage_row+occupied_row)*_g.inventory_size+4;
    var slot=inventory_slot(_g,px,py);
    debug_inventory_assert(inventory_pick(_g,slot,px,py),"pick catalog specimen");
    return _g.active_device.selected_module;
}
function debug_inventory_place_first(_d,_item) {
    for(var row=0;row<_d.rows;++row) for(var col=0;col<_d.cols;++col) {
        if(!board_can_place(_item,col,row)) continue;
        _item.preview_col=col;_item.preview_row=row;return board_drop(_d);
    }
    return false;
}
function debug_inventory_capture(_g,_name) {
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    if(instance_exists(_g.active_device)) {
        var d=_g.active_device;with(d) event_perform(ev_draw,0);
        with(par_module) if(device==d&&visible) event_perform(ev_draw,0);
    }
    with(_g) event_perform(ev_draw,0);
    campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    surface_reset_target();surface_save(sf,environment_get_variable("ASSEMBLER_TEST_OUTPUT")+"/"+_name+".png");surface_free(sf);
}
function debug_inventory_tests() {
    global.debug_inventory_passes=0;
    var g=instance_find(obj_game,0),types=game_module_types(),sources=debug_inventory_sources(g);
    debug_inventory_assert(g.debug_tools&&g.money==1000&&g.scrap==50,"debug starting resources retained");
    debug_inventory_assert(g.order_index==0&&g.order_device.object_index==obj_order,"debug starts with microwave order one");
    debug_inventory_assert(array_length(sources)==array_length(types),"all sixteen module types available immediately");
    var initial_count=instance_number(par_module);inventory_debug_seed(g);
    debug_inventory_assert(instance_number(par_module)==initial_count,"catalog seeding is idempotent");
    campaign_open(g,g.order_device);
    for(var t=0;t<array_length(types);++t) {
        var source=sources[t];
        debug_inventory_assert(source.object_index==types[t]&&source.in_inventory&&!source.visible,"catalog type order and hidden storage "+string(t));
        var shape=json_stringify(source.shape),stats=json_stringify(source.stats);
        var copy=debug_inventory_pick_source(g,source);
        debug_inventory_assert(copy!=source&&copy.object_index==source.object_index&&!copy.debug_infinite_source&&copy.debug_inventory_source==source,"pickup creates separate usable module "+string(t));
        debug_inventory_assert(source.in_inventory&&!source.visible&&json_stringify(copy.stats)==stats&&json_stringify(copy.shape)==shape,"source remains and authored copy matches "+string(t));
        copy.stats.energy+=100;board_rotate(g.active_device);
        debug_inventory_assert(json_stringify(source.stats)==stats&&json_stringify(source.shape)==shape,"copy mutation and rotation never alter source "+string(t));
        debug_inventory_assert(board_cancel(g.active_device)&&!instance_exists(copy)&&source.in_inventory,"cancel discards copy and preserves specimen "+string(t));
    }
    debug_inventory_assert(instance_number(par_module)==initial_count,"repeated pickup/cancel leaves no physical copies behind");
    var d=g.active_device,source=sources[0],a=debug_inventory_pick_source(g,source);
    debug_inventory_assert(debug_inventory_place_first(d,a),"debug copy installs on real order board");
    var b=debug_inventory_pick_source(g,source);
    debug_inventory_assert(debug_inventory_place_first(d,b)&&a!=b&&a.device==d&&b.device==d,"same source supplies multiple real modules");
    debug_inventory_assert(array_length(debug_inventory_sources(g))==16&&source.in_inventory,"installation never consumes catalog");
    debug_inventory_assert(board_pick(a,a.x+4,a.y+4),"installed debug part can be picked again");
    var px=g.inventory_x+source.storage_col*g.inventory_size+4,py=g.inventory_y+source.storage_row*g.inventory_size+4;
    debug_inventory_assert(storage_drop(g,px,py)&&!instance_exists(a)&&source.in_inventory&&!instance_exists(d.selected_module),"return onto occupied catalog cell removes only copy");
    var found=false;for(var i=0;i<array_length(d.children);++i) if(d.children[i]==a) found=true;
    debug_inventory_assert(!found,"return removes installed child ownership");
    g.debug_tools=false;
    debug_inventory_assert(!campaign_debug_skip_order(g)&&g.order_index==0,"skip guarded when debug disabled");g.debug_tools=true;
    var pending=debug_inventory_pick_source(g,source),cash=g.money,scrap=g.scrap;
    var names=["Microwave","Player","Drone","Telephone","Game","Computer"];
    for(var order=0;order<6;++order) {
        d=g.order_device;
        debug_inventory_assert(g.order_index==order&&d.object_index==g.order_types[order]&&d.device_name==names[order],"authored order sequence "+string(order+1));
        if(order==0) board_cancel(d); // Capture the inventory with no held preview.
        debug_inventory_capture(g,"debug-order-"+string(order+1));
        if(order==0) pending=debug_inventory_pick_source(g,source);
        var button=campaign_skip_rect(g);
        debug_inventory_assert(campaign_gui_click(g,button[0]+8,button[1]+8)&&g.order_index==order+1&&!instance_exists(d),"skip button advances exactly one order "+string(order+1));
        debug_inventory_assert(g.active_device==g.order_device&&global.mode==GameMode.Play&&g.money==cash&&g.scrap==scrap,"next order opens without payout "+string(order+1));
        debug_inventory_assert(array_length(debug_inventory_sources(g))==16&&source.in_inventory,"skip preserves catalog "+string(order+1));
        if(order==0) debug_inventory_assert(!instance_exists(b)&&!instance_exists(pending),"skip cleans installed and held copies");
    }
    debug_inventory_assert(g.order_index==6&&g.order_device.object_index==obj_big_order,"skip sixth continues normal later-order flow");
    campaign_table(g);var index=g.order_index;
    debug_inventory_assert(!campaign_debug_skip_order(g)&&g.order_index==index,"table mode cannot skip an unopened order");
    campaign_open(g,g.recycler_robot.board_device);
    debug_inventory_assert(!campaign_debug_skip_order(g)&&g.order_index==index,"recycler cannot skip campaign order");
    campaign_table(g);campaign_open(g,g.order_device);
    var item=instance_create_depth(0,0,-10,obj_module_coil);inventory_add(g,item);
    var item_slot=-1;for(var i=0;i<array_length(g.inventory);++i) if(g.inventory[i]==item) item_slot=i;
    g.inventory_page=item.storage_page;px=g.inventory_x+item.storage_col*g.inventory_size+4;py=g.inventory_y+item.storage_row*g.inventory_size+4;
    debug_inventory_assert(inventory_pick(g,item_slot,px,py)&&g.active_device.selected_module==item&&g.inventory[item_slot]==noone,"ordinary loot retains normal move semantics in debug");
    debug_inventory_assert(board_cancel(g.active_device)&&g.inventory[item_slot]==item&&item.in_inventory,"ordinary loot cancel still returns original module");
    debug_inventory_assert(inventory_pick(g,item_slot,px,py)&&campaign_debug_skip_order(g)&&item.in_inventory&&g.inventory[item_slot]==item,"skip returns held ordinary loot without deleting it");
    campaign_table(g);var recycler=g.recycler_robot;
    debug_inventory_assert(robot_assign_power(g,recycler),"debug copy recycling uses normal energy allocation");
    campaign_open(g,recycler.board_device);var recycled=debug_inventory_pick_source(g,source);
    debug_inventory_assert(debug_inventory_place_first(recycler.board_device,recycled),"infinite source copy can enter recycler queue");
    scrap=g.scrap;robots_tick(g,0);robots_tick(g,30);
    debug_inventory_assert(!instance_exists(recycled)&&g.scrap==scrap+source.scrap_cost*0.5&&source.in_inventory,"recycling consumes copy and preserves infinite specimen");
    debug_inventory_assert(array_length(debug_inventory_sources(g))==16,"all catalog types survive delivery, skip, cancellation and recycling");
    show_debug_message("DEBUG_INVENTORY_RESULT passes="+string(global.debug_inventory_passes)+" failures=0");game_end();
}
