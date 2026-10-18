// Run only in an isolated project after obj_game initialization.
function currency_assert(_ok,_label) {
    if(!_ok) throw "CURRENCY_UI_FAILURE: "+_label;
    global.currency_passes++;
}
function currency_capture(_g,_name) {
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    with(_g) event_perform(ev_draw,0);
    campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    if(_g.shop.open) shop_draw(_g.shop);
    surface_reset_target();surface_save(sf,environment_get_variable("CURRENCY_TEST_OUTPUT")+"/"+_name+".png");surface_free(sf);
}
function currency_ui_tests() {
    global.currency_passes=0;
    var g=instance_find(obj_game,0);draw_set_font(g.ui_font);
    var size=max(16,string_height("M")),runs=ui_text_runs("A {coin} 12 {scrap} 3.5");
    var coins=0,cogs=0,plain="";
    for(var i=0;i<array_length(runs);++i) {
        if(runs[i].sprite==spr_coin) coins++;
        else if(runs[i].sprite==spr_cog) cogs++;
        else plain+=runs[i].text;
    }
    currency_assert(coins==1&&cogs==1&&plain=="A  12  3.5","currency markers emit exact sprite assets and retain numbers");
    currency_assert(ui_text_width("A {coin} 12")==string_width("A  12")+size,"inline icon participates in text measurement");
    currency_assert(ui_text_width("{coin}\n{scrap} 5")==size+string_width(" 5"),"multiline width uses widest line");
    currency_assert(ui_text_width("Normal text")==string_width("Normal text"),"ordinary text keeps native measurement");
    var sf=surface_create(640,180);surface_set_target(sf);draw_clear(c_black);
    draw_set_color(c_white);draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_alpha(1);
    ui_text(16,16,"{coin} 125");
    campaign_sprite(spr_coin,[300,16,300+size,16+size]);draw_text(300+size,16," 125");
    ui_text(16,64,"{scrap} 3.50");
    campaign_sprite(spr_cog,[300,64,300+size,64+size]);draw_text(300+size,64," 3.50");
    surface_reset_target();
    var matching_coin=true,matching_scrap=true;
    for(var py=0;py<size;++py) for(var px=0;px<160;++px) {
        if(surface_getpixel(sf,16+px,16+py)!=surface_getpixel(sf,300+px,16+py)) matching_coin=false;
        if(surface_getpixel(sf,16+px,64+py)!=surface_getpixel(sf,300+px,64+py)) matching_scrap=false;
    }
    currency_assert(matching_coin,"coin text pixels match direct spr_coin plus numeric text");
    currency_assert(matching_scrap,"scrap text pixels match direct spr_cog plus fractional text");
    surface_set_target(sf);draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_color(c_yellow);draw_set_alpha(0.5);
    var expected_alpha=draw_get_alpha();
    ui_text_ext(320,130,"A {coin} B {scrap} C",24,100);
    surface_reset_target();surface_free(sf);
    currency_assert(draw_get_halign()==fa_center&&draw_get_valign()==fa_middle&&draw_get_color()==c_yellow&&draw_get_alpha()==expected_alpha,"rich text preserves alignment, colour and alpha");
    draw_set_alpha(1);draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(c_white);
    g.money=250;g.scrap=12.5;campaign_table(g);currency_capture(g,"currency-table");
    g.shop.open=true;g.shop.scroll=2;currency_capture(g,"currency-shop");g.shop.open=false;
    campaign_open(g,g.recycler_robot.board_device);currency_capture(g,"currency-recycler");campaign_table(g);
    campaign_open(g,g.order_device);currency_capture(g,"currency-order");campaign_table(g);
    var lab=instance_create_depth(0,0,0,obj_balance_lab);lab.tab=2;lab_rebuild(lab);
    sf=surface_create(1280,720);surface_set_target(sf);lab_ui_draw(lab);surface_reset_target();
    surface_save(sf,environment_get_variable("CURRENCY_TEST_OUTPUT")+"/currency-balance-lab.png");surface_free(sf);instance_destroy(lab);
    var manual=instance_create_depth(0,0,0,obj_manual_lab);manual.tab=1;manual_rebuild(manual);
    sf=surface_create(1280,720);surface_set_target(sf);manual_draw(manual);surface_reset_target();
    surface_save(sf,environment_get_variable("CURRENCY_TEST_OUTPUT")+"/currency-manual-lab.png");surface_free(sf);instance_destroy(manual);
    show_debug_message("CURRENCY_UI_RESULT passes="+string(global.currency_passes)+" failures=0");game_end();
}
