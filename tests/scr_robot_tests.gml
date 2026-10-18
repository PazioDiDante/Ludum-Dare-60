// Standalone suite: inject in a copy, call robot_tests() after obj_game initialization.
function robot_assert(_ok,_message) {
    if(!_ok) throw "ROBOT_TEST_FAILURE: "+_message;
    global.robot_test_passes++;
}
function robot_test_parts(_device) {
    var parts=[];
    for(var i=0;i<instance_number(par_module);++i) {
        var m=instance_find(par_module,i);if(m.device==_device&&!m.in_inventory) array_push(parts,m);
    }
    return parts;
}
function robot_test_inventory(_g) {
    var parts=[];
    for(var i=0;i<array_length(_g.inventory);++i) if(instance_exists(_g.inventory[i])) array_push(parts,_g.inventory[i]);
    return parts;
}
function robot_tests() {
    global.robot_test_passes=0;
    var g=instance_find(obj_game,0),gen=g.generator;
    // Capacity edge cases use an isolated fleet of two-energy fixtures.
    // The real one-energy products and starting recycler are covered separately.
    instance_destroy(g.recycler_robot);g.recycler_robot=noone;g.robots=[];
    // This suite exercises random donors; starter sets have their own coverage.
    for(var i=0;i<array_length(g.table_devices);++i) instance_destroy(g.table_devices[i]);
    g.table_devices=[];g.campaign_devices_created=2;
    g.debug_tools=false;g.money=400;
    robot_assert(array_length(shop_catalog())==5&&array_length(g.robots)==0,"three robot products and two upgrades, empty fleet");
    robot_assert(!shop_buy(g,"missing")&&g.money==400,"unknown product does not charge");
    robot_assert(shop_buy(g,"solder_robot")&&shop_buy(g,"solder_robot")&&shop_buy(g,"solder_robot")&&shop_buy(g,"dismantle_robot"),"repeatable purchases");
    robot_assert(g.money==0&&shop_count(g,"solder_robot")==3&&shop_count(g,"dismantle_robot")==1,"price 100 per machine and correct counts");
    robot_assert(!shop_buy(g,"solder_robot")&&array_length(g.robots)==4,"no funds, no new machine");
    shop_apply(g);shop_apply(g);
    robot_assert(array_length(g.robots)==4&&g.power_used==0,"reapplying never duplicates robots, idle draws zero");
    var a=g.robots[0],b=g.robots[1],c=g.robots[2],dismantler=g.robots[3];
    for(var i=0;i<array_length(g.robots);++i) g.robots[i].energy_cost=2;
    robot_assert(!a.power_allocated&&!b.power_allocated&&!c.power_allocated,"purchases start with empty power cells");
    robot_assert(robot_assign_power(g,a)&&a.powered&&g.power_free==0,"left allocation reserves the complete energy cost");
    robot_assert(!robot_assign_power(g,a)&&!robot_assign_power(g,b)&&!b.power_allocated&&g.power_used==2,"duplicate and insufficient allocations cannot spend power");
    campaign_earn(g);robot_assert(robot_start(g,a)&&!robot_start(g,a),"one plate job per click, busy cannot restart");
    robot_assert(!robot_start(g,b)&&!b.working&&b.remaining==0&&a.powered&&!b.powered&&g.power_demand==2&&g.power_used==2,"unpowered start does nothing and never allocates power");
    robots_tick(g,4);
    robot_assert(a.remaining==6&&b.remaining==0&&g.money==0,"unpowered robot has no pending timer");
    campaign_open(g,g.order_device);robots_tick(g,6);
    robot_assert(g.money==20&&!a.working&&a.powered&&!b.powered&&b.remaining==0,"completed job retains allocation instead of transferring it");
    campaign_table(g);robot_release_power(g,a);robot_assign_power(g,b);campaign_earn(g);robot_start(g,b);campaign_open(g,g.order_device);
    robots_tick(g,10);robots_tick(g,100);
    robot_assert(g.money==40&&!b.working&&!c.working,"exact single payouts, no automatic repeat or idle income");
    campaign_table(g);robot_release_power(g,b);robot_assign_power(g,c);campaign_earn(g);robot_start(g,c);robots_tick(g,2);
    robot_release_power(g,c);robots_tick(g,20);
    robot_assert(c.remaining==8&&!c.powered&&g.power_free==2,"right release returns energy and preserves job progress");
    robot_assign_power(g,c);
    generator_stop(g,"test");robots_tick(g,50);
    robot_assert(c.remaining==8&&g.money==40,"outage preserves timer");
    generator_restart(g);global.mode=GameMode.Pause;robots_tick(g,50);
    robot_assert(c.remaining==8,"pause freezes progress");
    global.mode=GameMode.Menu;robots_tick(g,8);
    robot_assert(g.money==60&&!c.working,"resume finishes once");
    robot_finish(g,c);
    robot_assert(g.money==60,"direct repeated finish cannot duplicate payout");
    robot_assert(!robot_start(g,dismantler)&&!dismantler.working,"empty table does not start dismantling");
    robot_release_power(g,c);
    g.money=50;g.device_types=[obj_remote];campaign_buy(g);g.device_types=[obj_radio];campaign_buy(g);
    var first=g.table_devices[0],second=g.table_devices[1];
    robot_assert(!robot_start(g,dismantler)&&!dismantler.working&&dismantler.remaining==0&&dismantler.target_device==noone&&array_length(g.table_devices)==2&&g.table_devices[0]==first&&first.automation_owner==noone,"unpowered dismantler leaves donor and timer untouched");
    robot_assign_power(g,dismantler);
    // Same generation path, same seed: robot loot must match a manual opening.
    var reference=campaign_create_device(obj_remote);reference.campaign=true;
    random_set_seed(4242);reference.open_cover();
    var expected=[],refparts=robot_test_parts(reference);
    for(var i=0;i<array_length(refparts);++i) array_push(expected,refparts[i].object_index);
    array_sort(expected,true);instance_destroy(reference);
    robot_assert(robot_start(g,dismantler)&&dismantler.target_device==first&&array_length(g.table_devices)==1&&g.table_devices[0]==second,"reserves first device and leaves next on table");
    robot_assert(!campaign_open(g,first)&&!robot_start(g,dismantler),"reserved workpiece cannot be opened or taken twice");
    robots_tick(g,29);
    robot_assert(instance_exists(first)&&array_length(robot_test_inventory(g))==0,"no early loot before thirty seconds");
    random_set_seed(4242);robots_tick(g,1);
    var obtained=robot_test_inventory(g),actual=[];
    for(var i=0;i<array_length(obtained);++i) array_push(actual,obtained[i].object_index);
    array_sort(actual,true);
    robot_assert(json_stringify(actual)==json_stringify(expected),"robot generates exactly the manual device loot for same seed");
    robot_assert(!instance_exists(first)&&!dismantler.working&&array_length(dismantler.outputs)==0,"finished donor destroyed, all loot safely stored");
    robots_tick(g,60);
    robot_assert(array_length(robot_test_inventory(g))==array_length(obtained),"loot cannot be awarded twice");
    campaign_open(g,second);second.open_cover();
    var original=robot_test_parts(second),removed=original[0];
    module_detach(removed);inventory_add(g,removed);campaign_table(g);
    robot_start(g,dismantler);campaign_open(g,g.order_device);robots_tick(g,30);
    var all_preserved=true;
    for(var i=0;i<array_length(original);++i) all_preserved=all_preserved&&instance_exists(original[i])&&original[i].in_inventory&&original[i].device==noone;
    robot_assert(all_preserved&&!instance_exists(second),"partially opened donor returns original remaining parts without reroll, during another assembly");
    campaign_table(g);g.money=150;shop_buy(g,"dismantle_robot");
    var second_robot=g.robots[4];second_robot.energy_cost=2;campaign_buy(g);campaign_buy(g);
    gen.stats_base.energy=4;device_stats_update(gen);
    robot_assign_power(g,second_robot);
    robot_start(g,dismantler);robot_start(g,second_robot);
    robot_assert(dismantler.target_device!=second_robot.target_device&&array_length(g.table_devices)==0&&g.power_used==4,"two dismantlers reserve different devices and sum power");
    var cols=g.inventory_cols;g.inventory_cols=1;robots_tick(g,30);
    robot_assert(array_length(dismantler.outputs)+array_length(second_robot.outputs)>0,"oversized loot waits on robot rather than disappearing");
    g.inventory_cols=cols;robots_tick(g,0);
    robot_assert(array_length(dismantler.outputs)==0&&array_length(second_robot.outputs)==0,"waiting loot stored when capacity returns");
    robot_assert(instance_exists(g.order_device)&&instance_exists(gen),"orders and generator survive automation");
    g.robot_stack_front[2]=0;g.robot_stack_front[3]=0;
    var rect=robot_card_rect(0);
    robot_release_power(g,dismantler);robot_release_power(g,second_robot);
    robot_assert(robots_click(g,rect[0]+54,rect[1]+16)&&a.power_allocated&&!a.working,"click on robot energy cells only allocates energy");
    robot_assert(robots_click(g,rect[0]+5,rect[1]+5,mb_right)&&!a.power_allocated&&g.power_free==4,"right click releases the full reservation");
    var job=robot_job_rect(0);
    robot_assert(robots_click(g,job[0]+5,job[1]+5)&&!a.working&&a.remaining==0&&!a.power_allocated,"play button does nothing without energy");
    robots_click(g,rect[0]+54,rect[1]+16);
    campaign_earn(g);
    robot_assert(robots_click(g,job[0]+5,job[1]+5)&&a.working,"play starts normally after energy is assigned");
    var groups=robot_groups(g);
    robot_assert(array_length(groups)==2&&array_length(groups[0].machines)==3&&array_length(groups[1].machines)==2,"robots grouped by type in separate rows");
    var battery=generator_energy_rect(),solder_row=robot_card_rect(0,0),dismantle_row=robot_card_rect(0,1);
    robot_assert(battery[1]>solder_row[3]&&solder_row[1]>dismantle_row[3],"bottom-up order is generator, solder, dismantle");
    robot_assert(solder_row[2]-solder_row[0]==136&&solder_row[3]-solder_row[1]==48,"compact controls have shared fixed dimensions");
    robots_click(g,dismantle_row[0]+54,dismantle_row[1]+16);
    robot_assert(dismantler.power_allocated&&a.power_allocated,"second row click targets dismantler without affecting solder robot");
    robots_click(g,dismantle_row[0]+5,dismantle_row[1]+5,mb_right);
    robot_assert(!dismantler.power_allocated&&a.power_allocated,"second row right click releases only its robot");
    robots_tick(g,5);
    var surface=surface_create(1280,720);surface_set_target(surface);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    campaign_table_draw(g);campaign_gui_draw(g);generator_draw(g);robots_draw(g);shop_draw(g.shop);
    surface_reset_target();surface_save(surface,"robots-table-preview.png");surface_free(surface);
    g.money=1000;
    repeat(6) shop_buy(g,"solder_robot");
    g.robot_stack_front[2]=0;g.robot_stack_front[3]=0;
    var arrow=robot_stack_arrow(2,true);
    robot_assert(campaign_table_click(g,arrow[0]+5,arrow[1]+5)&&g.robot_stack_front[2]==1&&g.robot_stack_front[3]==0,"stack selection changes only the matching type");
    show_debug_message("ROBOT_TEST_RESULT passes="+string(global.robot_test_passes)+" failures=0");game_end();
}
