function table_layout_assert(_ok,_label) {
    if(!_ok) throw "TABLE_LAYOUT_FAILURE: "+_label;
    global.table_layout_passes++;
}
function table_layout_capture(_g,_name) {
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    draw_set_font(_g.ui_font);draw_set_halign(fa_left);draw_set_valign(fa_top);
    campaign_table_draw(_g);campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    surface_reset_target();surface_save(sf,environment_get_variable("ASSEMBLER_TEST_OUTPUT")+"/"+_name+".png");surface_free(sf);
}
function table_layout_tests() {
    global.table_layout_passes=0;
    var g=instance_find(obj_game,0);g.money=10000;g.scrap=100;
    var order=campaign_order_rect(),donor=campaign_item_rect(0),plate=campaign_plate_rect();
    table_layout_assert(order[1]==donor[1]&&order[3]==donor[3],"main order aligns with upper donor row");
    table_layout_assert(plate[1]==order[3]+16&&plate[1]<452,"plate moves up directly beneath raised order");
    table_layout_assert(campaign_table_click(g,order[0]+60,order[1]+60)&&g.active_device==g.order_device,"raised order uses new click bounds");campaign_table(g);
    campaign_earn(g);
    table_layout_assert(campaign_table_click(g,plate[0]+80,plate[1]+80)&&g.earn_remaining==5,"raised plate starts manual income at new position");
    campaign_tick(g,5);
    table_layout_assert(!g.table_plate&&g.earn_remaining==0,"raised plate completes normally");campaign_earn(g);
    while(array_length(g.table_devices)<6) campaign_buy(g);
    for(var i=0;i<array_length(g.table_devices);++i) g.table_devices[i].arrival_progress=1;
    shop_buy(g,"assembler_robot");shop_buy(g,"solder_robot");shop_buy(g,"dismantle_robot");
    var stacks=robots_table_stacks(g);
    for(var group=0;group<4;++group) {
        table_layout_assert(array_length(stacks[group])==1,"all four robot types have a permanent column "+string(group));
        var hit=robot_table_hit_rect(stacks[group][0]);
        table_layout_assert(hit[1]>=472&&hit[3]<=656,"robot column clears donors and bottom edge "+string(group));
    }
    var last_hit=robot_table_hit_rect(stacks[3][0]);
    table_layout_assert(last_hit[2]>1180&&last_hit[2]<display_get_gui_width()-16,"robot area reaches far right of table");
    table_layout_capture(g,"table-four-types");
    repeat(4) shop_buy(g,"assembler_robot");repeat(2) shop_buy(g,"solder_robot");repeat(2) shop_buy(g,"dismantle_robot");
    stacks=robots_table_stacks(g);
    table_layout_assert(array_length(stacks[1])==5&&array_length(stacks[2])==3&&array_length(stacks[3])==3,"repeat purchases stay in their type's stack");
    table_layout_assert(g.robot_stack_front[1]==4&&g.robot_stack_front[2]==2&&g.robot_stack_front[3]==2,"new purchases come to front of their own stack");
    for(var group=1;group<4;++group) {
        var r=stacks[group][g.robot_stack_front[group]],front=robot_table_hit_rect(r),back=robot_table_hit_rect(r,2);
        table_layout_assert(back[0]==front[0]+32&&back[1]<front[1],"duplicates cascade diagonally "+string(group));
        table_layout_assert(back[1]>=472&&back[3]<=656&&back[2]<display_get_gui_width()-16,"cascade fits the table "+string(group));
    }
    table_layout_capture(g,"table-cascades-idle");
    var selected=stacks[1][4],front=robot_table_hit_rect(selected);
    table_layout_assert(campaign_table_click(g,(front[0]+front[2])/2,(front[1]+front[3])/2)&&g.active_device==selected.board_device,"overlap click selects visible front assembler");campaign_table(g);
    var card=robot_card_rect(0,1),job=robot_job_rect(0,1);
    table_layout_assert(robots_click(g,job[0]+4,job[1]+4)&&g.active_device==selected.board_device,"single control card targets front robot");campaign_table(g);
    var energy_row=robot_row_layout(robot_groups(g)[1],1);
    table_layout_assert(!robots_click(g,energy_row.card[2]+8,card[1]+10),"energy row clicks stop at the expanded card edge");
    var behind=stacks[1][0],behind_rect=robot_table_hit_rect(behind,1);
    table_layout_assert(campaign_table_click(g,behind_rect[2]-2,behind_rect[1]+10)&&g.active_device==behind.board_device,"exposed cascade edge opens the correct robot");campaign_table(g);
    table_layout_assert(g.robot_stack_front[1]==0,"clicked back robot becomes front and owns shared controls");
    var previous_arrow=robot_stack_arrow(1,false);campaign_table_click(g,previous_arrow[0]+4,previous_arrow[1]+4);
    var arrow=robot_stack_arrow(1,true);
    table_layout_assert(campaign_table_click(g,arrow[0]+4,arrow[1]+4)&&g.robot_stack_front[1]==0&&g.robot_stack_front[2]==2,"stack arrow wraps and affects only its type");
    table_layout_assert(robots_click(g,job[0]+4,job[1]+4)&&g.active_device==behind.board_device,"control card follows stack selection");campaign_table(g);
    for(var i=0;i<5;++i) {
        selected=stacks[1][g.robot_stack_front[1]];front=robot_table_hit_rect(selected);
        table_layout_assert(campaign_table_click(g,(front[0]+front[2])/2,(front[1]+front[3])/2)&&g.active_device==selected.board_device,"all assembler instances remain accessible "+string(i));
        campaign_table(g);campaign_table_click(g,arrow[0]+4,arrow[1]+4);
    }
    var old_arrow=robot_stack_arrow(1,false);campaign_table_click(g,old_arrow[0]+4,old_arrow[1]+4);
    table_layout_assert(g.robot_stack_front[1]==4,"previous stack arrow wraps backwards");
    g.generator.stats_base.energy=12;device_stats_update(g.generator);power_update(g);
    var a=stacks[1][4],b=stacks[1][0],solder=stacks[2][2],dismantler=stacks[3][2];
    robot_assign_power(g,a);robot_assign_power(g,b);robot_assign_power(g,solder);robot_assign_power(g,dismantler);
    campaign_open(g,a.board_device);assembler_start(g,a,0);campaign_table(g);robots_tick(g,0.25);
    campaign_open(g,b.board_device);assembler_start(g,b,0);campaign_table(g);robots_tick(g,0.125);
    table_layout_assert(a.working&&b.working&&a.work_frame!=b.work_frame&&a.target_module!=b.target_module,"stacked assemblers keep independent jobs and animations");
    var hit=robot_table_hit_rect(solder);
    table_layout_assert(campaign_table_click(g,(hit[0]+hit[2])/2,(hit[1]+hit[3])/2)&&solder.working&&solder.has_plate,"front solder robot consumes raised table plate");
    hit=robot_table_hit_rect(dismantler);
    table_layout_assert(campaign_table_click(g,(hit[0]+hit[2])/2,(hit[1]+hit[3])/2)&&dismantler.working,"rightmost dismantler starts from its table body");
    robots_tick(g,0.5);table_layout_capture(g,"table-cascades-working");
    var old_count=array_length(stacks[1]);instance_destroy(a);stacks=robots_table_stacks(g);
    table_layout_assert(array_length(stacks[1])==old_count-1,"destroyed robot is removed from stack");
    table_layout_capture(g,"table-stack-after-removal");
    table_layout_assert(g.robot_stack_front[1]<array_length(stacks[1]),"stack front clamps after removal");
    show_debug_message("TABLE_LAYOUT_RESULT passes="+string(global.table_layout_passes)+" failures=0");game_end();
}
