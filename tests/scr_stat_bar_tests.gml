function stat_test_assert(_ok,_message) {
    if(!_ok) throw "STAT_TEST_FAILURE: "+_message;
    global.stat_test_passes++;
}
function stat_bar_tests() {
    global.stat_test_passes=0;
    var values=[0,10,12,13,20,100];
    for(var i=0;i<array_length(values);++i) {
        var model=stat_bar_model(values[i],6,10);
        stat_test_assert(model.count==20&&model.unit==1&&model.low==0&&model.high==20,"fixed twenty cells at value "+string(values[i]));
    }
    stat_test_assert(stat_bar_model(6,6,10).valid&&stat_bar_model(10,6,10).valid&&!stat_bar_model(13,6,10).valid,"inclusive actual requirement validation");
    stat_test_assert(stat_bar_model(100,6,undefined).valid&&!stat_bar_model(-1,0,undefined).valid,"out-of-display values retain actual validation");
    stat_test_assert(stat_bar_model(-2.5,-3,-2).valid&&stat_bar_model(0,0,0).valid,"fractional and exact conditions");
    var s=surface_create(500,500);surface_set_target(s);draw_clear(c_black);
    draw_set_font(instance_find(obj_game,0).ui_font);
    stat_bar_draw(16,16,spr_stat_energy,13,6,10);
    stat_bar_draw(16,96,spr_stat_energy,0,6,10);
    stat_bar_draw(16,176,spr_stat_energy,20,undefined,10);
    stat_bar_draw(16,256,spr_stat_energy,6,6,10);
    stat_bar_draw(16,336,spr_stat_energy,-2.5,-3,-2);
    stat_bar_draw(16,416,spr_stat_energy,100,6,10);
    var refs=[spr_stat_blue_full,spr_stat_green_full,spr_stat_blue_empty,spr_stat_green_empty];
    for(var i=0;i<4;++i) draw_sprite_part_ext(refs[i],0,0,0,10,16,440,16+i*40,1.6,2,c_white,1);
    surface_reset_target();
    stat_test_assert(surface_getpixel(s,96+12*16+8,32)==surface_getpixel(s,448,32),"thirteenth unit remains full blue with no compression");
    stat_test_assert(surface_getpixel(s,96+7*16+8,32)==surface_getpixel(s,448,72),"filled acceptable interval is green");
    stat_test_assert(surface_getpixel(s,96+15*16+8,32)==surface_getpixel(s,448,112),"unfilled cells beyond value remain blue through twenty");
    stat_test_assert(surface_getpixel(s,96+7*16+8,112)==surface_getpixel(s,448,152),"empty acceptable interval stays green");
    for(var row=0;row<6;++row) {
        var expected=(row==3||row==4)?make_color_rgb(0,166,81):make_color_rgb(0,174,240);
        var pixels=0;
        for(var py=16+row*80;py<48+row*80;++py) for(var px=56;px<88;++px)
            if(surface_getpixel(s,px,py)==expected) pixels++;
        stat_test_assert(pixels>0,"numeric value uses exact range colour for row "+string(row));
    }
    surface_save(s,"fixed-stat-bars-preview.png");surface_free(s);
    // Each lamp is labelled by its 1-based value, including both range limits.
    var boundary_values=[5,0,5,0,10,11,5,0];
    var boundary_max=[10,10,undefined,undefined,10,10,5,5];
    s=surface_create(500,340);surface_set_target(s);draw_clear(c_black);
    for(var row=0;row<8;++row)
        stat_bar_draw(16,8+row*38,spr_stat_energy,boundary_values[row],5,boundary_max[row]);
    for(var i=0;i<4;++i) draw_sprite_part_ext(refs[i],0,0,0,10,16,440,8+i*40,1.6,2,c_white,1);
    surface_reset_target();
    for(var row=0;row<8;++row) for(var cell=0;cell<20;++cell) {
        var green=cell+1>=5&&(is_undefined(boundary_max[row])||cell+1<=boundary_max[row]);
        var full=cell+1<=boundary_values[row];
        var reference_row=green?(full?1:3):(full?0:2);
        stat_test_assert(surface_getpixel(s,96+cell*16+8,24+row*38)==surface_getpixel(s,448,24+reference_row*40),
            "inclusive lamp "+string(cell+1)+" on boundary row "+string(row));
    }
    surface_save(s,"inclusive-stat-boundaries-preview.png");surface_free(s);
    var g=instance_find(obj_game,0);campaign_open(g,g.order_device);
    var d=g.order_device;d.stats_min={energy:6,heat:0,stability:1};d.stats_max={energy:10,heat:4,weight:12};
    d.current_stats={energy:13,heat:2,stability:3,weight:7};campaign_device_layout(g,d);
    s=surface_create(1280,720);surface_set_target(s);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);campaign_gui_draw(g);
    surface_reset_target();surface_save(s,"fixed-stat-panel-preview.png");surface_free(s);
    stat_test_assert(16+80+20*16<=g.sidebar_width-8,"number and all twenty cells fit inside sidebar backing");
    // Real orders, unmodified requirements: inspect the full 20th cell on every row.
    var orders=[obj_order,obj_order_2,obj_order_3],keys=["energy","weight","heat","stability"];
    for(var order_index=0;order_index<array_length(orders);++order_index) {
        var order=campaign_create_device(orders[order_index]);campaign_open(g,order);
        var rows=0;
        s=surface_create(1280,720);surface_set_target(s);draw_clear(c_black);
        campaign_gui_draw(g);
        // Reference empty cell, with the same exact drawing dimensions.
        draw_sprite_part_ext(spr_stat_blue_empty,0,0,0,10,16,500,200,1.6,2,c_white,1);
        draw_sprite_part_ext(spr_stat_green_empty,0,0,0,10,16,540,200,1.6,2,c_white,1);
        surface_reset_target();
        for(var k=0;k<4;++k) {
            var key=keys[k];
            if(!struct_exists(order.stats_min,key)&&!struct_exists(order.stats_max,key)) continue;
            var lower=struct_exists(order.stats_min,key)?struct_get(order.stats_min,key):undefined;
            var upper=struct_exists(order.stats_max,key)?struct_get(order.stats_max,key):undefined;
            var green=(is_undefined(lower)||20>=lower)&&(is_undefined(upper)||20<=upper);
            var reference_x=green?540:500,matched=true,samples=0;
            for(var py=0;py<32;++py) for(var px=0;px<16;++px) {
                var color=surface_getpixel(s,reference_x+px,200+py);
                if(color==c_black) continue;
                samples++;
                if(surface_getpixel(s,96+19*16+px,16+rows*38+py)!=color) matched=false;
            }
            stat_test_assert(matched&&samples>0,"real order "+string(order_index+1)+" renders twentieth "+key+" cell beyond requirement maximum");
            rows++;
        }
        surface_save(s,"actual-order-"+string(order_index+1)+"-stats.png");surface_free(s);
        campaign_table(g);instance_destroy(order);
    }
    show_debug_message("STAT_TEST_RESULT passes="+string(global.stat_test_passes)+" failures=0");game_end();
}
