// Isolated integration checks for purchased instances sharing one energy row.
function robot_energy_assert(_ok,_label) {
    if(!_ok) throw "ROBOT_ENERGY_FAILURE: "+_label;
    global.robot_energy_passes++;
}
function robot_energy_click(_g,_block,_button=mb_left,_cell=0,_width=16) {
    return robots_click(_g,_block.rect[0]+_cell*_width+_width/2,(_block.rect[1]+_block.rect[3])/2,_button);
}
function robot_energy_render(_g,_layout,_filename) {
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    campaign_table_draw(_g);campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    surface_reset_target();
    var pixels=[];
    for(var i=0;i<array_length(_layout.energy);++i) {
        var b=_layout.energy[i];
        array_push(pixels,surface_getpixel(sf,floor((b.rect[0]+b.rect[2])/2),floor((b.rect[1]+b.rect[3])/2)));
    }
    surface_save(sf,_filename);surface_free(sf);return pixels;
}
function robot_energy_tests() {
    global.robot_energy_passes=0;
    var g=instance_find(obj_game,0);g.money=10000;g.scrap=100;
    repeat(2) robot_energy_assert(shop_buy(g,"assembler_robot"),"buy another assembler");
    repeat(3) robot_energy_assert(shop_buy(g,"solder_robot"),"buy another solder robot");
    repeat(2) robot_energy_assert(shop_buy(g,"dismantle_robot"),"buy another dismantler");
    var groups=robot_groups(g),layout=robot_row_layout(groups[2],2),blocks=layout.energy;
    robot_energy_assert(array_length(blocks)==3,"all three solder instances have visible energy blocks");
    var stacks=robots_table_stacks(g),solder=stacks[2];
    for(var i=0;i<3;++i) {
        robot_energy_assert(blocks[i].robot==solder[i],"energy blocks retain purchase order");
        robot_energy_assert(blocks[i].rect[2]<=layout.job[0],"energy cells do not overlap the shared action");
        if(i>0) robot_energy_assert(blocks[i].rect[0]>=blocks[i-1].rect[2],"purchased robots have separate hit regions");
    }
    g.generator.stats_base.energy=20;device_stats_update(g.generator);power_update(g);
    robot_energy_assert(robot_energy_click(g,blocks[1])&&solder[1].powered&&!solder[0].power_allocated&&!solder[2].power_allocated,"middle cell powers its own non-front instance");
    robot_energy_assert(g.robot_stack_front[2]==1&&g.power_used==1,"power click selects that instance without affecting other allocations");
    var pixels=robot_energy_render(g,layout,"robot-energy-line.png");
    robot_energy_assert(pixels[0]==pixels[2]&&pixels[1]!=pixels[0],"render shows empty/full/empty cells for all three real robots");
    var arrow=robot_stack_arrow(2,true);robots_table_click(g,arrow[0]+4,arrow[1]+4);
    var after=robot_row_layout(robot_groups(g)[2],2);
    robot_energy_assert(g.robot_stack_front[2]==2&&array_length(after.energy)==3,"front selection never hides other energy blocks");
    for(var i=0;i<3;++i)
        robot_energy_assert(after.energy[i].robot==blocks[i].robot&&json_stringify(after.energy[i].rect)==json_stringify(blocks[i].rect),"changing front preserves power-row order and positions");
    var after_pixels=robot_energy_render(g,after,"robot-energy-other-front.png");
    robot_energy_assert(json_stringify(pixels)==json_stringify(after_pixels),"front arrows do not change displayed power states");
    robot_energy_assert(robot_energy_click(g,blocks[0])&&solder[0].powered&&solder[1].powered&&!solder[2].powered,"first cell allocates another instance independently");
    robot_energy_assert(robot_energy_click(g,blocks[1],mb_right)&&solder[0].powered&&!solder[1].power_allocated&&g.power_used==1,"right click releases only the clicked robot");
    campaign_earn(g);var job=robot_job_rect(0,2);
    robot_energy_assert(robot_energy_click(g,blocks[0])&&robots_click(g,job[0]+4,job[1]+4)&&solder[0].working&&!solder[1].working,"shared action still starts the selected instance");
    var assembler_layout=robot_row_layout(robot_groups(g)[1],1),assemblers=stacks[1];
    robot_energy_assert(array_length(assembler_layout.energy)==2&&assembler_layout.energy[1].rect[2]-assembler_layout.energy[1].rect[0]==3*assembler_layout.cell_width,"each assembler contributes its full three-cell energy cost");
    robot_energy_assert(robot_energy_click(g,assembler_layout.energy[1],mb_left,2,assembler_layout.cell_width)&&assemblers[1].powered&&!assemblers[0].power_allocated,"last cell of a multi-cell block targets the correct assembler");
    var selected=assemblers[1];job=robot_job_rect(0,1);
    robot_energy_assert(robots_click(g,job[0]+4,job[1]+4)&&g.active_device==selected.board_device,"shifted modify button opens the selected assembler");campaign_table(g);
    generator_stop(g,"test");power_update(g);
    var off=robot_energy_render(g,layout,"robot-energy-outage.png");
    robot_energy_assert(off[0]==off[1]&&off[1]==off[2]&&!solder[0].powered&&solder[0].power_allocated,"outage empties every displayed cell without discarding allocations");
    generator_restart(g);power_update(g);
    robot_energy_assert(solder[0].powered&&assemblers[1].powered,"power restoration restores individual displayed states");
    instance_destroy(solder[1]);after=robot_row_layout(robot_groups(g)[2],2);
    robot_energy_assert(array_length(after.energy)==2&&after.energy[0].robot==solder[0]&&after.energy[1].robot==solder[2],"removing a robot compacts only its energy block");
    robot_energy_render(g,after,"robot-energy-after-removal.png");
    show_debug_message("ROBOT_ENERGY_RESULT passes="+string(global.robot_energy_passes)+" failures=0");game_end();
}
