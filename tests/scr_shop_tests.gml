// Run only in an isolated project copy, after obj_game initialization.
function shop_tests() {
    var g=instance_find(obj_game,0),passed=0;
    g.debug_tools=false;g.money=100;g.purchases={};shop_apply(g);
    if(shop_buy(g,"missing") || g.money!=100) throw "Unknown product charged money";
    passed++;
    if(!shop_buy(g,"solder_robot") || g.money!=0 || shop_count(g,"solder_robot")!=1) throw "Purchase failed";
    passed++;
    if(shop_buy(g,"solder_robot") || shop_buy(g,"dismantle_robot") || g.money!=0) throw "Unaffordable purchase";
    passed++;
    var robot=g.robots[array_length(g.robots)-1];shop_apply(g);robot_assign_power(g,robot);campaign_earn(g);robot_start(g,robot);robots_tick(g,10);
    if(g.money!=20) throw "Plate income did not pay twenty once";
    passed++;
    global.mode=GameMode.Menu;campaign_earn(g);robot_start(g,robot);
    global.mode=GameMode.Pause;robots_tick(g,20);
    if(g.money!=20) throw "Income advanced in pause";
    global.mode=GameMode.Play;robots_tick(g,10);
    if(g.money!=40 || shop_buy(g,"dismantle_robot")) throw "Play income or purchase guard failed";
    passed++;
    global.mode=GameMode.Menu;g.money=200;
    if(!shop_buy(g,"solder_robot") || !shop_buy(g,"dismantle_robot") || g.money!=0 || shop_count(g,"solder_robot")!=2) throw "Repeat purchase failed";
    passed++;
    var s=g.shop;s.open=false;
    var r=shop_button_rect();
    if(!shop_click(s,r[0]+2,r[1]+2) || !s.open) throw "Shop did not open";
    r=shop_panel_rect();
    if(!shop_click(s,r[0]+2,r[1]+2)) throw "Panel did not consume click";
    if(!shop_click(s,10,100) || s.open) throw "Outside click did not dismiss";
    passed++;
    s.open=true;g.money=40;s.page_size=3;
    var surf=surface_create(1280,720);surface_set_target(surf);draw_clear(c_black);
    campaign_gui_draw(g);shop_draw(s);surface_reset_target();surface_save(surf,"shop-preview.png");surface_free(surf);
    show_debug_message("SHOP_TEST_RESULT passes="+string(passed)+" failures=0");
    game_end();
}
