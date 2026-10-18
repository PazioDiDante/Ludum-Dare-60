function table_test_assert(_ok,_message) {
    if(!_ok) throw "TABLE_TEST_FAILURE: "+_message;
    global.table_test_passes++;
}
function table_tests() {
    global.table_test_passes=0;
    var g=instance_find(obj_game,0);g.money=700;
    table_test_assert(array_length(g.table_devices)==1,"one starter occupies the first slot");
    repeat(5) table_test_assert(campaign_buy(g),"purchase within six slots");
    var count=instance_number(par_device);
    table_test_assert(array_length(g.table_devices)==6&&g.money==575,"starter and five purchases take six slots and 125 coins");
    table_test_assert(!campaign_buy(g)&&g.money==575&&instance_number(par_device)==count,"seventh purchase cannot charge or create device");
    table_test_assert(!campaign_gui_click(g,120,490)&&!campaign_gui_click(g,550,490),"removed page arrows do not consume clicks");
    var last=g.table_devices[5],r=campaign_item_rect(5);
    table_test_assert(campaign_table_click(g,r[0]+20,r[1]+20)&&g.active_device==last,"sixth device remains accessible");
    campaign_table(g);shop_buy(g,"dismantle_robot");
    var robot=g.robots[array_length(g.robots)-1];robot_assign_power(g,robot);
    table_test_assert(robot_start(g,robot)&&array_length(g.table_devices)==5,"robot removes donor and frees slot");
    table_test_assert(campaign_buy(g)&&array_length(g.table_devices)==6&&!campaign_buy(g),"freed slot can be refilled only once");
    show_debug_message("TABLE_TEST_RESULT passes="+string(global.table_test_passes)+" failures=0");game_end();
}
