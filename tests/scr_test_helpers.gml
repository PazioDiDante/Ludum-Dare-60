// Helpers for isolated test projects; never included in the release.
function robot_job_rect(_slot,_row=0) {
    var g=instance_find(obj_game,0);
    if(instance_exists(g)) {
        var groups=robot_groups(g);
        if(_row>=0&&_row<array_length(groups)) return robot_row_layout(groups[_row],_row).job;
    }
    var r=robot_card_rect(_slot,_row);return [r[0]+96,r[1]+4,r[2]-4,r[1]+40];
}

function robot_display_rect(_slot,_row,_robot) {
    var g=instance_find(obj_game,0);
    if(instance_exists(g)) {
        var groups=robot_groups(g);
        if(_row>=0&&_row<array_length(groups)) return robot_row_layout(groups[_row],_row).card;
    }
    var r=robot_card_rect(_slot,_row);
    if(_robot.product_id=="recycle_robot") r[2]+=56;
    return r;
}

function generator_restart_rect() {
    return generator_layout(instance_find(obj_game,0)).control;
}

function generator_energy_rect() {
    return generator_layout(instance_find(obj_game,0)).panel;
}

function base_assert(_ok,_label) {
    if (_ok) { global.test_passes++; show_debug_message("PASS: "+_label); }
    else { global.test_failures++; show_debug_message("FAIL: "+_label); }
}

function ui_text_width(_text) {
    if(string_pos("{coin}",_text)==0&&string_pos("{scrap}",_text)==0) return string_width(_text);
    var runs=ui_text_runs(_text),size=max(16,string_height("M")),width=0,widest=0;
    for(var i=0;i<array_length(runs);++i) {
        var run=runs[i];
        if(run.text=="\n") {widest=max(widest,width);width=0;}
        else width+=run.sprite>=0?size:string_width(run.text);
    }
    return max(widest,width);
}

function robots_table_machines(_g) {
    var result=[];
    for(var i=0;i<array_length(_g.robots);++i) {
        var robot=_g.robots[i];
        if(instance_exists(robot)&&sprite_exists(robot_idle_sprite(robot))) array_push(result,robot);
    }
    return result;
}
