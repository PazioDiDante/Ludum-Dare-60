// Standalone shapes keep regression tests independent of editable game assets.
function module_test_fixture(_x,_y,_depth,_type) {
    var item=instance_create_depth(_x,_y,_depth,par_module);
    switch(_type) {
        case 1: item.shape=[[0,0,1],[0,1,Cell.R],[Cell.U,1,1]];break;
        case 2: item.shape=[[Cell.L,1],[1,Cell.D]];break;
        case 3: item.shape=[[Cell.L,1,Cell.R]];break;
    }
    return item;
}
// Device artwork may be edited to a smaller board. A partial layout is valid
// only when no type in its pool has any remaining legal position.
function device_test_capacity(_d) {
    if (_d.placed_modules == _d.requested_modules) return true;
    if (_d.placed_modules > _d.requested_modules) return false;
    for (var t=0;t<array_length(_d.module_pool);++t) {
        var candidate=instance_create_depth(0,0,-10,_d.module_pool[t]);candidate.device=_d;
        var fits=false;
        for(var row=0;row<_d.rows;++row)
            for(var col=0;col<_d.cols;++col)
                if(board_can_place(candidate,col,row)) fits=true;
        instance_destroy(candidate);
        if(fits) return false;
    }
    return true;
}
function base_assert(_ok,_label) {
    if (_ok) { global.test_passes++; show_debug_message("PASS: "+_label); }
    else { global.test_failures++; show_debug_message("FAIL: "+_label); }
}
function device_test_valid(_d) {
    var count = 0;
    for (var i=0; i<array_length(_d.children); ++i) {
        var item=_d.children[i];
        if (!instance_exists(item)) continue;
        if (item.object_index==obj_screw) continue;
        count++;
        if (item.device!=_d || !board_can_place(item,item.grid_col,item.grid_row)) return false;
        for (var row=0;row<array_length(item.shape);++row)
            for (var col=0;col<array_length(item.shape[row]);++col)
                if (item.shape[row][col]!=0 && _d.board[item.grid_row+row][item.grid_col+col]!=item) return false;
    }
    return count==_d.placed_modules;
}
function device_test_signature(_d) {
    var result="";
    for (var i=0;i<array_length(_d.children);++i) {
        var item=_d.children[i];
        if (!instance_exists(item) || item.object_index==obj_screw) continue;
        result+=object_get_name(item.object_index)+":"+string(item.grid_col)+","+string(item.grid_row)+";";
    }
    return result;
}
function base_tests() {
    var test_catalog=campaign_load();
    global.test_passes=0;global.test_failures=0;
    base_assert(instance_number(par_device)==1 && instance_exists(obj_game.order_device),"table starts with permanent order only");
    obj_game.start_device(obj_remote);
    var d=obj_game.active_device;
    base_assert(d.remaining==4 && instance_number(obj_screw)==4,"remote has its four screws");
    var screw=instance_find(obj_screw,0);
    pointer_dispatch(screw,mb_right);base_assert(d.remaining==4,"RMB leaves screw in place");
    global.mode=GameMode.Pause;pointer_dispatch(screw,mb_left);
    base_assert(d.remaining==4,"pause blocks screw action");global.mode=GameMode.Play;
    repeat(3) pointer_dispatch(instance_find(obj_screw,0),mb_left);
    base_assert(!d.cover_open && instance_number(par_module)==0,"three screws keep remote closed");
    pointer_dispatch(instance_find(obj_screw,0),mb_left);
    base_assert(d.cover_open && d.requested_modules>=3 && d.requested_modules<=6 && device_test_valid(d) && device_test_capacity(d),"last screw generates legal modules");
    var total=instance_number(par_module);d.open_cover();
    base_assert(instance_number(par_module)==total,"opening again does not regenerate");
    var old_module=instance_find(par_module,0);
    obj_game.start_device(obj_radio);
    base_assert(!instance_exists(d) && !instance_exists(old_module) && instance_number(par_device)==2,"factory switch cleans donor and retains order");
    d=obj_game.active_device;
    base_assert(d.remaining==3 && d.rows==7 && !d.board_shape[2][4],"radio has own screws and shaped board");
    var count_variants="", signatures="";
    for(var seed=0;seed<20;++seed) {
        obj_game.start_device(seed mod 2==0 ? obj_remote : obj_radio);
        d=obj_game.active_device;d.layout_seed=seed;d.open_cover();
        base_assert(device_test_valid(d) && device_test_capacity(d),"seed "+string(seed)+": valid non-overlapping layout");
        if(seed==0) count_variants=string(d.placed_modules);
        if(seed==2) base_assert(device_test_signature(d)!=signatures,"different seeds change the layout");
        if(seed==0) signatures=device_test_signature(d);
    }
    obj_game.start_device(obj_radio);d=obj_game.active_device;d.layout_seed=123;d.open_cover();
    var sig=device_test_signature(d);
    obj_game.start_device(obj_radio);d=obj_game.active_device;d.layout_seed=123;d.open_cover();
    base_assert(sig==device_test_signature(d),"fixed seed reproduces types and positions");
    var item=instance_find(par_module,0);
    var old_col=item.grid_col,old_row=item.grid_row;
    base_assert(!board_place(item,-20,-20) && item.grid_col==old_col && item.grid_row==old_row,"invalid move preserves position");
    var pick_x=0,pick_y=0;
    for(var sy=0;sy<array_length(item.shape);++sy)
        for(var sx=0;sx<array_length(item.shape[sy]);++sx)
            if(item.shape[sy][sx]!=0) { pick_x=item.x+(sx+0.5)*d.cell_size;pick_y=item.y+(sy+0.5)*d.cell_size; }
    board_pick(item,pick_x,pick_y);base_assert(d.selected_module==item,"module selects on its device");
    board_cancel(d);base_assert(d.selected_module==noone,"cancel clears selection");
    // The surface is only test input for the sprite-mask path.
    var surf=surface_create(38,24);
    surface_set_target(surf);draw_clear_alpha(c_black,0);draw_set_alpha(1);draw_set_color(c_white);
    draw_rectangle(0,0,11,11,false);draw_rectangle(24,0,35,11,false);draw_rectangle(12,12,23,23,false);
    surface_reset_target();
    var spr=sprite_create_from_surface(surf,0,0,38,24,false,false,7,3);surface_free(surf);
    sprite_collision_mask(spr,false,0,0,0,0,0,bboxkind_precise,0);
    var mask=board_shape_from_sprite(spr,12);
    base_assert(mask[0][0] && !mask[0][1] && mask[0][2] && !mask[1][0] && mask[1][1],"sprite transparency and origin produce correct grid");
    base_assert(array_length(mask[0])==4 && !mask[0][3] && instance_number(obj_board_mask)==0,"partial cells forbidden and sampler removed");
    instance_destroy(obj_game.active_device);obj_game.active_device=noone;
    var shaped=instance_create_depth(480,290,0,par_device);
    shaped.source_cell_size=12;shaped.board_mask_sprite=spr;shaped.module_min=0;shaped.module_max=0;
    with(shaped) device_build();
    base_assert(shaped.cover_open && shaped.board_shape[0][0] && !shaped.board_shape[0][1],"device build accepts sprite mask and zero screws");
    var test_module=module_test_fixture(0,0,-10,3);test_module.device=shaped;
    base_assert(!board_can_place(test_module,0,0),"module cannot cross a hole in sprite-derived board");
    base_assert(shaped.cell_size==shaped.source_cell_size*shaped.draw_scale && shaped.draw_scale==3,"small board enlarged three times");
    test_module.shape=[[1]];
    base_assert(board_place(test_module,2,0) && test_module.x==shaped.board_x+2*shaped.cell_size,"module uses scaled grid position");
    base_assert(test_module.hit_test(test_module.x+shaped.cell_size-1,test_module.y+1) && !test_module.hit_test(test_module.x+shaped.cell_size+1,test_module.y+1),"module hit test uses scaled size");
    instance_destroy(test_module);instance_destroy(shaped);sprite_delete(spr);
    var remote=instance_create_depth(480,290,0,obj_remote);
    base_assert(remote.cols==ceil(sprite_get_width(remote.board_mask_sprite)/16) && remote.rows==ceil(sprite_get_height(remote.board_mask_sprite)/16),"user board sprite maps to sixteen-pixel cells");
    base_assert(remote.board_x>=40 && remote.board_y>=80 && remote.board_x+remote.cols*remote.cell_size<=room_width-40 && remote.board_y+remote.rows*remote.cell_size<=room_height-40,"large board fits visible play area");
    instance_destroy(remote);
    var tiny=instance_create_depth(480,290,0,par_device);
    tiny.board_shape=[[0]];tiny.module_min=3;tiny.module_max=3;
    with(tiny) device_build();
    base_assert(tiny.requested_modules==3 && tiny.placed_modules==0 && instance_number(par_module)==0,"impossible layout terminates without stray candidates");
    instance_destroy(tiny);
    base_assert(instance_number(obj_screw)==0 && instance_number(par_module)==0,"all child instances cleaned up");

    // Deterministic board: an L-shaped module, blocker and one forbidden cell.
    var drag_device=instance_create_depth(480,290,0,par_device);
    drag_device.board_shape=[
        [1,1,1,1,1,1,1,1],[1,1,1,1,1,1,1,1],[1,1,1,1,1,1,1,1],
        [1,1,1,1,1,1,1,1],[1,1,1,1,1,1,1,1],[1,1,1,1,1,1,1,0]];
    drag_device.module_min=0;drag_device.module_max=0;
    with(drag_device) device_build();
    var held=module_test_fixture(0,0,-10,1);held.device=drag_device;
    var blocker=module_test_fixture(0,0,-10,2);blocker.device=drag_device;
    array_push(drag_device.children,held);array_push(drag_device.children,blocker);
    board_place(held,1,1);board_place(blocker,5,1);
    var cs=drag_device.cell_size, bx=drag_device.board_x, by=drag_device.board_y;
    base_assert(!board_pick(held,held.x+cs/2,held.y+cs/2),"cannot pick up through a shape hole");
    var hx=held.x+2.75*cs, hy=held.y+2.25*cs;
    base_assert(board_pick(held,hx,hy) && held.grab_col==2 && held.grab_row==2,"pickup remembers bottom-right grab offset");
    board_drag_update(drag_device,hx,hy);
    base_assert(held.x==bx+cs && held.y==by+cs,"pickup does not jump to cursor origin");
    board_drag_update(drag_device,hx+cs,hy);
    base_assert(held.x==bx+2*cs && held.y==by+cs && held.grid_col==1,"preview moves exactly one cell without committing");
    base_assert(drag_device.board[3][1]==held && drag_device.board[1][4]==noone,"old cells remain reserved during pickup");
    base_assert(!board_pick(blocker,blocker.x+cs/2,blocker.y+cs/2),"only one module can be held");
    board_drag_update(drag_device,bx+5.75*cs,by+3.25*cs);
    base_assert(!held.drop_valid && !board_drop(drag_device) && drag_device.selected_module==held,"occupied drop rejected and module remains held");
    board_drag_update(drag_device,bx-3*cs,by-3*cs);
    base_assert(!held.drop_valid && !board_drop(drag_device),"outside drop rejected");
    board_drag_update(drag_device,bx+7.75*cs,by+5.25*cs);
    base_assert(!held.drop_valid,"preview detects forbidden board cell");
    base_assert(board_cancel(drag_device) && held.x==bx+cs && held.y==by+cs && held.depth==-10,"cancel restores original position and depth");
    board_pick(held,hx,hy);
    board_drag_update(drag_device,hx+cs,hy);
    base_assert(board_drop(drag_device) && held.grid_col==2 && drag_device.selected_module==noone,"next click commits preview");
    base_assert(drag_device.board[3][1]==noone && drag_device.board[1][4]==held,"drop transfers occupancy");
    board_pick(held,held.x+2.75*cs,held.y+2.25*cs);
    var frozen_x=held.x;
    global.mode=GameMode.Pause;
    base_assert(!board_drag_update(drag_device,0,0) && held.x==frozen_x && !board_drop(drag_device),"pause freezes pickup and blocks drop");
    global.mode=GameMode.Play;board_cancel(drag_device);
    instance_destroy(drag_device);
    base_assert(!instance_exists(held) && !instance_exists(blocker),"device cleanup removes held-capable modules");

    // Rectangular asymmetric shape exercises all port directions and grab offsets.
    var turn_device=instance_create_depth(480,290,0,par_device);
    turn_device.board_shape=array_create(8);
    for(var rr=0;rr<8;++rr) turn_device.board_shape[rr]=array_create(8,1);
    turn_device.module_min=0;turn_device.module_max=0;
    with(turn_device) device_build();
    var turned=module_test_fixture(0,0,-10,1);turned.device=turn_device;
    turned.shape=[[Cell.L,0,Cell.U],[1,Cell.D,Cell.R]];
    array_push(turn_device.children,turned);board_place(turned,2,2);
    var ts=turn_device.cell_size;
    board_pick(turned,turned.x+2.5*ts,turned.y+1.5*ts);
    var anchor_c=turned.preview_col+turned.grab_col, anchor_r=turned.preview_row+turned.grab_row;
    pointer_dispatch(turned,mb_right);
    base_assert(turn_device.selected_module==turned && turned.rotation_steps==1,"RMB rotates held module instead of cancelling");
    base_assert(array_length(turned.shape)==3 && array_length(turned.shape[0])==2,"quarter turn swaps rectangular dimensions");
    base_assert(turned.shape[0][1]==Cell.U && turned.shape[1][0]==Cell.L && turned.shape[2][0]==Cell.D && turned.shape[2][1]==Cell.R,"all four port directions rotate clockwise");
    base_assert(turned.shape[0][0]==1 && turned.shape[1][1]==0,"rotation preserves solid cells and holes");
    base_assert(turned.preview_col+turned.grab_col==anchor_c && turned.preview_row+turned.grab_row==anchor_r,"rotation preserves grabbed cell under cursor");
    base_assert(turn_device.board[2][2]==turned && turn_device.board[4][4]==noone,"rotation preview does not change occupancy");
    repeat(3) board_rotate(turn_device);
    base_assert(turned.rotation_steps==0 && json_stringify(turned.shape)==json_stringify([[Cell.L,0,Cell.U],[1,Cell.D,Cell.R]]) && turned.preview_col==2 && turned.preview_row==2,"four turns restore shape ports and anchor");
    board_rotate(turn_device);board_cancel(turn_device);
    base_assert(turned.rotation_steps==0 && array_length(turned.shape)==2 && turned.shape[0][0]==Cell.L && turned.x==turn_device.board_x+2*ts,"cancel restores pickup orientation and position");
    board_pick(turned,turned.x+2.5*ts,turned.y+1.5*ts);board_rotate(turn_device);
    base_assert(board_drop(turn_device) && turned.rotation_steps==1 && turned.grid_col==4 && turned.grid_row==1,"drop commits rotated shape at anchored position");
    base_assert(turn_device.board[2][2]==noone && turn_device.board[1][5]==turned && turn_device.board[2][5]==noone,"rotated occupancy matches ports and holes");
    board_pick(turned,turned.x+0.5*ts,turned.y+0.5*ts);board_rotate(turn_device);board_cancel(turn_device);
    base_assert(turned.rotation_steps==1 && array_length(turned.shape)==3,"later cancel restores last placed orientation");
    board_pick(turned,turned.x+0.5*ts,turned.y+0.5*ts);
    global.mode=GameMode.Pause;
    base_assert(!board_rotate(turn_device) && turned.rotation_steps==1,"pause blocks rotation");
    global.mode=GameMode.Play;board_cancel(turn_device);
    var wall_item=module_test_fixture(0,0,-10,2);wall_item.device=turn_device;wall_item.shape=[[1]];
    array_push(turn_device.children,wall_item);
    board_place(turned,4,1);board_place(wall_item,2,1);
    board_pick(turned,turned.x+0.5*ts,turned.y+0.5*ts);board_rotate(turn_device);
    base_assert(!turned.drop_valid && !board_drop(turn_device) && turn_device.selected_module==turned,"rotation into another module cannot be placed");
    board_cancel(turn_device);
    board_pick(turned,turned.x+0.5*ts,turned.y+0.5*ts);
    board_drag_update(turn_device,turn_device.board_x+7.5*ts,turn_device.board_y+7.5*ts);board_rotate(turn_device);
    base_assert(!turned.drop_valid && !board_drop(turn_device),"rotated preview outside board cannot be placed");
    board_cancel(turn_device);
    instance_destroy(turn_device);
    base_assert(!board_rotate(noone),"rotation without held module is rejected");

    // Render an asymmetric test sprite with a non-zero origin. Check actual pixels.
    var source_surface=surface_create(48,32);
    surface_set_target(source_surface);draw_clear_alpha(c_black,0);draw_set_alpha(1);
    draw_set_color(c_red);draw_rectangle(32,0,47,15,false);
    draw_set_color(c_blue);draw_rectangle(0,16,15,31,false);
    surface_reset_target();
    var rotate_sprite=sprite_create_from_surface(source_surface,0,0,48,32,false,false,7,5);
    surface_free(source_surface);
    var target_surface=surface_create(64,64);
    var sprite_offset=module_sprite_offset(rotate_sprite,1,1);
    surface_set_target(target_surface);draw_clear_alpha(c_black,0);
    draw_sprite_ext(rotate_sprite,0,sprite_offset[0],sprite_offset[1],1,1,-90,c_white,1);
    surface_reset_target();
    base_assert(surface_getpixel(target_surface,24,40)==c_red && surface_getpixel(target_surface,8,8)==c_blue,"sprite pixels rotate clockwise and align with grid despite origin");
    surface_free(target_surface);sprite_delete(rotate_sprite);draw_set_color(c_white);
    // Input actions use injected key/button states, not physical OS input.
    input_init();global.test_cancel_key=false;global.test_cancel_mouse=false;
    var key_reader=function(_key) { return _key==ord("Q") && global.test_cancel_key; };
    var mouse_reader=function(_button) { return _button==mb_middle && global.test_cancel_mouse; };
    input_update(key_reader,mouse_reader);global.test_cancel_key=true;input_update(key_reader,mouse_reader);
    base_assert(input_pressed(Action.Cancel),"Q triggers cancel action");
    global.test_cancel_mouse=true;input_update(key_reader,mouse_reader);
    base_assert(!input_pressed(Action.Cancel),"held Q plus middle button does not repeat cancel");
    global.test_cancel_key=false;global.test_cancel_mouse=false;input_update(key_reader,mouse_reader);
    global.test_cancel_mouse=true;input_update(key_reader,mouse_reader);
    base_assert(input_pressed(Action.Cancel),"middle mouse triggers cancel action");

    // Wiring fixture: two modules with two contacts each, no random layout.
    var wire_device=instance_create_depth(480,290,0,par_device);
    wire_device.board_shape=array_create(6);
    for(var wr=0;wr<6;++wr) wire_device.board_shape[wr]=array_create(10,1);
    wire_device.module_min=0;wire_device.module_max=0;
    with(wire_device) device_build();
    var wa=module_test_fixture(0,0,-10,1);wa.device=wire_device;wa.shape=[[0,Cell.R],[Cell.U,1]];
    var wb=module_test_fixture(0,0,-10,2);wb.device=wire_device;wb.shape=[[Cell.L,1],[1,Cell.D]];
    array_push(wire_device.children,wa);array_push(wire_device.children,wb);
    board_place(wa,1,1);board_place(wb,5,1);
    var ws=wire_device.cell_size;
    var pa=port_reference(wa,1,0), pb=port_reference(wb,0,0), pa2=port_reference(wa,0,1);
    var a_pos=port_current(pa), b_pos=port_current(pb);
    base_assert(port_equal(port_find(wire_device,a_pos.x,a_pos.y),pa),"contact hit returns stable port reference");
    base_assert(is_undefined(port_find(wire_device,wa.x+1.5*ws,wa.y+0.5*ws)),"port cell body is not a contact");
    base_assert(!wire_input(wire_device,wa.x+1.5*ws,wa.y+1.5*ws,false,false),"module body remains available for pickup");
    base_assert(wire_input(wire_device,a_pos.x,a_pos.y,true,false) && port_equal(wire_device.wire_start,pa) && wire_device.selected_module==noone,"first contact click starts wire instead of pickup");
    wire_input(wire_device,70,450,false,false);
    base_assert(wire_device.wire_mouse_x==70 && wire_device.wire_mouse_y==450,"draft endpoint follows pointer");
    wire_input(wire_device,70,450,true,false);
    base_assert(port_equal(wire_device.wire_start,pa) && array_length(wire_device.wires)==0,"empty second click keeps draft");
    base_assert(!wire_click(wire_device,pa2) && array_length(wire_device.wires)==0,"same-module connection rejected");
    base_assert(!board_pick(wb,wb.x+1.5*ws,wb.y+0.5*ws),"pending wire blocks pickup");
    global.mode=GameMode.Pause;
    base_assert(!wire_input(wire_device,b_pos.x,b_pos.y,true,false) && array_length(wire_device.wires)==0,"pause blocks wire completion");
    global.mode=GameMode.Play;
    base_assert(wire_input(wire_device,b_pos.x,b_pos.y,true,false) && is_undefined(wire_device.wire_start),"second module contact completes wire");
    base_assert(array_length(wire_device.wires)==1 && array_length(wa.connections)==1 && array_length(wb.connections)==1,"connection stored once in device and on both modules");
    base_assert(wa.connections[0].module==wb && wb.connections[0].module==wa && port_equal(wb.connections[0].other_port,pa),"module collections identify peer and endpoint");
    // Verify real line rendering, not only the connection data.
    var wire_surface=surface_create(960,540);
    surface_set_target(wire_surface);draw_clear_alpha(c_black,0);wire_draw(wire_device);surface_reset_target();
    base_assert(surface_getpixel(wire_surface,round((a_pos.x+b_pos.x)/2),round(a_pos.y))==c_aqua,"completed wire draws between contacts");
    surface_free(wire_surface);
    base_assert(!wire_connect(wire_device,pb,pa) && array_length(wire_device.wires)==1,"reverse duplicate rejected");
    wire_click(wire_device,pa2);wire_input(wire_device,70,450,false,true);
    base_assert(is_undefined(wire_device.wire_start) && array_length(wa.connections)==1,"cancel draft preserves completed wires");
    // Wires follow the stable contact through rotation, movement and cancellation.
    board_pick(wa,wa.x+1.5*ws,wa.y+1.5*ws);board_rotate(wire_device);
    var rotated_port=port_current(pa);
    base_assert(rotated_port.direction==Cell.D && port_equal(port_reference(wa,rotated_port.col,rotated_port.row),pa),"port identity survives rotation");
    base_assert(wb.connections[0].other_port.col==1 && wb.connections[0].other_port.row==0,"peer reference stays in original coordinates");
    board_drag_update(wire_device,wa.x+(wa.grab_col+0.5)*ws+ws,wa.y+(wa.grab_row+0.5)*ws);
    var moved_port=port_current(pa);
    base_assert(moved_port.x==rotated_port.x+ws && moved_port.y==rotated_port.y,"wire endpoint follows picked module");
    base_assert(!wire_click(wire_device,pb),"cannot start wire while holding module");
    board_cancel(wire_device);
    var restored_port=port_current(pa);
    base_assert(restored_port.x==a_pos.x && restored_port.y==a_pos.y && restored_port.direction==Cell.R,"cancel restores connection endpoint");
    base_assert(!wire_connect(wire_device,pa2,pb) && array_length(wb.connections)==1,"occupied target rejects another source");
    var pb2=port_reference(wb,1,1);
    base_assert(!wire_connect(wire_device,pa,pb2) && array_length(wa.connections)==1,"occupied source rejects another target");
    base_assert(wire_connect(wire_device,pa2,pb2) && array_length(wb.connections)==2,"distinct free port pair on same modules is allowed");
    global.mode=GameMode.Pause;
    base_assert(!wire_click(wire_device,pa) && array_length(wire_device.wires)==2,"pause prevents disconnecting occupied port");
    global.mode=GameMode.Play;
    var occupied_pos=port_current(pa);
    wire_input(wire_device,occupied_pos.x,occupied_pos.y,true,false);
    base_assert(array_length(wire_device.wires)==1 && port_equal(wire_device.wire_start,pa),"click occupied port removes old wire and starts draft");
    base_assert(array_length(wa.connections)==1 && array_length(wb.connections)==1 && wire_for_port(wire_device,pa)<0 && wire_for_port(wire_device,pb)<0,"disconnect removes both records and frees both contacts");
    base_assert(wire_for_port(wire_device,pa2)>=0 && wire_for_port(wire_device,pb2)>=0,"disconnect preserves another wire between same modules");
    base_assert(!wire_click(wire_device,pa2) && wire_for_port(wire_device,pa2)>=0,"invalid same-module target keeps its existing wire");
    base_assert(wire_click(wire_device,pb2) && array_length(wire_device.wires)==1 && is_undefined(wire_device.wire_start),"occupied target wire replaced by drawn wire");
    base_assert(wire_for_port(wire_device,pa2)<0 && array_length(wa.connections)==1 && array_length(wb.connections)==1 && port_equal(wb.connections[0].other_port,pa),"replacement frees old source and updates both connection lists");
    wire_click(wire_device,pa);
    wire_input(wire_device,70,450,false,false,true);
    base_assert(is_undefined(wire_device.wire_start) && wire_for_port(wire_device,pa)<0,"RMB cancels draft without restoring deleted wire");
    wire_connect(wire_device,pa2,pb2);
    wire_click(wire_device,pb);wire_click(wire_device,pa);
    base_assert(array_length(wire_device.wires)==2 && array_length(wa.connections)==2,"freed contacts can reconnect in reverse order");
    occupied_pos=port_current(pb);
    wire_input(wire_device,occupied_pos.x,occupied_pos.y,true,false);
    base_assert(array_length(wire_device.wires)==1 && port_equal(wire_device.wire_start,pb),"either endpoint can disconnect a wire");
    wire_cancel(wire_device);wire_connect(wire_device,pa,pb);
    // Hovering the rendered contact after rotation resolves the same endpoint.
    board_pick(wa,wa.x+1.5*ws,wa.y+1.5*ws);board_rotate(wire_device);board_drop(wire_device);
    rotated_port=port_current(pa);
    base_assert(port_equal(port_find(wire_device,rotated_port.x,rotated_port.y),pa),"rotated contact remains clickable");
    var alien_device=instance_create_depth(480,290,0,par_device);alien_device.module_min=0;alien_device.module_max=0;
    with(alien_device) device_build();
    var alien=module_test_fixture(0,0,-10,3);alien.device=alien_device;
    array_push(alien_device.children,alien);
    base_assert(!wire_connect(wire_device,pa,port_reference(alien,0,0)),"cross-device connection rejected");
    instance_destroy(alien_device);
    wire_click(wire_device,pa);instance_destroy(wa);
    base_assert(array_length(wb.connections)==0 && array_length(wire_device.wires)==0 && is_undefined(wire_device.wire_start),"deleting source clears peers wires and draft");
    base_assert(is_undefined(port_current(pa)),"deleted endpoint is safely rejected");

    // Three different modules: C takes the target previously connected to B.
    var wc=module_test_fixture(0,0,-10,3);wc.device=wire_device;wc.shape=[[Cell.R]];
    var wd=module_test_fixture(0,0,-10,3);wd.device=wire_device;wd.shape=[[Cell.L]];
    array_push(wire_device.children,wc);array_push(wire_device.children,wd);
    board_place(wc,1,4);board_place(wd,3,4);
    var pc=port_reference(wc,0,0),pd=port_reference(wd,0,0);
    wire_connect(wire_device,pc,pb);wire_click(wire_device,pd);
    global.mode=GameMode.Pause;
    base_assert(!wire_click(wire_device,pb) && wc.connections[0].module==wb,"pause prevents replacing an occupied target");
    global.mode=GameMode.Play;
    base_assert(wire_click(wire_device,pb) && array_length(wc.connections)==0 && wd.connections[0].module==wb && wb.connections[0].module==wd,"replacement clears third module and records new peers");
    wire_click(wire_device,pc);
    wire_input(wire_device,70,450,true,false,true);
    base_assert(is_undefined(wire_device.wire_start) && array_length(wire_device.wires)==1,"RMB cancellation wins over simultaneous left click");
    wire_click(wire_device,pc);wire_input(wire_device,70,450,false,true,false);
    base_assert(is_undefined(wire_device.wire_start) && array_length(wire_device.wires)==1,"Q or middle-button cancellation still preserves completed wires");
    instance_destroy(wire_device);
    base_assert(!instance_exists(wb),"device cleanup removes connected modules");

    // Storage transactions: real module instances, no duplicate items.
    var manager = instance_find(obj_game,0);
    manager.start_device(obj_radio);
    var sd = manager.active_device;
    with(sd) open_cover();
    with(par_module) { if (device == sd) instance_destroy(); }
    var si = module_test_fixture(0,0,-10,3);
    si.device=sd; si.shape=[[Cell.R]];
    var sj = module_test_fixture(0,0,-10,3);
    sj.device=sd; sj.shape=[[Cell.L]];
    array_push(sd.children,si);array_push(sd.children,sj);
    board_place(si,2,0);board_place(sj,3,0);
    wire_connect(sd,port_reference(si,0,0),port_reference(sj,0,0));
    var ix=manager.inventory_x+32,iy=manager.inventory_y+32;
    base_assert(inventory_slot(manager,ix,iy)==0 && inventory_slot(manager,manager.inventory_x-1,iy)==-1,"inventory slot boundaries");
    board_pick(si,si.x+sd.cell_size/2,si.y+sd.cell_size/2);
    base_assert(storage_drop(manager,ix,iy) && manager.inventory[0]==si && !si.visible && si.in_inventory,"board module stored in one inventory slot");
    base_assert(sd.board[0][2]==noone && array_length(sj.connections)==0 && array_length(sd.wires)==0,"storage clears board and both wire endpoints");
    base_assert(is_undefined(port_current(port_reference(si,0,0))),"stored module ports are inactive");
    board_pick(sj,sj.x+sd.cell_size/2,sj.y+sd.cell_size/2);
    base_assert(!storage_drop(manager,ix,iy) && sd.selected_module==sj && manager.inventory[0]==si,"occupied inventory slot rejects second module");
    board_cancel(sd);
    base_assert(inventory_pick(manager,0,ix,iy) && manager.inventory[0]==noone && sd.selected_module==si && si.visible,"inventory pickup immediately removes thumbnail");
    board_rotate(sd);board_cancel(sd);
    base_assert(manager.inventory[0]==si && si.rotation_steps==0 && !si.visible && sd.selected_module==noone,"cancel restores inventory slot and original rotation");
    inventory_pick(manager,0,ix,iy);
    sd.cover_open=false;
    board_drag_update(sd,sd.board_x+2.5*sd.cell_size,sd.board_y+0.5*sd.cell_size);
    base_assert(!board_drop(sd),"inventory module cannot enter a closed device");
    sd.cover_open=true;
    base_assert(board_drop(sd) && sd.board[0][2]==si && si.inventory_origin==-1,"inventory module placed back on board");
    board_pick(si,si.x+sd.cell_size/2,si.y+sd.cell_size/2);storage_drop(manager,ix,iy);
    manager.start_device(obj_remote);
    base_assert(instance_exists(si) && manager.inventory[0]==si && si.device==noone,"inventory survives device switch");
    sd=manager.active_device;
    with(sd) open_cover();
    inventory_pick(manager,0,ix,iy);
    manager.start_device(obj_radio);
    base_assert(instance_exists(si) && manager.inventory[0]==si && !si.visible,"device switch returns held inventory module");
    sd=manager.active_device;
    with(sd) open_cover();
    inventory_pick(manager,0,ix,iy);
    global.mode=GameMode.Pause;
    base_assert(!storage_drop(manager,ix,iy),"pause prevents inventory drop");
    global.mode=GameMode.Play;
    base_assert(!storage_drop(manager,800,120) && instance_exists(si) && sd.selected_module==si,"former sale area does not consume module");
    board_cancel(sd);
    manager.inventory[0]=noone;instance_destroy(si);
    // Exercise thumbnail rendering and all four sprite rotations in a Draw event.
    var thumb=module_test_fixture(0,0,-10,1);
    thumb.in_inventory=true;thumb.visible=false;manager.inventory[0]=thumb;
    storage_draw(manager);
    thumb.sprite_index=spr_remote_board;
    for(var turn=0;turn<4;++turn) {thumb.rotation_steps=turn;storage_draw(manager);}
    manager.inventory[0]=noone;instance_destroy(thumb);
    base_assert(true,"shape and sprite inventory thumbnails render");

    manager.start_device(obj_radio);
    var bd=manager.active_device;
    base_assert(array_length(bd.board_ports)==0,"board contacts hidden before opening");
    with(bd) open_cover();
    base_assert(array_length(bd.board_ports)==2,"two board contacts generated");
    var br0=board_port_reference(bd,0),br1=board_port_reference(bd,1);
    var bp0=port_current(br0),bp1=port_current(br1);
    base_assert(!port_equal(br0,br1) && (bp0.x!=bp1.x || bp0.y!=bp1.y),"board contacts distinct");
    base_assert(port_equal(port_find(bd,bp0.x,bp0.y),br0),"board contact hit matches drawing");
    var exterior=true;
    for(var i=0;i<2;++i) {
        var edge=bd.board_ports[i];
        exterior=exterior && bd.board_shape[edge.row][edge.col];
        var dc=(edge.direction==Cell.R)-(edge.direction==Cell.L);
        var dr=(edge.direction==Cell.D)-(edge.direction==Cell.U);
        var ec=edge.col+dc,er=edge.row+dr;
        while(ec>=0 && er>=0 && ec<bd.cols && er<bd.rows) {
            if(bd.board_shape[er][ec]) exterior=false;
            ec+=dc;er+=dr;
        }
    }
    base_assert(exterior,"contacts on exterior silhouette not inner holes");
    with(par_module) {if(device==bd) instance_destroy();}
    var bm=module_test_fixture(0,0,-10,3);
    bm.device=bd;bm.shape=[[Cell.R]];array_push(bd.children,bm);board_place(bm,2,0);
    var mr=port_reference(bm,0,0);
    base_assert(wire_click(bd,br0) && wire_click(bd,mr) && bm.connections[0].module==bd && bd.connections[0].module==bm,"board-to-module wire stores both peers");
    wire_click(bd,br1);
    base_assert(wire_click(bd,mr) && wire_for_port(bd,br0)==-1 && array_length(bd.connections)==1,"board draft replaces occupied module contact");
    wire_click(bd,br1);wire_input(bd,0,0,false,false,true);
    base_assert(is_undefined(bd.wire_start) && array_length(bd.wires)==0,"board contact disconnect and RMB cancel");
    base_assert(wire_click(bd,mr) && wire_click(bd,br0),"module-to-board wire works");
    board_pick(bm,bm.x+bd.cell_size/2,bm.y+bd.cell_size/2);
    storage_drop(manager,ix,iy);
    base_assert(array_length(bd.connections)==0 && array_length(bm.connections)==0 && array_length(bd.wires)==0,"inventory removes board connection from both peers");
    base_assert(port_current(br0).x==bp0.x && port_current(br0).y==bp0.y,"board port position remains fixed");
    manager.inventory[0]=noone;instance_destroy(bm);
    board_ports_draw(bd);
    manager.start_device(obj_remote);
    base_assert(is_undefined(port_current(br0)),"old board contact invalid after device switch");
    bd=manager.active_device;
    with(bd) open_cover();
    base_assert(array_length(bd.board_ports)==2,"sprite board also has two contacts");
    var tiny=instance_create_depth(360,290,0,par_device);
    tiny.module_min=0;tiny.module_max=0;
    with(tiny) device_build();
    base_assert(array_length(tiny.board_ports)==2,"single-cell board has two distinct edge contacts");
    instance_destroy(tiny);
    var empty=instance_create_depth(360,290,0,par_device);
    empty.board_shape=[[0]];empty.module_min=0;empty.module_max=0;
    with(empty) device_build();
    base_assert(array_length(empty.board_ports)==0,"empty board has no invalid contacts");
    instance_destroy(empty);
    manager.start_device(obj_radio);
    var cd=manager.active_device;
    with(cd) open_cover();
    with(par_module) {if(device==cd) instance_destroy();}
    base_assert(!cd.circuit_connected && cd.circuit_check_count==0,"initial circuit false without frame checks");
    var cm=[];
    repeat(3) {
        var part=module_test_fixture(100,100,-10,3);
        part.device=cd;part.shape=[[Cell.L,Cell.U,Cell.R,Cell.D]];
        array_push(cd.children,part);array_push(cm,part);
    }
    var a0=port_reference(cm[0],0,0),a1=port_reference(cm[0],1,0),a2=port_reference(cm[0],2,0),a3=port_reference(cm[0],3,0);
    var b0=port_reference(cm[1],0,0),b1=port_reference(cm[1],1,0),b2=port_reference(cm[1],2,0);
    var c0=port_reference(cm[2],0,0),c1=port_reference(cm[2],1,0),c2=port_reference(cm[2],2,0);
    var cp0=board_port_reference(cd,0),cp1=board_port_reference(cd,1);
    wire_click(cd,cp0);wire_cancel(cd);
    base_assert(cd.circuit_check_count==0,"draft and cancellation do not check graph");
    wire_connect(cd,cp0,a0);
    base_assert(!cd.circuit_connected && cd.circuit_check_count==1,"single board endpoint is not a circuit");
    wire_connect(cd,cp1,b0);
    base_assert(!cd.circuit_connected,"disconnected modules do not conduct through board owner");
    wire_connect(cd,a1,b1);
    base_assert(cd.circuit_connected,"two-module chain connects board ports");
    var checks=cd.circuit_check_count;
    base_assert(!wire_connect(cd,a0,b0) && cd.circuit_check_count==checks,"rejected connection does not check graph");
    cm[0].x+=32;
    board_pick(cm[0],cm[0].x+cd.cell_size/2,cm[0].y+cd.cell_size/2);
    board_rotate(cd);board_cancel(cd);
    base_assert(cd.circuit_connected && cd.circuit_check_count==checks,"movement rotation and cancel do not check graph");
    wire_disconnect(cd,wire_for_port(cd,a1));
    base_assert(!cd.circuit_connected,"removing bridge breaks circuit");
    wire_connect(cd,a1,c0);wire_connect(cd,c1,b1);
    base_assert(cd.circuit_connected,"three-module chain connects board ports");
    wire_connect(cd,a2,b2);
    wire_disconnect(cd,wire_for_port(cd,cp1));
    base_assert(!cd.circuit_connected,"cycle without second board endpoint terminates false");
    wire_connect(cd,cp1,b0);
    base_assert(cd.circuit_connected,"cycle with path to second endpoint succeeds");
    checks=cd.circuit_check_count;
    wire_connect(cd,a3,cp1,true);
    base_assert(cd.circuit_connected && cd.circuit_check_count==checks+1,"occupied target replacement checks once after complete edit");
    wire_click(cd,cp0);
    base_assert(!cd.circuit_connected,"picking occupied board port immediately breaks circuit");
    checks=cd.circuit_check_count;wire_cancel(cd);
    base_assert(cd.circuit_check_count==checks,"cancel removed wire draft does not recheck");
    wire_connect(cd,cp0,a0);
    checks=cd.circuit_check_count;
    board_pick(cm[0],cm[0].x+cd.cell_size/2,cm[0].y+cd.cell_size/2);
    storage_drop(manager,ix,iy);
    base_assert(!cd.circuit_connected && cd.circuit_check_count==checks+1,"inventory removes multiple wires with one graph check");
    manager.inventory[0]=noone;instance_destroy(cm[0]);
    wire_disconnect(cd,wire_for_port(cd,b1));
    wire_connect(cd,cp0,b0);wire_connect(cd,cp1,b1);
    base_assert(cd.circuit_connected,"single module with two ports completes chain");
    instance_destroy(cm[1]);
    base_assert(!cd.circuit_connected,"deleting connected module clears circuit");
    manager.start_device(obj_remote);
    base_assert(!manager.active_device.circuit_connected && manager.active_device.circuit_check_count==0,"new device starts with fresh circuit state");
    manager.show_table();
    base_assert(global.mode==GameMode.Menu && !instance_exists(manager.active_device),"table replaces device selection menu");
    base_assert(!manager.table_click(0,0) && !instance_exists(manager.active_device),"click outside tabletop device does nothing");
    base_assert(bal_count(bal_catalog(),bal_radio_goal(),0).count==6,"provided balance demo has six solutions");
    var bc=lab_defaults(),orig=bal_catalog();
    for(var bi=0;bi<array_length(orig);++bi) bc.modules[bi].qty=string(orig[bi].qty);
    var bm=lab_validate(bc),bj=lab_job(bm);
    repeat(10000) {if(bj.phase!="count") break;lab_count_step(bj,1000);}
    base_assert(bj.phase=="simulate" && bj.valid==6 && bj.total==78,"incremental counts match original for current stock");
    // One deterministic type makes time and cash analytically verifiable.
    bc=lab_defaults();bc.modules=[{name:"Test",qty:"0",drop_weight:"1",stats:{}}];
    var bkeys=bal_keys();
    for(var bi=0;bi<8;++bi) {
        struct_set(bc.modules[0].stats,bkeys[bi],"0");struct_set(bc.base,bkeys[bi],"0");
        struct_set(bc.min,bkeys[bi],"");struct_set(bc.max,bkeys[bi],"");
    }
    bc.slots="1";bc.min_installed="1";bc.modules[0].stats.speed="1";bc.min.speed="1";
    bc.start_money="0";bc.device_price="20";bc.gift="5";bc.gift_seconds="2";
    bc.dismantle_seconds="10";bc.assembly_seconds="3";bc.order_price="100";bc.trials="4";
    bm=lab_validate(bc);bj=lab_job(bm);
    while(bj.phase=="count") lab_count_step(bj,1000);
    while(bj.phase=="simulate") lab_sim_step(bj,1000);
    base_assert(bj.successes==4 && bj.runs[0].seconds==21 && bj.runs[0].clicks==4 && bj.runs[0].money==100,"simulation includes money button dismantling assembly reward");
    base_assert(bj.runs[0].bought==1 && bj.runs[0].devices==1 && bj.runs[0].inventory[0]>=1,"cash shortage buys one device and consumes order modules");
    var bj2=lab_job(bm);
    while(bj2.phase=="count") lab_count_step(bj2,3);
    while(bj2.phase=="simulate") lab_sim_step(bj2,3);
    base_assert(json_stringify(bj.runs)==json_stringify(bj2.runs),"seed reproducible across different calculation budgets");
    bc.start_money="100";bj=lab_job(lab_validate(bc));
    while(bj.phase=="count") lab_count_step(bj,1000);
    while(bj.phase=="simulate") lab_sim_step(bj,1000);
    base_assert(bj.runs[0].bought>=3 && bj.runs[0].bought<=4 && bj.runs[0].devices==1 && bj.runs[0].seconds==13 && bj.runs[0].money==200-20*bj.runs[0].bought,"funded run pays entire batch but stops after completed order");
    bc.modules[0].qty="1";bc.modules[0].drop_weight="0";bj=lab_job(lab_validate(bc));
    while(bj.phase=="count") lab_count_step(bj,1000);
    while(bj.phase=="simulate") lab_sim_step(bj,1000);
    base_assert(bj.runs[0].devices==0 && bj.runs[0].seconds==3 && bj.runs[0].inventory[0]==0,"starting inventory can complete order without drops");
    bc.modules[0].qty="0";bj=lab_job(lab_validate(bc));
    while(bj.phase=="count") lab_count_step(bj,1000);
    base_assert(bj.phase=="impossible","unavailable module makes order impossible");
    bc.modules[0].drop_weight="1";bc.slots="8";bc.min_installed="8";bc.device_limit="1";bj=lab_job(lab_validate(bc));
    while(bj.phase=="count") lab_count_step(bj,1000);
    while(bj.phase=="simulate") lab_sim_step(bj,1000);
    base_assert(bj.phase=="done" && bj.successes==0 && bj.runs[0].devices==1,"simulation reports cap failures without infinite loop");
    bj=lab_job(lab_validate(bc));bj.node_limit=1;lab_count_step(bj,1000);
    base_assert(bj.phase=="limited","enumeration cap explicitly marks incomplete results");
    bc.gift="0";base_assert(!lab_validate(bc).ok,"zero money reward rejected");bc.gift="5";
    bc.min.speed="9";bc.max.speed="2";base_assert(!lab_validate(bc).ok,"contradictory stat bounds rejected");
    base_assert(is_undefined(lab_number("-")) && is_undefined(lab_number("1.2.3")) && lab_number("-2.5")==-2.5,"numeric editor validates malformed input");
    // OFF state is a distinct configuration, but still contributes its mass.
    bc=lab_defaults();bc.modules=[{name:"Single",qty:"1",drop_weight:"0",stats:{}}];
    for(var bi=0;bi<8;++bi) {
        struct_set(bc.modules[0].stats,bkeys[bi],"0");struct_set(bc.base,bkeys[bi],"0");
        struct_set(bc.min,bkeys[bi],"");struct_set(bc.max,bkeys[bi],"");
    }
    bc.modules[0].stats.weight="3";bc.slots="1";bc.allow_unpowered=true;bc.max.weight="2";
    bj=lab_job(lab_validate(bc));while(bj.phase=="count") lab_count_step(bj,1000);
    base_assert(bj.total==2 && bj.valid==0,"OFF enumeration keeps installed module weight");

    // Editable child objects: inherited defaults and per-type values.
    var module_expected=[[3,1,2,-2,2],[-1,1,-3,0,1],[-1,0,1,3,1],[8,5,1,-5,1],[-2,1,0,5,1],[5,2,3,-2,1],[4,2,-3,3,1],[1,1,-1,1,1]];
    base_assert(array_length(manager.module_types)==8,"eight editable module types registered");
    for(var mi=0;mi<8;++mi) {
        var sample=instance_create_depth(0,0,0,manager.module_types[mi]),expected=module_expected[mi];
        base_assert(object_is_ancestor(sample.object_index,par_module),"module inherits parent "+string(mi));
        base_assert(sample.stats.energy==expected[0]&&sample.stats.weight==expected[1]&&sample.stats.heat==expected[2]&&sample.stats.stability==expected[3]&&sample.drop_weight==expected[4],"module configured stats "+string(mi));
        instance_destroy(sample);
    }
    campaign_table(manager);
    var debug_money=manager.money;
    base_assert(manager.debug_tools&&campaign_earn(manager)&&manager.money==debug_money&&manager.table_plate&&manager.earn_remaining==0,"debug supply creates a plate without immediate money");
    campaign_solder_plate(manager);campaign_tick(manager,10);
    base_assert(manager.money==debug_money+20&&!manager.table_plate,"plate pays twenty once through timer even in debug");
    var debug_device=instance_create_depth(480,290,0,obj_remote);
    campaign_open(manager,debug_device);
    base_assert(campaign_debug_unscrew(manager)&&debug_device.remaining==0&&debug_device.cover_open,"debug removes all screws and opens cover");
    var debug_parts=debug_device.placed_modules;
    base_assert(!campaign_debug_unscrew(manager)&&debug_device.placed_modules==debug_parts,"debug unscrew cannot generate loot twice");
    campaign_table(manager);instance_destroy(debug_device);
    manager.debug_tools=false; // Remaining checks exercise normal five-second economy.
    // Actual campaign transactions; legacy factory fixtures above are not purchases.
    with(par_device) {if(!is_order) instance_destroy();}
    manager.active_device=noone;manager.table_devices=[];manager.money=50;manager.earn_remaining=0;
    campaign_table(manager);
    base_assert(instance_exists(manager.order_device)&&!is_undefined(test_catalog),"campaign order and saved catalog loaded");
    base_assert(campaign_buy(manager)&&campaign_buy(manager)&&manager.money==0&&array_length(manager.table_devices)==2,"50 coins buy exactly two single devices");
    base_assert(!campaign_buy(manager)&&array_length(manager.table_devices)==2,"insufficient funds cannot create a device");
    var work=manager.table_devices[0],next_work=manager.table_devices[1];
    campaign_open(manager,work);var screws_before=work.remaining;
    base_assert(!campaign_finish(manager),"cannot finish unopened workpiece");
    work.open_cover();
    base_assert(work.placed_modules>=2&&work.placed_modules<=3,"campaign donor yields two or three catalog modules");
    var saved_parts=[];
    for(var ci=0;ci<array_length(work.children);++ci) {
        var part=work.children[ci];
        if(instance_exists(part)&&variable_instance_exists(part,"catalog_index")) array_push(saved_parts,part);
    }
    for(var ci=0;ci<array_length(saved_parts);++ci) {
        var part=saved_parts[ci],listed=false;
        for(var mi=0;mi<array_length(manager.module_types);++mi) if(part.object_index==manager.module_types[mi]) listed=true;
        base_assert(listed,"campaign creates listed child object");
        var sample=instance_create_depth(0,0,0,part.object_index);
        base_assert(json_stringify(sample.shape)==json_stringify(part.shape)&&json_stringify(sample.stats)==json_stringify(part.stats),"loot preserves child shape and stats");
        instance_destroy(sample);
    }
    campaign_table(manager);campaign_open(manager,work);
    base_assert(work.cover_open&&campaign_module_count(work)==array_length(saved_parts),"table return preserves generated donor parts");
    for(var ci=0;ci<array_length(saved_parts);++ci) {
        var part=saved_parts[ci];
        var pick_col=0,pick_row=0,found_cell=false;
        for(var pr=0;pr<array_length(part.shape)&&!found_cell;++pr)
            for(var pc=0;pc<array_length(part.shape[pr])&&!found_cell;++pc)
                if(part.shape[pr][pc]!=Cell.Empty) {pick_col=pc;pick_row=pr;found_cell=true;}
        board_pick(part,part.x+(pick_col+0.5)*work.cell_size,part.y+(pick_row+0.5)*work.cell_size);
        var slot=ci;storage_drop(manager,manager.inventory_x+(slot mod manager.inventory_cols)*manager.inventory_size+32,manager.inventory_y+(slot div manager.inventory_cols)*manager.inventory_size+32);
    }
    base_assert(campaign_module_count(work)==0&&campaign_finish(manager)&&!instance_exists(work),"empty donor finish removes only that workpiece");
    base_assert(instance_exists(saved_parts[0])&&saved_parts[0].in_inventory&&array_length(manager.table_devices)==1&&manager.table_devices[0]==next_work,"finish preserves recovered inventory and next device");
    campaign_open(manager,next_work);next_work.open_cover();
    base_assert(!campaign_finish(manager)&&manager.finish_confirm&&instance_exists(next_work),"remaining parts require discard confirmation");
    base_assert(campaign_finish(manager)&&!instance_exists(next_work),"confirmed finish scraps remaining parts");
    base_assert(campaign_earn(manager)&&!campaign_earn(manager)&&campaign_solder_plate(manager)&&!campaign_solder_plate(manager),"one plate and one earning timer");
    campaign_tick(manager,4.9);base_assert(manager.money==0,"earning cannot pay before five seconds");
    campaign_tick(manager,0.1);campaign_tick(manager,20);
    base_assert(manager.money==20&&manager.earn_remaining==0,"earning pays twenty once after five seconds");
    campaign_earn(manager);campaign_solder_plate(manager);global.mode=GameMode.Pause;campaign_tick(manager,5);
    base_assert(manager.earn_remaining==5&&manager.money==20,"pause suspends earning");
    global.mode=GameMode.Menu;campaign_tick(manager,5);campaign_earn(manager);campaign_solder_plate(manager);campaign_tick(manager,5);
    base_assert(campaign_buy(manager)&&manager.money==35,"earned coins fund a new device");
    var order=manager.order_device;campaign_open(manager,order);
    base_assert(!campaign_complete(manager),"empty unwired order cannot complete");
    // Legacy circuit fixture uses its own goal, independent of live order balance.
    var saved_order_min=order.stats_min;order.stats_min={energy:6,heat:0,stability:0};
    // Four known catalog types from the supplied manifest: accumulator, battery, cooler, coil.
    var types=[3,0,1,4],installed=[];
    for(var ci=0;ci<4;++ci) {
        var part=instance_create_depth(0,0,-10,par_module);part.device=order;part.shape=[[Cell.L,Cell.R]];
        part.stats=test_catalog.items[types[ci]].stats;part.module_name=test_catalog.items[types[ci]].name;
        var placed=false;
        for(var row=0;row<order.rows&&!placed;++row) for(var col=0;col<order.cols&&!placed;++col) if(board_place(part,col,row)) placed=true;
        base_assert(placed,"order has usable board cells for module "+string(ci));
        array_push(order.children,part);array_push(installed,part);
    }
    wire_connect(order,board_port_reference(order,0),port_reference(installed[0],0,0));
    for(var ci=0;ci<3;++ci) wire_connect(order,port_reference(installed[ci],1,0),port_reference(installed[ci+1],0,0));
    base_assert(!order.requirements_met,"stats alone cannot replace board circuit");
    wire_connect(order,port_reference(installed[3],1,0),board_port_reference(order,1));
    base_assert(order.requirements_met&&order.current_stats.energy==7&&order.current_stats.heat==4&&order.current_stats.stability==1&&order.current_stats.weight==8,"connected manifest modules satisfy goal");
    var old_slots=test_catalog.econ.slots,old_min_installed=test_catalog.econ.min_installed;
    test_catalog.econ.slots=1;test_catalog.econ.min_installed=99;
    device_stats_update(order);
    base_assert(order.requirements_met,"order completion ignores old module count limits");
    var extra=instance_create_depth(0,0,-10,par_module);extra.device=order;extra.shape=[[1]];extra.inventory_origin=0;
    var extra_fits=false;
    for(var er=0;er<order.rows;++er) for(var ec=0;ec<order.cols;++ec) if(board_can_place(extra,ec,er)) extra_fits=true;
    base_assert(extra_fits,"incoming inventory module can fit above old slot limit");
    instance_destroy(extra);
    test_catalog.econ.slots=old_slots;test_catalog.econ.min_installed=old_min_installed;
    wire_disconnect(order,wire_for_port(order,board_port_reference(order,0)));
    base_assert(!order.requirements_met&&order.current_stats.energy==7&&order.current_stats.weight==8,"open circuit retains stats powered from the other board contact");
    wire_connect(order,board_port_reference(order,0),port_reference(installed[0],0,0));
    base_assert(campaign_complete(manager)&&order.completed&&!order.cover_open,"valid order assembles its cover");
    base_assert(!campaign_complete(manager),"assembled order cannot complete twice");
    campaign_table(manager);campaign_open(manager,order);
    base_assert(order.completed&&!installed[0].visible,"completed order stays covered when reopened");
    campaign_table(manager);

    // Multiple independently wired contacts in the same cell.
    for(var mc=Cell.L;mc<=Cell.LURD;++mc) {
        var rotated_cell=mc;repeat(4) rotated_cell=cell_rotate(rotated_cell);
        base_assert(rotated_cell==mc,"four rotations preserve port combination "+string(mc));
    }
    base_assert(cell_rotate(Cell.LR)==Cell.UD && cell_rotate(Cell.LUD)==Cell.LUR,"combined sides rotate clockwise");
    base_assert(array_length(cell_directions("rLl"))==2 && cell_rotate("LUD")=="LUR","string cells accept unordered duplicate letters");
    var md=instance_create_depth(480,290,0,par_device);
    md.board_shape=array_create(4);for(var mr=0;mr<4;++mr) md.board_shape[mr]=array_create(6,1);
    md.module_min=0;md.module_max=0;with(md) device_build();md.cover_open=true;
    md.board_ports=[{col:0,row:0,direction:Cell.L},{col:5,row:0,direction:Cell.R}];
    var mm=instance_create_depth(0,0,-10,par_module);mm.device=md;mm.shape=[[Cell.LURD]];
    array_push(md.children,mm);board_place(mm,2,1);global.mode=GameMode.Play;
    var ml=port_reference(mm,0,0,Cell.L),mu=port_reference(mm,0,0,Cell.U),
        mright=port_reference(mm,0,0,Cell.R),mbottom=port_reference(mm,0,0,Cell.D);
    var refs=[ml,mu,mright,mbottom];
    for(var mi=0;mi<4;++mi) {
        var mp=port_current(refs[mi]);
        base_assert(port_equal(port_find(md,mp.x,mp.y),refs[mi]),"each side in same cell is clickable "+string(mi));
    }
    base_assert(!port_equal(ml,mright),"opposite contacts in same cell have separate identities");
    base_assert(is_undefined(port_find(md,mm.x+md.cell_size/2,mm.y+md.cell_size/2)),"multi-port cell centre remains body");
    base_assert(wire_connect(md,board_port_reference(md,0),ml)&&wire_connect(md,mright,board_port_reference(md,1))&&md.circuit_connected,"two wires on one cell close board circuit");
    base_assert(wire_for_port(md,mu)==-1&&wire_for_port(md,mbottom)==-1,"unused sides remain free");
    board_pick(mm,mm.x+md.cell_size/2,mm.y+md.cell_size/2);board_rotate(md);
    base_assert(port_current(ml).direction==Cell.U&&port_current(mright).direction==Cell.D,"wires follow original contact through rotation");
    base_assert(port_equal(port_reference(mm,0,0,Cell.U),ml),"rotated side resolves original identity");
    board_cancel(md);
    base_assert(port_current(ml).direction==Cell.L&&array_length(md.wires)==2,"cancel restores contact direction and both wires");
    wire_click(md,ml);
    base_assert(array_length(md.wires)==1&&wire_for_port(md,mright)>=0&&!md.circuit_connected,"disconnect one side preserves other side wire");
    wire_cancel(md);
    var snap_pos=port_current(mu),snap_x=snap_pos.x,snap_y=snap_pos.y-14;
    base_assert(is_undefined(port_find(md,snap_x,snap_y)),"snap test point lies outside actual contact");
    base_assert(is_undefined(port_find_snap(md,snap_x,snap_y)),"first port click uses smaller radius than attachment");
    wire_click(md,board_port_reference(md,0));
    wire_input(md,snap_x,snap_y,false,false);
    base_assert(port_equal(md.hover_port,mu)&&md.wire_mouse_x==snap_pos.x&&md.wire_mouse_y==snap_pos.y,"draft snaps and highlights nearest contact");
    wire_input(md,-1000,-1000,false,false);
    base_assert(is_undefined(md.hover_port)&&md.wire_mouse_x==-1000,"draft follows mouse outside radius");
    wire_input(md,snap_x,snap_y,true,false);
    base_assert(is_undefined(md.wire_start)&&wire_for_port(md,mu)>=0&&md.circuit_connected,"nearby click connects snapped port");
    wire_click(md,ml);
    base_assert(is_undefined(port_find_snap(md,snap_x,snap_y)),"snap excludes source module contacts");
    wire_cancel(md);instance_destroy(md);global.mode=GameMode.Menu;

    var bar=stat_bar_model(0,6,10);
    base_assert(bar.count==20&&!bar.valid&&bar.unit==1,"empty stat bar uses fixed twenty-cell scale");
    base_assert(stat_bar_model(6,6,10).valid&&stat_bar_model(10,6,10).valid&&!stat_bar_model(11,6,10).valid,"bar range includes endpoints and detects overflow");
    base_assert(stat_bar_model(100,6,undefined).valid&&!stat_bar_model(5,6,undefined).valid,"minimum-only bar");
    base_assert(stat_bar_model(-3,undefined,5).valid&&!stat_bar_model(6,undefined,5).valid,"maximum-only bar accepts negative values");
    bar=stat_bar_model(-4,-5,-2);
    base_assert(bar.low==0&&bar.high==20&&bar.valid,"negative values retain validation without changing display scale");
    base_assert(stat_bar_model(0,0,0).valid&&!stat_bar_model(1,0,0).valid,"exact zero goal");
    base_assert(stat_bar_model(-2.5,-3,-2).valid&&stat_bar_model(999,undefined,undefined).valid,"fractions and unrestricted values");
    bar=stat_bar_model(10000,-5000,6);
    base_assert(bar.count==20&&bar.low==0&&bar.high==20&&bar.unit==1,"large values do not rescale the fixed display");
    base_assert(!stat_bar_model(7,10,6).valid&&stat_bar_goal(10,6)=="Invalid bounds","contradictory limits are not valid");
    base_assert(manager.sidebar_width==floor(room_width/3)&&manager.inventory_x+manager.inventory_cols*manager.inventory_size<=manager.sidebar_width,"inventory stays in left third");
    base_assert(manager.inventory_y>manager.stats_height&&manager.inventory_footer+30<=room_height,"inventory uses available height below stats");
    base_assert(manager.order_device.board_x>=manager.sidebar_width&&manager.order_device.board_x+manager.order_device.cols*manager.order_device.cell_size<=room_width,"order board stays in right workspace");
    var saved_inventory=manager.inventory,saved_page=manager.inventory_page;
    manager.inventory=array_create(manager.inventory_capacity,noone);manager.inventory_page=0;
    var page_item=instance_create_depth(0,0,-10,par_module);page_item.visible=false;
    manager.inventory[manager.inventory_capacity-1]=page_item;
    campaign_inventory_page(manager,1);
    base_assert(manager.inventory_page==1&&array_length(manager.inventory)==2*manager.inventory_capacity,"page expansion uses adaptive capacity");
    base_assert(inventory_slot(manager,manager.inventory_x+1,manager.inventory_y+1)==manager.inventory_capacity,"second page clicks map to correct inventory index");
    campaign_inventory_page(manager,1);
    base_assert(manager.inventory_page==1,"empty last page cannot create further pages");
    instance_destroy(page_item);manager.inventory=saved_inventory;manager.inventory_page=saved_page;
    base_assert(module_stat_beneficial("energy",1)&&!module_stat_beneficial("energy",-1),"module energy gain green and consumption red");
    base_assert(module_stat_beneficial("stability",1)&&!module_stat_beneficial("stability",-1),"module stability gain green and loss red");
    base_assert(!module_stat_beneficial("heat",1)&&module_stat_beneficial("heat",-1),"module heat gain red and cooling green");
    base_assert(!module_stat_beneficial("weight",1)&&module_stat_beneficial("weight",-1),"module weight gain red and reduction green");
    for(var dt=0;dt<2;++dt) {
        var test_device=instance_create_depth(0,0,0,dt==0?obj_remote:obj_radio);
        test_device.stats_base={energy:2,heat:-1,stability:0,weight:3};
        test_device.stats_min={energy:2};test_device.stats_max={weight:3};test_device.circuit_connected=true;
        device_stats_update(test_device);
        base_assert(test_device.current_stats.energy==2&&test_device.current_stats.weight==3&&test_device.requirements_met,"non-order device uses own base and requirements");
        test_device.stats_min.energy=4;device_stats_update(test_device);
        base_assert(!test_device.requirements_met,"non-order device rejects unmet own requirement");
        var first_item=manager.inventory[0];campaign_device_layout(manager,test_device);
        base_assert(manager.stats_height==100&&manager.inventory[0]==first_item&&array_length(manager.inventory) mod manager.inventory_capacity==0,"per-device layout preserves inventory contents");
        instance_destroy(test_device);
    }
    manager.order_device.stats_min=saved_order_min;
    campaign_device_layout(manager,manager.order_device);
    base_assert(manager.order_device.stats_min.energy==10&&manager.order_device.stats_max.weight==12,"order requirements belong to obj_order");
    var flow_cfg=ana_test_model();flow_cfg.modules[0].qty="20";flow_cfg.modules[1].qty="20";
    flow_cfg.modules[1].drop_weight="0";flow_cfg.modules[0].stats.energy="1";
    flow_cfg.start_money="999";flow_cfg.loot_min="1";flow_cfg.loot_max="1";flow_cfg.trials="1";
    flow_cfg.use_initial_state=false;
    var flow_model=lab_workflow_model(flow_cfg),flow_job=lab_job(flow_model);
    base_assert(flow_model.econ.start_money==0&&flow_model.items[0].qty==0,"workflow defaults to zero cash and no modules despite configured stock");
    while(flow_job.phase=="count") lab_count_step(flow_job,1000);
    while(flow_job.phase=="simulate") lab_sim_step(flow_job,1000);
    base_assert(flow_job.runs[0].success&&flow_job.runs[0].devices==2&&flow_job.runs[0].clicks==5&&flow_job.runs[0].seconds==115,"zero-start workflow earns buys dismantles until two required modules");
    flow_cfg.use_initial_state=true;flow_model=lab_workflow_model(flow_cfg);
    base_assert(flow_model.econ.start_money==999&&flow_model.items[0].qty==20,"later-order option uses configured initial state");
    var linked_cfg=lab_defaults();ana_defaults(linked_cfg);
    var before_devices=instance_number(par_device),before_parts=instance_number(par_module),before_screws=instance_number(obj_screw);
    lab_sync_game(linked_cfg);
    base_assert(instance_number(par_device)==before_devices&&instance_number(par_module)==before_parts&&instance_number(obj_screw)==before_screws,"game import leaves no devices modules or screws");
    var game_types=game_module_types();
    base_assert(array_length(linked_cfg.modules)==array_length(game_types),"balance imports shared gameplay module list");
    for(var li=0;li<array_length(game_types);++li) {
        var probe=instance_create_depth(-10000,-10000,0,game_types[li]);
        base_assert(linked_cfg.modules[li].name==probe.module_name&&real(linked_cfg.modules[li].drop_weight)==probe.drop_weight&&real(linked_cfg.modules[li].stats.energy)==probe.stats.energy,"import matches actual module Create "+string(li));
        instance_destroy(probe);
    }
    base_assert(real(linked_cfg.min.energy)==manager.order_device.stats_min.energy&&real(linked_cfg.max.weight)==manager.order_device.stats_max.weight,"import matches obj_order goal");
    linked_cfg.modules[0].qty="7";linked_cfg.modules[0].stats.energy="999";linked_cfg.min.energy="999";
    lab_sync_game(linked_cfg);
    base_assert(linked_cfg.modules[0].qty=="7"&&linked_cfg.modules[0].stats.energy!="999"&&linked_cfg.min.energy!="999","refresh preserves inventory but replaces stale duplicated definitions");
    linked_cfg.use_initial_state=false;
    var linked_model=lab_workflow_model(linked_cfg);
    base_assert(linked_model.ok&&linked_model.items[0].qty==0&&linked_model.econ.start_money==0,"linked workflow still starts with zero resources");
    linked_cfg.modules[0].stats.energy="123";linked_cfg.min.energy="8";linked_cfg.max.energy="";
    var custom={name:"Custom test",qty:"2",drop_weight:"3",stats:{energy:"9"}};
    var custom_keys=bal_keys();for(var ck=0;ck<8;++ck) struct_set(custom.stats,custom_keys[ck],"0");custom.stats.energy="9";
    array_push(linked_cfg.modules,custom);
    linked_model=lab_workflow_model(linked_cfg);
    base_assert(linked_model.ok&&linked_model.items[0].stats.energy==123&&linked_model.goal.min.energy==8,"workflow preserves edited game defaults");
    base_assert(array_length(linked_model.items)==array_length(game_types)+1,"workflow preserves added module");
    var rest_job={model:{items:[{},{}]},runs:[
        {success:true,money:10,pending:2,inventory:[1,3]},
        {success:true,money:20,pending:0,inventory:[0,1]},
        {success:false,money:999,pending:9,inventory:[99,99]}]};
    var rest=lab_leftovers(rest_job);
    base_assert(rest.count==2&&rest.money.mean==15&&rest.modules.mean==2.5&&rest.pending.mean==1,"leftovers exclude failed trials and retain unopened devices");
    base_assert(rest.items[0].mean==0.5&&rest.items[0].present==1&&rest.items[1].low==1&&rest.items[1].high==3,"per-type leftovers distribution");
    var finish_job=lab_job(lab_validate(ana_test_model()));
    finish_job.trial=lab_run_start(finish_job);finish_job.trial.inventory=[3,2];finish_job.trial.money=7;finish_job.trial.pending=2;
    lab_finish_run(finish_job,true,[1,1]);rest=lab_leftovers(finish_job);
    base_assert(rest.modules.mean==3&&rest.money.mean==7+finish_job.model.econ.order_price&&rest.pending.mean==2,"post-order stock subtracts recipe and includes reward");
    analyzer_tests();
    show_debug_message("DEVICE_TEST_RESULT passes="+string(global.test_passes)+" failures="+string(global.test_failures));
    game_end();
}

function ana_test_model() {
    var cfg=lab_defaults(),keys=bal_keys();cfg.slots="2";cfg.min_installed="0";cfg.modules=[];
    for(var k=0;k<8;++k) {struct_set(cfg.base,keys[k],"0");struct_set(cfg.min,keys[k],"");struct_set(cfg.max,keys[k],"");}
    for(var i=0;i<2;++i) {
        var m={name:i==0?"A":"B",qty:i==0?"2":"1",drop_weight:"1",stats:{}};
        for(var k=0;k<8;++k) struct_set(m.stats,keys[k],"0");
        m.stats.weight="1";if(i==0) m.stats.energy="2";else m.stats.heat="-1";array_push(cfg.modules,m);
    }
    cfg.min.energy="2";cfg.max.heat="0";cfg.max.weight="2";ana_defaults(cfg);return cfg;
}
function ana_test_finish(_a) {
    var guard=0;while(!ana_finished(_a)&&guard++<10000) ana_step(_a,100);
    base_assert(guard<10000,"analyzer bounded completion");return _a;
}
function ana_test_progress_finish(_p) {
    var guard=0;while((_p.phase=="run"||_p.phase=="devices")&&guard++<10000) ana_progress_step(_p,100);
    base_assert(guard<10000&&_p.phase=="done","progression bounded completion");return _p;
}
function analyzer_tests() {
    var cfg=ana_test_model(),model=lab_validate(cfg),a=ana_test_finish(ana_job(model,ana_inventory(model)));
    base_assert(a.total==5&&a.valid==3&&a.min_modules==1,"inventory multisets counted without permutations");
    base_assert(a.near==2&&a.pressure[0]==2&&a.deviation_min[0]==2&&a.deviation_max[0]==2,"near miss counts and actual deficit");
    base_assert(a.usage[0]==3&&a.usage[1]==1&&a.on_usage[0]==3,"module usage denominator is valid builds");
    base_assert(array_length(a.minimal)==1&&a.minimal[0].counts[0]==1&&a.minimal_usage[1]==0,"redundant modules excluded from minimal builds");
    var legacy=bal_count(model.items,model.goal,0);base_assert(legacy.count==a.valid,"analyzer matches existing balance checker");
    cfg.allow_unpowered=true;model=lab_validate(cfg);a=ana_test_finish(ana_job(model,ana_inventory(model)));
    base_assert(a.total==12&&a.valid==5,"ON OFF states unique with multiplicities");
    cfg.max.weight="1";model=lab_validate(cfg);a=ana_test_finish(ana_job(model,ana_inventory(model)));
    base_assert(a.valid==1&&a.pressure[3]==7,"OFF modules retain weight and consume slots");
    cfg=ana_test_model();cfg.min.energy="0";cfg.max.energy="0";cfg.modules[0].stats.energy="1";cfg.modules[1].stats.energy="-1";
    model=lab_validate(cfg);a=ana_test_finish(ana_job(model,ana_inventory(model)));
    base_assert(a.valid==2&&array_length(a.minimal)==1&&a.minimal[0].total==0,"minimality finds removable pairs, not only single deletions");
    cfg=ana_test_model();cfg.modules[0].qty="0";cfg.modules[1].qty="0";
    model=lab_validate(cfg);a=ana_test_finish(ana_job(model,ana_inventory(model)));
    base_assert(a.total==1&&a.valid==0&&a.near==1,"empty inventory does not include future drops");
    cfg.min_installed="1";model=lab_validate(cfg);a=ana_test_finish(ana_job(model,ana_inventory(model)));
    base_assert(a.total==0&&ana_percent(0,0)=="N/A","zero denominator reported N/A");
    a=ana_job(model,ana_inventory(model));a.limit=1;ana_step(a,100);
    base_assert(a.phase=="limited"&&a.partial,"enumeration cap explicitly partial");
    cfg=ana_test_model();cfg.min.energy="2";cfg.modules[0].stats.energy="1";cfg.modules[0].qty="0";cfg.modules[1].qty="0";cfg.modules[1].drop_weight="0";
    cfg.max.weight="";cfg.loot_min="1";cfg.loot_max="1";cfg.analysis_steps="3";cfg.trials="4";
    model=lab_validate(cfg);var p=ana_test_progress_finish(ana_progress_job(model,cfg));
    base_assert(p.stages[1].hits==0&&p.stages[2].hits==4&&p.stages[3].hits==4,"random progression availability at two devices");
    base_assert(p.stages[2].valid==4&&p.stages[2].total==12&&p.stages[2].known==4,"progression counts and sample denominator");
    base_assert(p.min_status=="N/A","random devices have no invented exact minimum");
    var p2=ana_test_progress_finish(ana_progress_job(model,cfg));
    base_assert(json_stringify(p.stages)==json_stringify(p2.stages),"seed reproducibility");
    cfg.progression_mode=1;cfg.progression_rows=[{name:"Empty",counts:"0,0"},{name:"Enough",counts:"2,0"}];
    p=ana_test_progress_finish(ana_progress_job(model,cfg));
    base_assert(p.stages[1].hits==0&&p.stages[2].hits==1&&p.min_devices==1&&p.min_status=="exact","minimum devices searches any subset, not only prefixes");
    cfg.progression_mode=2;cfg.progression_rows=[{name:"Enough",counts:"2,0"},{name:"Reset",counts:"0,0"}];
    p=ana_test_progress_finish(ana_progress_job(model,cfg));
    base_assert(p.stages[1].hits==1&&p.stages[2].hits==0&&p.min_status=="N/A","snapshots replace inventory rather than accumulating");
    cfg.progression_rows[0].counts="2";base_assert(ana_progress_job(model,cfg).phase=="error","bad device composition rejected");
    cfg.progression_mode=0;cfg.trials="1";model=lab_validate(cfg);p=ana_progress_job(model,cfg);
    p.worker=ana_job(model,p.inventory);p.worker.limit=1;ana_progress_step(p,100);
    base_assert(p.stages[0].unknown==1&&p.stages[0].known==0,"limited progression is unknown rather than false impossibility");
}
