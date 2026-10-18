function robot_visual_assert(_ok,_label) {
    if(!_ok) throw "ROBOT_VISUAL_FAILURE: "+_label;
    global.robot_visual_passes++;
}
function robot_visual_click(_g,_robot,_slot) {
    var r=robot_table_hit_rect(_robot);
    return campaign_table_click(_g,(r[0]+r[2])/2,(r[1]+r[3])/2);
}
function robot_visual_tests() {
    global.robot_visual_passes=0;
    var g=instance_find(obj_game,0);g.money=2000;g.scrap=100;
    robot_visual_assert(shop_buy(g,"assembler_robot")&&shop_buy(g,"solder_robot")&&shop_buy(g,"dismantle_robot"),"purchase all three robot types");
    var assembler=g.robots[1],solder=g.robots[2],dismantler=g.robots[3];
    var machines=robots_table_machines(g);
    robot_visual_assert(array_length(machines)==4&&machines[0]==g.recycler_robot&&machines[1]==assembler&&machines[2]==solder&&machines[3]==dismantler&&g.robot_stack_front[1]==0,"all four types visible in separate columns");
    machines=[assembler,solder,dismantler];
    robot_visual_assert(robot_table_sprite(solder)==spr_solider_idle&&robot_table_sprite(dismantler)==spr_deassembler_idle,"new purchases use their own idle art");
    while(array_length(g.table_devices)<6) campaign_buy(g);
    for(var i=0;i<array_length(g.table_devices);++i) g.table_devices[i].arrival_progress=1;
    campaign_earn(g);
    var previous=-1,donor_rect=campaign_item_rect(5),plate_rect=campaign_plate_rect();
    for(var slot=0;slot<3;++slot) {
        var r=robot_table_hit_rect(machines[slot]);
        robot_visual_assert(r[1]>=donor_rect[3]&&r[3]<=656&&r[2]<display_get_gui_width()-16,"machine clears donor slots and table edge "+string(slot));
        if(slot>0) robot_visual_assert(r[0]>previous,"neighboring types do not overlap");
        previous=r[2];
    }
    assembler_visual_capture(g,"robots-all-idle");
    var donors=array_length(g.table_devices),cash=g.money;
    robot_visual_assert(robot_visual_click(g,solder,1)&&!solder.working&&g.table_plate&&g.money==cash,"unpowered solder click consumes no plate or money");
    robot_visual_assert(robot_visual_click(g,dismantler,2)&&!dismantler.working&&array_length(g.table_devices)==donors,"unpowered dismantler consumes no donor");
    g.generator.stats_base.energy=12;device_stats_update(g.generator);power_update(g);
    robot_assign_power(g,assembler);robot_assign_power(g,solder);robot_assign_power(g,dismantler);
    robot_visual_assert(g.power_used==5&&solder.energy_cost==1&&dismantler.energy_cost==1,"existing energy requirements preserved");
    robot_visual_assert(robot_visual_click(g,solder,1)&&solder.working&&solder.has_plate&&!g.table_plate&&solder.work_frame==0&&robot_table_sprite(solder)==spr_solider_work,"table click reserves plate and starts solder animation");
    var reserved=g.table_devices[0];
    robot_visual_assert(robot_visual_click(g,dismantler,2)&&dismantler.working&&dismantler.target_device==reserved&&array_length(g.table_devices)==donors-1&&robot_table_sprite(dismantler)==spr_deassembler_work,"table click reserves donor and starts dismantler animation");
    robot_visual_assert(robot_visual_click(g,solder,1)&&robot_visual_click(g,dismantler,2)&&array_length(g.table_devices)==donors-1&&solder.remaining==10&&dismantler.remaining==30,"busy clicks cannot duplicate work or consume another donor");
    robot_visual_assert(robot_visual_click(g,assembler,0)&&g.active_device==assembler.board_device,"assembler still opens its catalog");
    robot_visual_assert(assembler_start(g,assembler,0),"assembler can work alongside both new robots");campaign_table(g);
    robots_tick(g,0.25);
    robot_visual_assert(abs(solder.work_frame-1.5)<0.001&&abs(dismantler.work_frame-1.5)<0.001&&abs(assembler.work_frame-1.5)<0.001,"all three work animations advance at authored six FPS");
    assembler_visual_capture(g,"robots-working-frame1");
    robots_tick(g,0.25);robot_visual_assert(floor(solder.work_frame)==3&&floor(dismantler.work_frame)==3,"new work animations advance to distinct frames");
    assembler_visual_capture(g,"robots-working-frame3");
    robots_tick(g,1);robot_visual_assert(abs(solder.work_frame-3)<0.001&&abs(dismantler.work_frame-3)<0.001,"new animations loop");
    var time_left=solder.remaining,frame=solder.work_frame;
    global.mode=GameMode.Pause;robots_tick(g,3);
    robot_visual_assert(solder.remaining==time_left&&solder.work_frame==frame&&dismantler.work_frame==frame,"pause freezes both jobs and animations");global.mode=GameMode.Menu;
    generator_stop(g,"visual suite");robots_tick(g,3);
    robot_visual_assert(robot_table_sprite(solder)==spr_solider_idle&&robot_table_sprite(dismantler)==spr_deassembler_idle&&solder.work_frame==0&&dismantler.work_frame==0&&solder.remaining==time_left,"power loss idles both robots and preserves progress");
    assembler_visual_capture(g,"robots-power-off");generator_restart(g);robots_tick(g,0.25);
    robot_visual_assert(abs(solder.work_frame-1.5)<0.001&&abs(dismantler.work_frame-1.5)<0.001,"power restoration resumes both animations");
    robot_release_power(g,solder);robots_tick(g,0.25);
    robot_visual_assert(solder.work_frame==0&&robot_table_sprite(solder)==spr_solider_idle&&floor(dismantler.work_frame)==3,"releasing one allocation leaves other machine working");
    robot_assign_power(g,solder);robots_tick(g,solder.remaining);
    robot_visual_assert(!solder.working&&!solder.has_plate&&solder.work_frame==0&&robot_table_sprite(solder)==spr_solider_idle&&g.money==cash+20,"solder completion pays twenty exactly once and returns to idle");
    robot_visual_assert(dismantler.working&&robot_table_sprite(dismantler)==spr_deassembler_work,"longer dismantling job continues independently");
    robot_visual_assert(robot_visual_click(g,solder,1)&&!solder.working&&g.money==cash+20,"powered solder robot stays idle without a new plate");
    robots_tick(g,dismantler.remaining);
    robot_visual_assert(!dismantler.working&&dismantler.work_frame==0&&robot_table_sprite(dismantler)==spr_deassembler_idle&&!instance_exists(reserved),"dismantling completion returns to idle and consumes reserved device");
    var stored=0;for(var i=0;i<array_length(g.inventory);++i) if(instance_exists(g.inventory[i])) stored++;
    robot_visual_assert(stored>=5&&array_length(dismantler.outputs)==0,"real dismantled starter parts and crafted output reach inventory");
    for(var i=0;i<array_length(g.table_devices);++i) instance_destroy(g.table_devices[i]);g.table_devices=[];
    robot_visual_assert(robot_visual_click(g,dismantler,2)&&!dismantler.working&&g.active_device==noone,"dismantler stays idle without donors");
    campaign_earn(g);robot_visual_click(g,solder,1);robot_visual_assert(solder.working&&solder.work_frame==0,"new plate starts a fresh animation from zero");
    robot_visual_assert(shop_buy(g,"solder_robot")&&g.robot_stack_front[2]==1,"second solder purchase comes to front of its cascade");
    var second=g.robots[array_length(g.robots)-1];
    robot_visual_assert(!second.working&&robot_table_sprite(second)==spr_solider_idle&&solder.working,"second solder robot starts independently idle");
    var arrow=robot_stack_arrow(2,false);robots_table_click(g,arrow[0]+4,arrow[1]+4);
    robot_visual_assert(g.robot_stack_front[2]==0,"stack selection returns to first solder robot");
    assembler_visual_capture(g,"robots-finished");
    show_debug_message("ROBOT_VISUAL_RESULT passes="+string(global.robot_visual_passes)+" failures=0");game_end();
}
