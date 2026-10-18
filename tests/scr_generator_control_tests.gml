function generator_control_assert(_ok,_message) {
    if(!_ok) throw "GENERATOR_CONTROL_FAILURE: "+_message;
    global.generator_control_passes++;
}
function generator_control_snapshot(_g,_name) {
    var surface=surface_create(1280,720);surface_set_target(surface);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    campaign_table_draw(_g);campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    surface_reset_target();surface_save(surface,_name);surface_free(surface);
}
function generator_control_tests() {
    global.generator_control_passes=0;
    var g=instance_find(obj_game,0),gen=g.generator;
    var layout=generator_layout(g);
    generator_control_assert(layout.count==2&&generator_state_sprite(gen)==spr_ON,"initial capacity-sized battery and on icon");
    generator_control_assert(layout.heat_count==1,"zero heat has one empty cell");
    generator_control_assert(layout.panel[2]==layout.control[2]+8,"normal backing has no empty warning slot");
    generator_control_assert(layout.open[2]==layout.control[0],"dedicated modify icon immediately precedes power button");
    generator_control_assert(layout.heat_x==layout.energy_x+layout.count*layout.cell_width,"temperature immediately follows battery cells");
    g.money=100;shop_buy(g,"solder_robot");var robot=g.robots[array_length(g.robots)-1];robot_assign_power(g,robot);
    generator_control_assert(g.power_free==1&&robot.powered&&generator_layout(g).count==2,"allocated energy dims cells without shortening battery");
    var button=layout.control;
    generator_control_assert(generator_click(g,button[0]+10,button[1]+10)&&!gen.running&&generator_state_sprite(gen)==spr_OFF,"on button toggles generator off");
    generator_control_assert(generator_layout(g).count==2&&!robot.powered,"off generator retains all capacity cells");
    generator_click(g,button[0]+10,button[1]+10);
    generator_control_assert(gen.running&&robot.powered,"off button restarts power");
    var open=layout.open;generator_click(g,open[0]+10,open[1]+10);
    generator_control_assert(g.active_device==gen&&!gen.running,"modify icon opens board and isolates power");
    campaign_table(g);generator_restart(g);
    gen.stats_base.heat=3;device_stats_update(gen);gen.failure_remaining=0.001;generator_tick(g,1);
    generator_control_assert(generator_layout(g).heat_count==3,"positive heat draws exactly its own cell count");
    generator_control_assert(gen.broken&&gen.burning&&!gen.running&&g.power_capacity==0&&generator_state_sprite(gen)==spr_broke,"heat failure causes broken burning state");
    generator_control_assert(!generator_restart(g)&&!campaign_open(g,gen),"broken generator cannot start or open board");
    var money=g.money,inventory=json_stringify(g.inventory);
    generator_control_snapshot(g,"generator-broken-preview.png");
    layout=generator_layout(g);button=layout.control;var fire=layout.fire;
    generator_control_assert(layout.panel[2]==fire[2]+8,"backing expands exactly for visible warning");
    generator_control_assert(generator_click(g,fire[0]+10,fire[1]+10)&&gen.repair_remaining==5,"fire icon starts five-second repair");
    generator_tick(g,2);generator_click(g,button[0]+10,button[1]+10);
    generator_control_assert(gen.repair_remaining==3&&gen.burning&&!gen.running,"repeated clicks do not reset repair and fire remains during repair");
    generator_control_snapshot(g,"generator-repair-preview.png");
    global.mode=GameMode.Pause;generator_tick(g,20);
    generator_control_assert(gen.repair_remaining==3,"pause freezes repair progress");global.mode=GameMode.Menu;
    generator_tick(g,2);
    generator_control_assert(gen.broken&&gen.burning&&gen.repair_remaining==1,"repair cannot complete early");
    generator_tick(g,1);
    generator_control_assert(!gen.broken&&!gen.burning&&!gen.running&&gen.repair_remaining==0&&generator_state_sprite(gen)==spr_OFF,"completion removes fire and stays off");
    generator_control_assert(generator_layout(g).panel[2]==generator_layout(g).control[2]+8,"backing shrinks after fire disappears");
    generator_control_assert(g.money==money&&json_stringify(g.inventory)==inventory&&!robot.powered,"repair never charges money consumes parts or starts robots");
    generator_click(g,button[0]+10,button[1]+10);
    generator_control_assert(gen.running&&robot.powered,"separate press starts repaired generator");
    generator_break(g);generator_click(g,button[0]+10,button[1]+10);
    generator_control_assert(gen.repair_remaining==5,"broken icon starts same repair as fire");generator_tick(g,5);
    generator_break(g);generator_click(g,layout.energy_x+2,layout.top+20);
    generator_control_assert(gen.repair_remaining==5,"any part of broken generator row starts repair");generator_tick(g,5);
    gen.stats_base.energy=30;device_stats_update(gen);layout=generator_layout(g);
    generator_control_assert(layout.count==30&&layout.panel[2]<=display_get_gui_width()-8,"energy is not capped at twenty");
    gen.stats_base.energy=100;device_stats_update(gen);layout=generator_layout(g);
    generator_control_assert(layout.count==100&&layout.panel[2]<=display_get_gui_width()-8,"large capacity keeps all lamps on screen");
    gen.stats_base.energy=8;gen.stats_base.stability=0;device_stats_update(gen);
    generator_control_assert(generator_unstable(gen)&&generator_state_sprite(gen)==spr_broke&&!generator_restart(g),"low stability shows broken state and blocks restart");
    generator_control_assert(!gen.broken&&campaign_open(g,gen),"stability warning still allows board access to fix modules");campaign_table(g);
    gen.stats_base.stability=1;device_stats_update(gen);
    generator_control_assert(!generator_unstable(gen)&&generator_state_sprite(gen)==spr_OFF,"fixing stability removes warning and restores off state");
    generator_restart(g);
    generator_control_snapshot(g,"generator-row-preview.png");
    show_debug_message("GENERATOR_CONTROL_RESULT passes="+string(global.generator_control_passes)+" failures=0");game_end();
}
