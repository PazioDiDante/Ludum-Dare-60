function manual_upgrade_assert(_ok,_message) {
    if(!_ok) throw "MANUAL_UPGRADE_FAILURE: "+_message;
    global.manual_upgrade_passes++;
}
function manual_upgrade_tests() {
    global.manual_upgrade_passes=0;
    var g=instance_find(obj_game,0);g.money=49;
    manual_upgrade_assert(!shop_buy(g,"fast_manual_income")&&g.money==49&&!shop_owned(g,"fast_manual_income"),"fifty coins required");
    g.money=300;campaign_earn(g);campaign_solder_plate(g);
    manual_upgrade_assert(g.earn_remaining==5&&campaign_earn_seconds(g)==5,"base earnings remain five seconds");
    manual_upgrade_assert(shop_buy(g,"fast_manual_income")&&g.money==250&&shop_owned(g,"fast_manual_income")&&array_length(g.robots)==1,"income upgrade costs fifty without creating robot");
    manual_upgrade_assert(!shop_buy(g,"fast_manual_income")&&g.money==250&&shop_count(g,"fast_manual_income")==1,"income upgrade cannot charge twice");
    manual_upgrade_assert(g.earn_duration==5&&g.earn_remaining==5,"already running action keeps its duration");
    campaign_tick(g,5);var cash=g.money;
    campaign_earn(g);campaign_solder_plate(g);
    manual_upgrade_assert(g.earn_duration==2.5&&g.earn_remaining==2.5,"new manual action uses half duration");
    campaign_tick(g,2);
    manual_upgrade_assert(g.money==cash&&g.earn_remaining==0.5,"no payout before upgraded duration");
    campaign_tick(g,0.5);campaign_tick(g,10);
    manual_upgrade_assert(g.money==cash+20,"upgraded action pays twenty exactly once");
    campaign_earn(g);campaign_solder_plate(g);global.mode=GameMode.Pause;campaign_tick(g,10);
    manual_upgrade_assert(g.earn_remaining==2.5,"pause freezes upgraded earning");global.mode=GameMode.Menu;campaign_tick(g,2.5);
    cash=g.money;
    manual_upgrade_assert(shop_buy(g,"fast_unscrew")&&g.money==cash-50&&array_length(g.robots)==1,"screw upgrade costs fifty without creating robot");
    manual_upgrade_assert(!shop_buy(g,"fast_unscrew")&&shop_count(g,"fast_unscrew")==1&&g.money==cash-50,"screw upgrade is unique");
    shop_apply(g);shop_apply(g);
    manual_upgrade_assert(campaign_earn_seconds(g)==2.5&&g.generator.repair_seconds==5,"reapply cannot compound or speed generator repair");
    manual_upgrade_assert(shop_buy(g,"solder_robot")&&shop_buy(g,"solder_robot")&&shop_count(g,"solder_robot")==2,"robot purchases remain repeatable");
    var robot=g.robots[1];robot_assign_power(g,robot);campaign_earn(g);robot_start(g,robot);
    manual_upgrade_assert(robot.remaining==10&&robot.work_seconds==10,"manual upgrades never accelerate robots");
    g.device_types=[obj_remote];campaign_buy(g);var d=g.table_devices[0];campaign_open(g,d);
    var screws=[];
    for(var i=0;i<array_length(d.children);++i) {var item=d.children[i];if(instance_exists(item)&&item.object_index==obj_screw) array_push(screws,item);}
    var first=screws[0],second=screws[1],count=d.remaining;
    manual_upgrade_assert(pointer_dispatch(first,mb_left)&&first.unscrew_seconds==1&&first.unscrew_remaining==1,"upgrade affects screws generated before use");
    manual_upgrade_assert(!pointer_dispatch(second,mb_left)&&d.remaining==count,"still one screw at a time");
    screw_tick(g,0.5);global.mode=GameMode.Pause;screw_tick(g,10);
    manual_upgrade_assert(instance_exists(first)&&first.unscrew_remaining==0.5,"pause freezes upgraded screw timer");global.mode=GameMode.Play;
    screw_tick(g,0.5);
    manual_upgrade_assert(!instance_exists(first)&&d.remaining==count-1,"upgraded screw removed after one second");
    pointer_dispatch(second,mb_left);screw_tick(g,0.5);campaign_table(g);campaign_open(g,d);pointer_dispatch(second,mb_left);
    manual_upgrade_assert(second.unscrew_seconds==1&&second.unscrew_remaining==1,"restarting never compounds screw speed");
    screw_cancel(g);struct_set(g.purchases,"fast_unscrew",false);pointer_dispatch(second,mb_left);
    manual_upgrade_assert(second.unscrew_seconds==2,"base screw duration still supported without upgrade");
    screw_cancel(g);struct_set(g.purchases,"fast_unscrew",true);campaign_table(g);
    g.shop.open=true;g.shop.scroll=1;g.shop.page_size=3;
    var surface=surface_create(1280,720);surface_set_target(surface);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);campaign_table_draw(g);campaign_gui_draw(g);generator_draw(g);robots_draw(g);shop_draw(g.shop);
    surface_reset_target();surface_save(surface,"manual-upgrades-shop-preview.png");surface_free(surface);
    show_debug_message("MANUAL_UPGRADE_RESULT passes="+string(global.manual_upgrade_passes)+" failures=0");game_end();
}
