function port_hitbox_assert(_ok,_message) {
    if(!_ok) throw "PORT_HITBOX_FAILURE: "+_message;
    global.port_hitbox_passes++;
}
function port_hitbox_tests() {
    global.port_hitbox_passes=0;
    var g=instance_find(obj_game,0),d=g.generator;campaign_open(g,d);
    var a=instance_create_depth(0,0,-10,obj_module_battery);a.device=d;
    var b=instance_create_depth(0,0,-10,obj_module_battery);b.device=d;
    array_push(d.children,a);array_push(d.children,b);board_place(a,2,3);board_place(b,6,3);
    var pa=port_reference(a,0,0),pb=port_reference(b,0,0),ap=port_current(pa),bp=port_current(pb),radius=d.wire_snap_radius;
    var pickup=min(d.wire_pick_radius,d.cell_size*0.25);
    port_hitbox_assert(is_undefined(port_find(d,ap.x,ap.y-pickup)),"test point is outside the visible contact");
    port_hitbox_assert(port_equal(port_find_snap(d,ap.x,ap.y-pickup),pa),"first-click hitbox includes smaller pickup radius");
    port_hitbox_assert(is_undefined(port_find_snap(d,ap.x,ap.y-pickup-1)),"outside pickup radius cannot start wire");
    port_hitbox_assert(is_undefined(port_find_snap(d,ap.x,ap.y-radius)),"attachment radius no longer steals first clicks");
    port_hitbox_assert(wire_input(d,ap.x,ap.y-pickup,true,false)&&port_equal(d.wire_start,pa)&&d.selected_module==noone,"nearby first click starts wire instead of grabbing module");
    port_hitbox_assert(d.wire_mouse_x==ap.x&&d.wire_mouse_y==ap.y,"new draft begins snapped to contact centre");
    port_hitbox_assert(port_equal(port_find_snap(d,bp.x,bp.y-radius),pb),"attachment has identical radius");
    wire_input(d,bp.x,bp.y-radius,true,false);
    port_hitbox_assert(is_undefined(d.wire_start)&&wire_for_port(d,pb)>=0,"nearby second click connects");
    wire_input(d,ap.x,ap.y-pickup,true,false);
    port_hitbox_assert(port_equal(d.wire_start,pa)&&array_length(d.wires)==0,"nearby occupied-port click lifts existing wire");
    port_hitbox_assert(is_undefined(port_find_snap(d,ap.x,ap.y-radius)),"draft still excludes its source module");
    wire_cancel(d);a.visible=false;
    port_hitbox_assert(is_undefined(port_find_snap(d,ap.x,ap.y-radius)),"hidden module has no enlarged hitbox");a.visible=true;
    var board_ref=board_port_reference(d,0),board_pos=port_current(board_ref),near_x=board_pos.x-radius;
    // Use its actual centre to avoid assuming which board edge was generated.
    port_hitbox_assert(port_equal(port_find_snap(d,board_pos.x,board_pos.y),board_ref),"fixed board contact retains priority");
    global.mode=GameMode.Pause;
    port_hitbox_assert(!wire_input(d,ap.x,ap.y-radius,true,false)&&is_undefined(d.wire_start),"pause blocks expanded port clicks");
    global.mode=GameMode.Play;a.visible=false;b.visible=false;d.board_ports=[];d.cell_size=16;
    var small=instance_create_depth(700,350,-10,par_module);small.device=d;small.shape=[[Cell.LR]];array_push(d.children,small);
    port_hitbox_assert(is_undefined(port_find_snap(d,708,358))&&!wire_input(d,708,358,true,false),"centre of 16px single-cell module is not stolen by nearby ports");
    port_hitbox_assert(board_pick(small,708,358)&&d.selected_module==small,"single-cell module remains easy to pick up by its centre");
    show_debug_message("PORT_HITBOX_RESULT passes="+string(global.port_hitbox_passes)+" failures=0");game_end();
}
