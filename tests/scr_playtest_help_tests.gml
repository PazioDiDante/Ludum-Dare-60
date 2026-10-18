// Run in an isolated copy: opening guards, per-instance feedback and UI previews.
function playtest_help_assert(_ok,_label) {
    if(!_ok) throw "PLAYTEST_HELP_FAILURE: "+_label;
    global.playtest_help_passes++;
}
function playtest_help_render(_g,_file) {
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    if(global.mode==GameMode.Menu) campaign_table_draw(_g);
    else {
        var d=_g.active_device;
        if(d.is_assembler) assembler_draw(_g,d);
        else {
            with(d) event_perform(ev_draw,0);
            if(d.is_recycler) recycler_board_draw(_g,d);
        }
    }
    campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    if(_g.shop.open) shop_draw(_g.shop);
    surface_reset_target();surface_save(sf,environment_get_variable("FIRST_ORDERS_OUTPUT")+"/"+_file);surface_free(sf);
}
function playtest_help_tests() {
    global.playtest_help_passes=0;
    var g=instance_find(obj_game,0);g.money=10000;
    shop_buy(g,"assembler_robot");shop_buy(g,"recycle_robot");
    shop_buy(g,"solder_robot");shop_buy(g,"dismantle_robot");
    var stacks=robots_table_stacks(g),assembler=stacks[1][0],recycler=stacks[0][1];
    var original=g.active_device,free=g.power_free;
    playtest_help_assert(!campaign_open(g,assembler.board_device),"unpowered assembler stays closed");
    playtest_help_assert(global.mode==GameMode.Menu&&g.active_device==original&&g.power_free==free&&!assembler.power_allocated,"failed open preserves scene and power");
    playtest_help_assert(assembler.power_hint_remaining>0&&recycler.power_hint_remaining==0,"only clicked instance gets feedback");
    robots_tick(g,0.19);
    playtest_help_assert(robot_power_hint_alpha(assembler)==0.2,"warning and cells enter dim phase");
    playtest_help_render(g,"help-no-power-dim.png");
    global.mode=GameMode.Pause;var remaining=assembler.power_hint_remaining;
    robots_tick(g,10);
    playtest_help_assert(assembler.power_hint_remaining==remaining,"pause freezes feedback");
    global.mode=GameMode.Menu;
    var bounds=robot_table_hit_rect(recycler),cx=(bounds[0]+bounds[2])/2,cy=(bounds[1]+bounds[3])/2;
    playtest_help_assert(robots_table_click(g,cx,cy)&&g.active_device==noone&&recycler.power_hint_remaining>0,"table click rejects unpowered recycler");
    var groups=robot_groups(g),layout=robot_row_layout(groups[1],1);
    robots_tick(g,0.2);
    playtest_help_assert(robots_click(g,layout.job[0]+8,layout.job[1]+8)&&g.active_device==noone&&assembler.power_hint_elapsed==0,"panel click rejects assembler and restarts flash");
    playtest_help_render(g,"help-no-power-bright.png");
    robots_tick(g,2);
    playtest_help_assert(assembler.power_hint_remaining==0&&robot_power_hint_alpha(assembler)==1,"feedback ends with steady warning");
    g.generator.stats_base.energy=20;device_stats_update(g.generator);power_update(g);
    playtest_help_assert(robot_assign_power(g,assembler)&&campaign_open(g,assembler.board_device),"powered assembler opens");
    playtest_help_render(g,"help-assembler.png");campaign_table(g);
    playtest_help_assert(robot_assign_power(g,recycler)&&campaign_open(g,recycler.board_device),"powered recycler opens");
    playtest_help_render(g,"help-recycler.png");campaign_table(g);
    generator_stop(g,"test outage");
    playtest_help_assert(!campaign_open(g,recycler.board_device)&&recycler.power_allocated&&!recycler.powered,"outage blocks reserved robot without removing allocation");
    generator_restart(g);
    playtest_help_assert(campaign_open(g,recycler.board_device),"restoring power permits opening");campaign_table(g);
    generator_stop(g,"stale power test");assembler.powered=true;
    playtest_help_assert(!campaign_open(g,assembler.board_device)&&!assembler.powered,"guard refreshes stale power state");
    generator_restart(g);robots_tick(g,0);
    playtest_help_assert(assembler.power_hint_remaining==0&&recycler.power_hint_remaining==0,"power correction clears feedback");
    var donor=g.table_devices[0];campaign_open(g,donor);
    playtest_help_assert(donor.board_y>=160,"donor board leaves room for help");
    playtest_help_render(g,"help-donor.png");donor.open_cover();
    playtest_help_render(g,"help-donor-open.png");campaign_table(g);
    for(var i=0;i<array_length(g.order_types);++i) {
        var d=campaign_create_device(g.order_types[i]);campaign_open(g,d);
        playtest_help_assert(d.board_y>=160&&g.inventory_y>g.stats_height,"order help clears board and inventory");
        playtest_help_render(g,"help-order-"+string(i)+".png");campaign_table(g);instance_destroy(d);
    }
    g.shop.open=true;
    for(var i=0;i<array_length(shop_catalog());++i) {
        g.shop.scroll=i;playtest_help_render(g,"help-shop-"+string(i)+".png");
    }
    show_debug_message("PLAYTEST_HELP_RESULT passes="+string(global.playtest_help_passes)+" failures=0");
    game_end();
}
