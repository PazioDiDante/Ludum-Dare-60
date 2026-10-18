function assembler_visual_assert(_ok,_label) {
    if(!_ok) throw "ASSEMBLER_VISUAL_FAILURE: "+_label;
    global.assembler_visual_passes++;
}
function assembler_visual_capture(_g,_name) {
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    campaign_table_draw(_g);campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    surface_reset_target();surface_save(sf,environment_get_variable("ASSEMBLER_TEST_OUTPUT")+"/"+_name+".png");surface_free(sf);
}
function assembler_visual_tests() {
    global.assembler_visual_passes=0;
    var g=instance_find(obj_game,0);g.money=1000;g.scrap=100;
    assembler_visual_assert(shop_buy(g,"assembler_robot"),"real purchase succeeds");
    var r=g.robots[array_length(g.robots)-1];
    var machines=robots_table_machines(g);
    assembler_visual_assert(machines[1]==r,"purchase appears beside the starting recycler");
    assembler_visual_assert(robot_table_sprite(r)==spr_assembler_idle&&r.work_frame==0,"purchased robot idles");
    var hit=robot_table_hit_rect(r);
    var donor=campaign_item_rect(5),plate=campaign_plate_rect();
    assembler_visual_assert(hit[1]>=donor[3]&&hit[2]<=plate[0]&&hit[3]<664,"machine clears donors, plate and generator bar");
    campaign_earn(g);
    assembler_visual_capture(g,"assembler-idle");
    assembler_visual_assert(campaign_table_click(g,(hit[0]+hit[2])/2,(hit[1]+hit[3])/2)&&g.active_device==r.board_device,"machine click opens its catalog");
    campaign_table(g);
    g.generator.stats_base.energy=12;device_stats_update(g.generator);power_update(g);
    assembler_visual_assert(robot_assign_power(g,r),"three energy assigned through existing controls");
    campaign_open(g,r.board_device);
    assembler_visual_assert(assembler_start(g,r,0)&&robot_table_sprite(r)==spr_assembler_work&&r.work_frame==0,"craft starts work animation from frame zero");
    robots_tick(g,0.25);
    var frame_rate=sprite_get_speed(spr_assembler_work);
    if(sprite_get_speed_type(spr_assembler_work)==spritespeed_framespergameframe) frame_rate*=game_get_speed(gamespeed_fps);
    assembler_visual_assert(abs(r.work_frame-0.25*frame_rate)<0.001,"authored playback speed uses elapsed seconds");
    campaign_table(g);assembler_visual_capture(g,"assembler-working-frame1");
    robots_tick(g,0.25);
    assembler_visual_assert(floor(r.work_frame)==3,"work advances across distinct frames");
    assembler_visual_capture(g,"assembler-working-frame3");
    global.mode=GameMode.Pause;var before=r.work_frame,time_left=r.remaining;robots_tick(g,5);
    assembler_visual_assert(r.work_frame==before&&r.remaining==time_left,"pause freezes animation and job");
    global.mode=GameMode.Menu;generator_stop(g,"visual test");robots_tick(g,1);
    assembler_visual_assert(robot_table_sprite(r)==spr_assembler_idle&&r.work_frame==0&&r.remaining==time_left,"outage idles without losing progress");
    assembler_visual_assert(generator_restart(g),"restart restores power");robots_tick(g,0.25);
    assembler_visual_assert(robot_table_sprite(r)==spr_assembler_work&&abs(r.work_frame-0.25*frame_rate)<0.001,"power restoration resumes animation");
    robots_tick(g,sprite_get_number(spr_assembler_work)/frame_rate);
    assembler_visual_assert(abs(r.work_frame-0.25*frame_rate)<0.001,"work animation loops");
    assembler_visual_assert(shop_buy(g,"assembler_robot"),"second purchase succeeds");
    var second=g.robots[array_length(g.robots)-1];
    assembler_visual_assert(second.work_frame==0&&robot_table_sprite(second)==spr_assembler_idle,"second robot stays independently idle");
    hit=robot_table_hit_rect(second);
    assembler_visual_assert(campaign_table_click(g,hit[0]+10,hit[1]+20)&&g.active_device==second.board_device,"second table machine opens its own catalog");
    campaign_table(g);robot_assign_power(g,second);campaign_open(g,second.board_device);assembler_start(g,second,0);
    before=r.work_frame;robots_tick(g,0.125);
    assembler_visual_assert(abs(second.work_frame-0.125*frame_rate)<0.001&&abs(r.work_frame-second.work_frame-before)<0.001,"simultaneous robots keep independent clocks");
    campaign_table(g);assembler_visual_capture(g,"assembler-two-machines");
    robots_tick(g,r.remaining);
    assembler_visual_assert(!r.working&&r.work_frame==0&&robot_table_sprite(r)==spr_assembler_idle,"finished robot returns immediately to idle");
    assembler_visual_assert(second.working&&robot_table_sprite(second)==spr_assembler_work,"other robot continues working");
    assembler_visual_assert(shop_buy(g,"assembler_robot")&&g.robot_stack_front[1]==2,"third purchase comes to front of assembler cascade");
    var third=g.robots[array_length(g.robots)-1];hit=robot_table_hit_rect(third);
    assembler_visual_assert(campaign_table_click(g,hit[0]+10,hit[1]+20)&&g.active_device==third.board_device,"newly visible third robot is clickable");
    campaign_table(g);assembler_visual_assert(shop_buy(g,"assembler_robot")&&g.robot_stack_front[1]==3,"fourth purchase is brought to front");
    var arrow=robot_stack_arrow(1,true);
    assembler_visual_assert(robots_table_click(g,arrow[0]+2,arrow[1]+2)&&g.robot_stack_front[1]==0,"stack selection reaches earlier purchases");
    assembler_visual_capture(g,"assembler-paged-machines");
    show_debug_message("ASSEMBLER_VISUAL_RESULT passes="+string(global.assembler_visual_passes)+" failures=0");game_end();
}
