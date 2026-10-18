// Isolated runner suite. Inject as Script; call power_tests() after initialization.
function power_test_assert(_value,_message) {
    if(!_value) throw "POWER_TEST_FAILURE: "+_message;
    global.power_test_passes++;
}
function power_tests() {
    global.power_test_passes=0;
    var g=instance_find(obj_game,0),gen=g.generator;
    g.debug_tools=false;
    power_test_assert(instance_exists(gen)&&gen.cover_open&&gen.running,"generator starts available");
    power_test_assert(gen.installed_count==0&&gen.current_stats.energy==2,"built-in core, no free modules");
    g.money=200;shop_buy(g,"solder_robot");shop_buy(g,"solder_robot");
    var first=g.robots[1],second=g.robots[2];robot_assign_power(g,first);campaign_earn(g);robot_start(g,first);robot_start(g,second);
    power_test_assert(g.power_demand==1&&g.power_used==1&&first.powered&&!second.powered,"shared capacity with explicit allocation");
    var cash=g.money;robots_tick(g,10);
    power_test_assert(g.money==cash+20,"powered plate pays twenty");
    generator_stop(g,"test");robots_tick(g,10);
    power_test_assert(g.power_capacity==0&&!first.powered&&!second.powered&&g.money==cash+20,"shutdown disables all upgrades without erasing purchases");
    power_test_assert(shop_owned(g,"solder_robot")&&generator_restart(g),"manual restart retains purchases");
    var hazard=gen.failure_remaining;
    generator_tick(g,100);
    power_test_assert(gen.running&&gen.failure_remaining==hazard,"zero heat never trips");
    campaign_open(g,gen);
    power_test_assert(!gen.running&&g.power_capacity==0,"opening board isolates power");
    power_test_assert(!campaign_finish(g)&&!campaign_sell(g),"generator cannot be scrapped or sold");
    var battery=instance_create_depth(0,0,0,obj_module_battery);battery.device=gen;
    array_push(gen.children,battery);board_place(battery,1,1);
    var stabilizer=instance_create_depth(0,0,0,obj_module_stabilizer);stabilizer.device=gen;
    array_push(gen.children,stabilizer);board_place(stabilizer,4,1);
    wire_connect(gen,board_port_reference(gen,0),port_reference(battery,0,0));
    wire_connect(gen,port_reference(battery,1,0),port_reference(stabilizer,0,0));
    wire_connect(gen,port_reference(stabilizer,2,0),board_port_reference(gen,1));
    power_test_assert(gen.current_stats.energy==4&&gen.current_stats.heat==3&&gen.current_stats.stability==3,"wired modules modify energy heat and stability");
    campaign_table(g);
    robot_start(g,first);
    power_test_assert(generator_restart(g)&&robot_assign_power(g,second)&&first.powered&&second.powered&&g.power_used==2,"expanded generator supports manual allocation to both robots");
    gen.failure_remaining=0.02;
    generator_tick(g,1);
    power_test_assert(!gen.running&&g.power_used==0,"heat hazard trips generator and power together");
    power_test_assert(!generator_restart(g)&&gen.broken&&gen.burning,"fire requires repair before restart");
    generator_begin_repair(g);generator_tick(g,gen.repair_seconds);
    power_test_assert(!gen.running&&!gen.broken&&!gen.burning&&generator_restart(g),"repair leaves generator off until manual restart");
    gen.failure_remaining=0.02;global.mode=GameMode.Pause;generator_tick(g,100);
    power_test_assert(gen.running&&gen.failure_remaining==0.02,"pause freezes hazard");
    global.mode=GameMode.Menu;
    gen.stats_base.stability=-10;device_stats_update(gen);generator_tick(g,0);
    power_test_assert(!gen.running&&!generator_restart(g),"below minimum stops and blocks restart");
    gen.stats_base.stability=1;device_stats_update(gen);generator_restart(g);
    campaign_open(g,gen);campaign_table(g);
    power_test_assert(instance_exists(battery)&&instance_exists(stabilizer)&&gen.installed_count==2,"installed modules survive reopening");
    var r=generator_table_rect();
    power_test_assert(campaign_table_click(g,r[0]+8,r[1]+8)&&g.active_device==gen,"table generator opens board");
    campaign_table(g);
    var s=surface_create(1280,720);surface_set_target(s);draw_clear(c_black);
    campaign_table_draw(g);campaign_gui_draw(g);generator_draw(g);
    surface_reset_target();surface_save(s,"power-table-preview.png");surface_free(s);
    show_debug_message("POWER_TEST_RESULT passes="+string(global.power_test_passes)+" failures=0");
    game_end();
}
