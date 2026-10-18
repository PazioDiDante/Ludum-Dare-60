// Run after obj_game initialization in an isolated Room1 project.
function plate_assert(_ok,_label) {
    if(!_ok) throw "PLATE_FAILURE: "+_label;
    global.plate_passes++;
}
function plate_capture(_g,_name) {
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    campaign_table_draw(_g);campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    surface_reset_target();surface_save(sf,environment_get_variable("PLATE_TEST_OUTPUT")+"/"+_name+".png");surface_free(sf);
}
function plate_tests() {
    global.plate_passes=0;
    var g=instance_find(obj_game,0),start=g.money;
    plate_assert(!g.table_plate&&g.earn_remaining==0,"no starting plate or timer");
    plate_assert(!campaign_solder_plate(g),"manual income requires a plate");
    campaign_tick(g,100);plate_assert(g.money==start,"no plate means no passive income");
    g.debug_tools=true;
    plate_assert(campaign_gui_click(g,270,30)&&g.table_plate&&g.money==start&&g.earn_remaining==0,"former income button creates one plate without starting or paying");
    plate_assert(!campaign_earn(g)&&g.table_plate,"second request cannot stack plates");
    campaign_tick(g,100);plate_assert(g.money==start&&g.earn_remaining==0,"idle table plate never pays by itself");
    plate_capture(g,"plate-ready");
    var rect=campaign_plate_rect();
    var order_rect=campaign_order_rect(),last_top_donor=campaign_item_rect(2);
    plate_assert(rect[1]>order_rect[3]&&rect[0]>last_top_donor[2],"raised plate remains below order and clear of donor slots");
    plate_assert(campaign_table_click(g,rect[0]+40,rect[1]+40)&&g.table_plate&&g.earn_remaining==5,"click on table plate starts old five-second action even in debug");
    plate_assert(!campaign_solder_plate(g)&&!campaign_earn(g)&&g.earn_remaining==5,"manual reservation prevents restart and replacement");
    g.money=300;shop_buy(g,"solder_robot");shop_buy(g,"solder_robot");
    var a=g.robots[1],b=g.robots[2];
    plate_assert(robot_assign_power(g,a)&&robot_assign_power(g,b),"two one-energy solder robots powered");
    plate_assert(!robot_start(g,a)&&!robot_start(g,b)&&!a.has_plate&&!b.has_plate,"robots cannot take manually reserved plate");
    var cash=g.money;campaign_tick(g,2);
    plate_assert(g.earn_remaining==3&&g.money==cash,"manual job has no early payout");
    plate_capture(g,"plate-manual-progress");
    global.mode=GameMode.Pause;campaign_tick(g,100);
    plate_assert(g.earn_remaining==3&&g.table_plate,"pause preserves manual plate and timer");global.mode=GameMode.Menu;
    campaign_open(g,g.order_device);campaign_tick(g,2);
    plate_assert(g.earn_remaining==1&&g.table_plate,"manual work continues while another screen is open");
    plate_assert(!campaign_earn(g)&&!campaign_solder_plate(g),"plate actions are table-only");
    campaign_table(g);campaign_tick(g,1);
    plate_assert(g.money==cash+20&&!g.table_plate&&g.earn_remaining==0,"manual completion consumes plate and pays twenty");
    campaign_tick(g,100);plate_assert(g.money==cash+20,"manual payout occurs only once");
    plate_assert(!robot_start(g,a)&&!robot_start(g,b)&&a.remaining==0&&b.remaining==0,"powered robots cannot start without a table plate");
    plate_assert(campaign_earn(g),"table plate can be requested after consumption");
    g.robot_stack_front[2]=0; // The shared solder card controls the front instance.
    var job=robot_job_rect(0,1);
    plate_assert(robots_click(g,job[0]+8,job[1]+8)&&a.working&&a.has_plate&&!g.table_plate&&a.remaining==10,"robot start button reserves one plate for ten seconds");
    plate_assert(!campaign_solder_plate(g)&&!robot_start(g,b)&&!b.working,"robot-held plate cannot be reused manually or by another robot");
    cash=g.money;robots_tick(g,3);
    plate_assert(a.remaining==7&&a.has_plate&&g.money==cash,"robot has no early payout");
    plate_assert(campaign_earn(g)&&g.table_plate&&!campaign_earn(g),"one next plate is allowed while robot owns previous plate");
    plate_capture(g,"plate-robot-progress");
    plate_assert(!robot_start(g,a)&&g.table_plate&&a.remaining==7,"busy robot cannot take next plate or reset itself");
    robot_release_power(g,b);
    plate_assert(!robot_start(g,b)&&g.table_plate&&!b.has_plate,"unpowered robot leaves table plate untouched");
    robot_assign_power(g,b);
    plate_assert(robot_start(g,b)&&b.has_plate&&!g.table_plate,"second robot reserves its own plate");
    generator_stop(g,"test outage");robots_tick(g,100);
    plate_assert(a.remaining==7&&b.remaining==10&&a.has_plate&&b.has_plate,"power outage keeps both reserved plates and timers");
    generator_restart(g);global.mode=GameMode.Pause;robots_tick(g,100);
    plate_assert(a.remaining==7&&b.remaining==10&&g.money==cash,"pause stops both robot jobs");global.mode=GameMode.Menu;
    robot_release_power(g,a);robots_tick(g,3);
    plate_assert(a.remaining==7&&b.remaining==7&&a.has_plate,"released robot pauses independently");
    robot_assign_power(g,a);robots_tick(g,6);
    plate_assert(a.remaining==1&&b.remaining==1&&g.money==cash,"both require their full powered duration");
    robots_tick(g,1);
    plate_assert(g.money==cash+40&&!a.working&&!b.working&&!a.has_plate&&!b.has_plate&&!g.table_plate,"two consumed plates produce exactly two twenty-coin payouts");
    robot_finish(g,a);robot_finish(g,b);robots_tick(g,100);
    plate_assert(g.money==cash+40&&!a.working&&!b.working,"idle and repeated completion never create free money");
    a.working=true;a.has_plate=false;robot_finish(g,a);
    plate_assert(g.money==cash+40&&!a.working,"finish without an owned plate cannot pay");
    campaign_earn(g);g.debug_tools=false;
    plate_assert(campaign_solder_plate(g)&&g.earn_duration==5,"normal mode retains five-second manual work");campaign_tick(g,5);
    shop_buy(g,"fast_manual_income");campaign_earn(g);campaign_solder_plate(g);
    plate_assert(g.earn_duration==2.5&&g.earn_remaining==2.5,"existing manual income upgrade applies to plate work");campaign_tick(g,2.5);
    campaign_earn(g);robot_start(g,a);
    plate_assert(a.work_seconds==10&&a.remaining==10,"manual upgrade does not accelerate robot plates");robots_tick(g,10);
    campaign_earn(g);g.money=1000;
    while(array_length(g.table_devices)<6) campaign_buy(g);
    var donors=array_length(g.table_devices);robot_start(g,a);
    plate_assert(a.has_plate&&!g.table_plate&&array_length(g.table_devices)==donors,"plate is independent of six donor slots and robot never consumes donor");
    plate_assert(campaign_earn(g)&&g.table_plate&&array_length(g.table_devices)==6,"full donor table still allows its one separate plate");
    for(var i=0;i<array_length(g.table_devices);++i) g.table_devices[i].arrival_progress=1;
    plate_capture(g,"plate-full-table");
    show_debug_message("PLATE_RESULT passes="+string(global.plate_passes)+" failures=0");game_end();
}
