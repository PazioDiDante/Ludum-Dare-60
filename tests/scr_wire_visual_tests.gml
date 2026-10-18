function wire_visual_assert(_ok,_message) {
    if(!_ok) throw "WIRE_VISUAL_FAILURE: "+_message;
    global.wire_visual_passes++;
}
function wire_visual_tests() {
    global.wire_visual_passes=0;
    var v=wire_visual_create(40,40,300,40),a=wire_curve_point(40,40,300,40,0,v),b=wire_curve_point(40,40,300,40,1,v);
    wire_visual_assert(a.x==40&&a.y==40&&b.x==300&&b.y==40,"animated endpoints remain attached");
    var mid=wire_curve_point(40,40,300,40,0.5);
    wire_visual_assert(mid.y>40,"resting horizontal wire sags");
    wire_visual_assert(wire_curve_point(40,40,40,300,0.5).x!=40,"vertical wires have a visible bow");
    wire_visual_assert(wire_curve_point(40,40,40,40,0.5,v).x==40,"coincident endpoints stay finite");
    wire_visual_tick(v,40,40,300,40,2);
    a=wire_curve_point(40,40,300,40,0.5,v);
    wire_visual_assert(a.x==mid.x&&a.y==mid.y&&v.quiet_time==2,"motion completely settles at two seconds");
    wire_visual_tick(v,50,40,300,40,0.01);
    wire_visual_assert(v.quiet_time==0,"moving an endpoint restarts sway");
    wire_visual_tick(v,50,40,300,40,0.5);
    wire_visual_assert(v.quiet_time==0.5,"stationary endpoint damps again");
    var palette=[make_color_rgb(65,135,255),make_color_rgb(55,205,100),make_color_rgb(240,70,75)],last=-1,valid=true;
    for(var i=0;i<30;++i) {var color=wire_visual_color();valid=valid&&color!=last&&(color==palette[0]||color==palette[1]||color==palette[2]);last=color;}
    wire_visual_assert(valid,"persistent random colours use blue green red and alternate");
    random_set_seed(9876);var expected=random(1000);random_set_seed(9876);
    repeat(10) wire_visual_create(0,0,100,100);
    wire_visual_assert(random(1000)==expected,"cosmetics never consume gameplay randomness");
    var g=instance_find(obj_game,0),d=g.generator;campaign_open(g,d);
    var left=instance_create_depth(0,0,-10,obj_module_battery);left.device=d;array_push(d.children,left);board_place(left,2,3);
    var right=instance_create_depth(0,0,-10,obj_module_battery);right.device=d;array_push(d.children,right);board_place(right,6,3);
    var p=port_reference(left,0,0),q=port_reference(right,0,0);
    wire_click(d,p);var preview_color=d.wire_draft.color;wire_click(d,q);
    var wire=d.wires[0];
    wire_visual_assert(wire.visual.color==preview_color&&is_undefined(d.wire_draft),"attachment keeps preview colour and clears draft");
    var checks=d.circuit_check_count;
    wire_visual_update(d,2);
    wire_visual_assert(wire.visual.quiet_time==2&&d.circuit_check_count==checks,"settling never recomputes circuit");
    left.x+=24;wire_visual_update(d,0.01);
    wire_visual_assert(wire.visual.quiet_time==0,"actual module motion triggers sway");
    global.mode=GameMode.Pause;var state=json_stringify(wire.visual);wire_visual_update(d,1);
    wire_visual_assert(json_stringify(wire.visual)==state,"pause freezes sway");global.mode=GameMode.Play;
    var surface=surface_create(520,360);surface_set_target(surface);draw_clear(make_color_rgb(20,27,38));
    for(var i=0;i<3;++i) {
        var sample=wire_visual_create(40,40+i*100,460,40+i*100,palette[i]);sample.quiet_time=2;
        wire_curve_draw(40,40+i*100,460,40+i*100,sample);
    }
    state=json_stringify(wire.visual);wire_draw(d);
    surface_reset_target();surface_save(surface,"wire-parabola-preview.png");surface_free(surface);
    wire_visual_assert(json_stringify(wire.visual)==state,"drawing cannot advance animation");
    wire_click(d,p);wire_cancel(d);
    wire_visual_assert(is_undefined(d.wire_start)&&is_undefined(d.wire_draft),"cancel clears preview animation");
    show_debug_message("WIRE_VISUAL_RESULT passes="+string(global.wire_visual_passes)+" failures=0");game_end();
}
