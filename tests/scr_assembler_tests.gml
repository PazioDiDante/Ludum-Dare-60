// Isolated Runner suite. Uses real purchase, allocation, inventory and recycler paths.
function assembler_assert(_ok,_label) {
    if(!_ok) throw "ASSEMBLER_FAILURE: "+_label;
    global.assembler_passes++;
}
function assembler_test_capture(_g,_name) {
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    with(_g) event_perform(ev_draw,0);
    campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    surface_reset_target();surface_save(sf,environment_get_variable("ASSEMBLER_TEST_OUTPUT")+"/"+_name+".png");surface_free(sf);
}
function assembler_tests() {
    global.assembler_passes=0;
    global.recycler_passes=0; // Shared real inventory-to-recycler helper assertions.
    var g=instance_find(obj_game,0),gen=g.generator;
    var types=game_module_types(),count=instance_number(par_module);
    g.money=99;
    assembler_assert(!shop_buy(g,"assembler_robot")&&g.money==99,"unaffordable robot leaves coins unchanged");
    g.money=200;
    assembler_assert(shop_buy(g,"assembler_robot")&&g.money==100,"assembler purchase costs 100 coins");
    var r=g.robots[array_length(g.robots)-1],d=r.board_device;
    assembler_assert(r.energy_cost==3&&r.work_seconds==30&&!r.powered,"three-energy thirty-second product");
    assembler_assert(d.is_assembler&&d.cover_open&&array_length(d.board_ports)==0,"persistent portless assembler screen");
    assembler_assert(array_length(r.recipes)==array_length(types)&&instance_number(par_module)==count,"complete catalog without leaked probe instances");
    for(var i=0;i<array_length(r.recipes);++i) {
        var recipe=r.recipes[i],item=instance_create_depth(0,0,0,recipe.object_type);
        assembler_assert(item.scrap_cost>0&&recipe.scrap_cost==item.scrap_cost,"authored module cost "+string(i));
        assembler_assert(json_stringify(recipe.stats)==json_stringify(item.stats)&&json_stringify(recipe.shape)==json_stringify(item.shape),"authored stats and shape "+string(i));
        instance_destroy(item);
    }
    g.order_index=0;
    assembler_assert(array_length(assembler_available(g,r))==8,"tier one catalog respects progression");
    assembler_assert(!robot_assign_power(g,r)&&!r.power_allocated,"base two-energy generator cannot power assembler");
    gen.stats_base.energy=8;device_stats_update(gen);power_update(g);
    assembler_assert(robot_assign_power(g,r)&&r.powered&&g.power_used==3,"player allocates exactly three energy");
    assembler_assert(!robot_start(g,r),"generic start cannot invent a recipe");
    assembler_assert(campaign_open(g,d)&&g.active_device==d,"assembler opens its persistent catalog");
    assembler_assert(!campaign_finish(g)&&!campaign_sell(g)&&instance_exists(d),"assembler cannot be sold or discarded");
    g.scrap=100;
    assembler_assert(!assembler_start(g,r,8)&&g.scrap==100,"locked recipe cannot charge scrap");
    assembler_assert(!assembler_start(g,r,-1)&&!assembler_start(g,r,999),"invalid recipe rejected");
    g.scrap=1;
    assembler_assert(!assembler_start(g,r,0)&&g.scrap==1&&!r.working,"insufficient scrap rejected");
    var button=assembler_page_rect(g,true);g.pointer_ready=true;global.actions[Action.Primary].pressed=true;
    assembler_assert(assembler_input(g,button[0]+4,button[1]+4)&&r.recipe_scroll==4,"next-page hitbox changes list");
    button=assembler_page_rect(g,false);
    assembler_assert(assembler_input(g,button[0]+4,button[1]+4)&&r.recipe_scroll==0,"previous-page hitbox returns list");
    g.scrap=20;
    button=assembler_row_rect(g,0);
    assembler_assert(assembler_input(g,button[2]-20,button[3]-12)&&r.working&&g.scrap==18&&g.money==100,"recipe price hitbox starts and charges once in scrap");
    global.actions[Action.Primary].pressed=false;
    var output=r.target_module;
    assembler_assert(instance_exists(output)&&!output.visible&&!output.in_inventory&&output.object_index==obj_module_battery,"reserved output is exact physical module");
    assembler_assert(!assembler_start(g,r,1)&&g.scrap==18&&r.target_module==output,"double click cannot queue or charge twice");
    robots_tick(g,15);
    assembler_assert(r.remaining==15&&!output.in_inventory,"not delivered early");
    assembler_test_capture(g,"assembler-working-preview");
    campaign_table(g);generator_stop(g,"test outage");robots_tick(g,100);
    assembler_assert(r.remaining==15&&g.scrap==18&&instance_exists(output),"power loss preserves progress and payment");
    assembler_assert(generator_restart(g)&&r.powered,"generator restart restores allocation");
    global.mode=GameMode.Pause;robots_tick(g,100);
    assembler_assert(r.remaining==15,"pause freezes job");global.mode=GameMode.Menu;
    assembler_assert(robot_release_power(g,r),"energy release allowed during job");robots_tick(g,100);
    assembler_assert(r.remaining==15,"energy release freezes job");
    assembler_assert(robot_assign_power(g,r),"energy reassignment resumes job");
    robots_tick(g,14);
    assembler_assert(r.remaining==1&&!output.in_inventory,"full thirty powered seconds required");
    robots_tick(g,1);
    assembler_assert(!r.working&&r.target_module==noone&&output.in_inventory&&output.interaction_enabled,"completion delivers usable module to inventory");
    var inventory_count=0;
    for(var i=0;i<array_length(g.inventory);++i) if(g.inventory[i]==output) inventory_count++;
    robot_finish(g,r);
    assembler_assert(inventory_count==1&&g.scrap==18&&array_length(r.outputs)==0,"output delivered exactly once");
    var recycle=g.recycler_robot;
    recycler_test_feed(g,recycle,output,0,0);campaign_table(g);
    assembler_assert(robot_assign_power(g,recycle),"crafted part can be fed into powered recycler");
    robots_tick(g,0);robots_tick(g,30);
    assembler_assert(!instance_exists(output)&&g.scrap==19,"crafted part recycles for half its cost");
    robot_finish(g,recycle);assembler_assert(g.scrap==19,"recycling payout cannot duplicate");
    campaign_open(g,d);g.order_index=3;
    assembler_assert(array_length(assembler_available(g,r))==16,"all tier two recipes unlocked");
    // An odd authored price verifies exact half, without rounding away scrap.
    var expensive=instance_create_depth(0,0,-10,obj_module_big_boy);expensive.scrap_cost=7;
    expensive.device=recycle.board_device;array_push(recycle.board_device.children,expensive);board_place(expensive,0,0);
    robots_tick(g,0);robots_tick(g,30);
    assembler_assert(g.scrap==22.5&&!instance_exists(expensive),"recycler returns 3.5 scrap for cost seven");
    assembler_assert(assembler_start(g,r,13)&&g.scrap==14.5,"advanced recipe charges its own authored cost");
    var big=r.target_module;
    assembler_assert(big.object_index==obj_module_big_boy&&big.scrap_cost==8,"advanced physical output retains price");
    // A temporarily too-small inventory must retain output on the robot.
    g.inventory_cols=1;g.inventory_rows=1;robots_tick(g,30);
    assembler_assert(!r.working&&array_length(r.outputs)==1&&r.outputs[0]==big&&!big.in_inventory,"oversized output safely waits for space");
    assembler_assert(!assembler_start(g,r,0)&&g.scrap==14.5,"pending output blocks another charge");
    campaign_device_layout(g,d);robots_tick(g,0);
    assembler_assert(big.in_inventory&&array_length(r.outputs)==0,"waiting output automatically stored when space returns");
    r.recipe_scroll=12;assembler_test_capture(g,"assembler-catalog-preview");
    campaign_table(g);
    assembler_assert(shop_buy(g,"assembler_robot")&&shop_count(g,"assembler_robot")==2,"repeatable assembler purchases");
    var second=g.robots[array_length(g.robots)-1];
    assembler_assert(second.board_device!=d&&second.remaining==0&&second.recipe_scroll==0,"independent robot screens and progress");
    assembler_assert(robot_assign_power(g,second),"independent allocation for second assembler");campaign_open(g,second.board_device);
    assembler_assert(assembler_start(g,second,0),"second robot starts independently");
    var doomed=second.target_module,screen=second.board_device;instance_destroy(second);
    assembler_assert(!instance_exists(doomed)&&!instance_exists(screen)&&instance_exists(big),"cleanup owns unfinished output and screen, preserves inventory");
    campaign_table(g);g.money=200;shop_buy(g,"solder_robot");shop_buy(g,"dismantle_robot");
    assembler_assert(robot_card_rect(0,3)[1]>=campaign_item_rect(5)[3],"all four robot rows fit below donor grid");
    assembler_test_capture(g,"assembler-table-preview");
    show_debug_message("ASSEMBLER_RESULT passes="+string(global.assembler_passes)+" failures=0");game_end();
}
