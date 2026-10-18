// Isolated integration checks for failed robot power allocation feedback.
function power_hint_assert(_ok,_label) {
    if(!_ok) throw "POWER_HINT_FAILURE: "+_label;
    global.power_hint_passes++;
}
function power_hint_snapshot(_g,_name) {
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    campaign_table_draw(_g);campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    surface_reset_target();
    var l=generator_layout(_g);
    var pixels={energy:surface_getpixel(sf,l.energy_x+floor(l.cell_width/2),l.top+24),
        heat:surface_getpixel(sf,l.heat_bar_x+floor(l.cell_width/2),l.top+24)};
    surface_save(sf,_name);surface_free(sf);return pixels;
}
function power_hint_tests() {
    global.power_hint_passes=0;
    var g=instance_find(obj_game,0),gen=g.generator,r=g.recycler_robot;
    g.money=200;shop_buy(g,"solder_robot");shop_buy(g,"solder_robot");
    var a=g.robots[1],b=g.robots[2];
    gen.stats_base.heat=1;device_stats_update(gen);gen.failure_remaining=1000;
    power_hint_assert(robot_assign_power(g,a)&&g.power_free==1,"allocate one real robot before testing shortage");
    var row=robot_row_layout(robot_groups(g)[0],0),cell=row.energy[0].rect;
    power_hint_assert(robots_click(g,cell[0]+4,cell[1]+4)&&gen.power_hint=="energy"&&!r.power_allocated&&a.powered&&g.power_used==1,"clicking unaffordable two-energy robot hints without changing allocations");
    var dim=power_hint_snapshot(g,"power-hint-energy-dim.png");
    generator_tick(g,0.2);var bright=power_hint_snapshot(g,"power-hint-energy-bright.png");
    power_hint_assert(dim.energy!=bright.energy&&dim.heat==bright.heat,"actual energy lamps blink while temperature stays unchanged");
    power_hint_assert(generator_state_sprite(gen)==spr_ON,"shortage leaves the generator control in its real on state");
    generator_tick(g,2);
    power_hint_assert(gen.power_hint==""&&g.power_used==1&&a.powered,"shortage hint expires without changing power");
    robot_assign_power(g,r);generator_tick(g,0.8);robot_assign_power(g,r);
    power_hint_assert(gen.power_hint_elapsed==0&&gen.power_hint_remaining>1,"repeated rejected clicks restart feedback");
    power_hint_assert(robot_assign_power(g,b)&&gen.power_hint==""&&g.power_used==2,"successful smaller allocation clears stale shortage feedback");
    generator_stop(g,"test");
    power_hint_assert(!robot_assign_power(g,r)&&gen.power_hint=="start"&&!gen.running&&!gen.broken&&!r.power_allocated,"off generator failure requests start without pretending to break it");
    power_hint_assert(generator_state_sprite(gen)==spr_broke,"off feedback starts with a visible alternate sprite");
    power_hint_snapshot(g,"power-hint-start-broke.png");generator_tick(g,0.2);
    power_hint_assert(generator_state_sprite(gen)==spr_OFF,"off feedback alternates to the off sprite");
    power_hint_snapshot(g,"power-hint-start-off.png");
    power_hint_assert(!robot_assign_power(g,a)&&gen.power_hint_elapsed==0&&a.power_allocated,"clicking a reserved unpowered robot also points to generator start");
    global.mode=GameMode.Pause;generator_tick(g,5);
    power_hint_assert(gen.power_hint_elapsed==0,"pause freezes feedback with the rest of the game");global.mode=GameMode.Menu;
    generator_tick(g,2);
    power_hint_assert(gen.power_hint==""&&generator_state_sprite(gen)==spr_OFF,"off feedback finishes in the true off state");
    robot_assign_power(g,r);power_hint_assert(generator_restart(g)&&gen.power_hint==""&&a.powered&&b.powered,"turning on clears feedback and restores existing reservations");
    robot_assign_power(g,r);robot_release_power(g,b);
    power_hint_assert(gen.power_hint==""&&g.power_free==1,"releasing power clears stale lamp feedback");
    gen.stats_base.energy=0;device_stats_update(gen);power_update(g);
    power_hint_assert(!robot_assign_power(g,r)&&gen.power_hint=="energy"&&generator_layout(g).count==0,"zero capacity still highlights the energy icon");
    generator_break(g);robot_assign_power(g,r);generator_begin_repair(g);
    power_hint_assert(gen.power_hint==""&&gen.repair_remaining==5,"starting a real repair clears the hint");
    show_debug_message("POWER_HINT_RESULT passes="+string(global.power_hint_passes)+" failures=0");game_end();
}
