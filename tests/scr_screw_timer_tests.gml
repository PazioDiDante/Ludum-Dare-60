function screw_test_assert(_ok,_message) {
    if(!_ok) throw "SCREW_TIMER_FAILURE: "+_message;
    global.screw_test_passes++;
}
function screw_timer_tests() {
    global.screw_test_passes=0;
    var g=instance_find(obj_game,0);
    screw_test_assert(!variable_instance_exists(g,"debug_tools")&&!variable_global_exists("debug_enabled"),"release has no debug state");
    g.money=0;campaign_earn(g);campaign_solder_plate(g);
    screw_test_assert(g.money==0&&g.earn_remaining==5,"money requires normal five-second action");
    campaign_tick(g,4);screw_test_assert(g.money==0,"no instant debug payout");
    campaign_tick(g,1);screw_test_assert(g.money==20,"normal plate earning pays twenty");
    g.money=25;g.device_types=[obj_remote];campaign_buy(g);
    var d=g.table_devices[0];campaign_open(g,d);
    var screws=[];
    for(var i=0;i<array_length(d.children);++i) {var child=d.children[i];if(instance_exists(child)&&child.object_index==obj_screw) array_push(screws,child);}
    var a=screws[0],b=screws[1],initial=d.remaining;
    screw_test_assert(d.remaining==initial,"cover starts with all screws");
    screw_test_assert(pointer_dispatch(a,mb_left)&&a.unscrewing&&a.unscrew_remaining==2&&d.remaining==initial,"click starts two-second timer without removing screw");
    screw_test_assert(!pointer_dispatch(a,mb_left)&&!pointer_dispatch(b,mb_left)&&g.active_screw==a&&!b.unscrewing,"cannot restart timer or run second screw");
    screw_tick(g,0.5);screw_test_assert(instance_exists(a)&&a.unscrew_remaining==1.5&&d.remaining==initial,"no removal after half a second");
    global.mode=GameMode.Pause;screw_tick(g,10);
    screw_test_assert(a.unscrew_remaining==1.5&&!pointer_dispatch(b,mb_left),"pause freezes action and blocks other screw");global.mode=GameMode.Play;
    screw_tick(g,0.5);screw_test_assert(instance_exists(a)&&d.remaining==initial,"no removal before second second");
    screw_tick(g,1);
    screw_test_assert(!instance_exists(a)&&g.active_screw==noone&&d.remaining==initial-1&&!d.cover_open,"exactly one removal after two seconds");
    screw_test_assert(pointer_dispatch(b,mb_left),"next screw can start after completion");
    screw_tick(g,1);campaign_table(g);
    screw_test_assert(!b.unscrewing&&b.unscrew_remaining==0&&g.active_screw==noone&&d.remaining==initial-1,"returning to table cancels unfinished action");
    campaign_open(g,d);pointer_dispatch(b,mb_left);
    screw_test_assert(b.unscrew_remaining==2,"cancelled screw restarts with full duration");
    var surface=surface_create(1280,720);surface_set_target(surface);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);with(d) event_perform(ev_draw,0);
    screw_tick(g,1);
    for(var i=0;i<array_length(screws);++i) if(instance_exists(screws[i])) with(screws[i]) event_perform(ev_draw,0);
    campaign_gui_draw(g);surface_reset_target();surface_save(surface,"screw-progress-preview.png");surface_free(surface);
    screw_tick(g,2);
    for(var i=2;i<array_length(screws);++i) {pointer_dispatch(screws[i],mb_left);screw_tick(g,2);}
    screw_test_assert(d.remaining==0&&d.cover_open&&g.active_screw==noone,"last completed screw opens cover once");
    var parts=d.placed_modules;screw_tick(g,20);
    screw_test_assert(d.placed_modules==parts,"completed action cannot generate parts twice");
    var another=campaign_create_device(obj_radio);campaign_open(g,another);
    var next=noone;
    for(var i=0;i<array_length(another.children);++i) {var child=another.children[i];if(instance_exists(child)&&child.object_index==obj_screw){next=child;break;}}
    pointer_dispatch(next,mb_left);campaign_open(g,d);
    screw_test_assert(!next.unscrewing&&g.active_screw==noone,"switching workpieces cancels previous timer");
    campaign_open(g,another);pointer_dispatch(next,mb_left);instance_destroy(next);screw_tick(g,0);
    screw_test_assert(g.active_screw==noone,"deleted screw cannot leave action locked");
    show_debug_message("SCREW_TIMER_RESULT passes="+string(global.screw_test_passes)+" failures=0");game_end();
}
