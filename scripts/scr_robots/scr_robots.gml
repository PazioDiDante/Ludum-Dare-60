function robot_idle_sprite(_robot) {
    switch(_robot.product_id) {
        case "assembler_robot":return spr_assembler_idle;
        case "dismantle_robot":return spr_deassembler_idle;
        case "solder_robot":return spr_solider_idle;
        case "recycle_robot":return spr_srapper_idle;
    }
    return -1;
}
function robot_work_sprite(_robot) {
    switch(_robot.product_id) {
        case "assembler_robot":return spr_assembler_work;
        case "dismantle_robot":return spr_deassembler_work;
        case "solder_robot":return spr_solider_work;
        case "recycle_robot":return spr_srapper_work;
    }
    return -1;
}
function robot_table_sprite(_robot) {
    return _robot.working&&_robot.powered?robot_work_sprite(_robot):robot_idle_sprite(_robot);
}
// Failed opening/starting clicks point to the exact robot and its energy cells.
function robot_require_power(_g,_robot) {
    if(!instance_exists(_robot)) return false;
    power_update(_g);
    if(_robot.powered) {
        _robot.power_hint_remaining=0;_robot.power_hint_elapsed=0;return true;
    }
    _robot.power_hint_remaining=1.44;_robot.power_hint_elapsed=0;
    return false;
}
function robot_power_hint_alpha(_robot) {
    return _robot.power_hint_remaining>0&&(floor(_robot.power_hint_elapsed/0.18) mod 2)==1?0.2:1;
}
function robot_animation_tick(_robot,_seconds) {
    if(!_robot.working||!_robot.powered) {_robot.work_frame=0;return;}
    var sprite=robot_work_sprite(_robot);if(!sprite_exists(sprite)) return;
    var frame_rate=sprite_get_speed(sprite);
    if(sprite_get_speed_type(sprite)==spritespeed_framespergameframe)
        frame_rate*=game_get_speed(gamespeed_fps);
    _robot.work_frame=(_robot.work_frame+max(0,_seconds)*frame_rate) mod sprite_get_number(sprite);
}

function robot_table_group_index(_robot) {
    switch(_robot.product_id) {
        case "recycle_robot":return 0;
        case "assembler_robot":return 1;
        case "solder_robot":return 2;
        case "dismantle_robot":return 3;
    }
    return -1;
}
function robots_table_stacks(_g) {
    var stacks=[[],[],[],[]];
    for(var i=0;i<array_length(_g.robots);++i) {
        var robot=_g.robots[i];if(!instance_exists(robot)) continue;
        var index=robot_table_group_index(robot);
        if(index>=0) array_push(stacks[index],robot);
    }
    return stacks;
}
function robot_table_group_center(_index) {
    // Reserve the left HUD and use the entire remaining width, including the right edge.
    return 232+(display_get_gui_width()-256)/4*(_index+0.5)-16;
}
// Each type has one footprint. Up to three real instances form its visible cascade.
// Extra instances remain reachable through the group's front-selection arrows.
function robot_table_rect(_robot,_stack_depth=0) {
    var idle=robot_idle_sprite(_robot),work=robot_work_sprite(_robot);
    var left=min(sprite_get_bbox_left(idle),sprite_get_bbox_left(work));
    var right=max(sprite_get_bbox_right(idle),sprite_get_bbox_right(work))+1;
    var top=min(sprite_get_bbox_top(idle),sprite_get_bbox_top(work));
    var bottom=max(sprite_get_bbox_bottom(idle),sprite_get_bbox_bottom(work))+1;
    var lift=min(12,max(0,floor((184-(bottom-top)*2)/2)));
    var px=robot_table_group_center(robot_table_group_index(_robot))-(left+right)+_stack_depth*16;
    var py=656-bottom*2-_stack_depth*lift;
    return [px,py,px+sprite_get_width(idle)*2,py+sprite_get_height(idle)*2];
}
function robot_table_hit_rect(_robot,_stack_depth=0) {
    var r=robot_table_rect(_robot,_stack_depth),sprite=robot_table_sprite(_robot);
    return [r[0]+sprite_get_bbox_left(sprite)*2,r[1]+sprite_get_bbox_top(sprite)*2,
        r[0]+(sprite_get_bbox_right(sprite)+1)*2,r[1]+(sprite_get_bbox_bottom(sprite)+1)*2];
}
function robot_stack_arrow(_index,_next) {
    var left=robot_table_group_center(_index)-66+(_next?104:0);
    return [left,664,left+28,692];
}
function robots_table_click(_g,_x,_y) {
    var stacks=robots_table_stacks(_g);
    for(var group=0;group<4;++group) {
        var machines=stacks[group],count=array_length(machines);if(count==0) continue;
        var first=clamp(_g.robot_stack_front[group],0,count-1);_g.robot_stack_front[group]=first;
        if(count>1) for(var next=0;next<2;++next) {
            if(campaign_hit(_x,_y,robot_stack_arrow(group,next==1))) {
                _g.robot_stack_front[group]=(first+(next==1?1:count-1)) mod count;
                return true;
            }
        }
        // Test the front instance first, in reverse of the painter's order.
        for(var stack_depth=0;stack_depth<min(3,count);++stack_depth) {
            var robot=machines[(first+stack_depth) mod count];
            if(!campaign_hit(_x,_y,robot_table_hit_rect(robot,stack_depth))) continue;
            _g.robot_stack_front[group]=(first+stack_depth) mod count;
            if(robot.product_id=="assembler_robot"||robot.product_id=="recycle_robot") sfx_action(campaign_open(_g,robot.board_device));
            else sfx_action(robot_start(_g,robot));
            return true;
        }
    }
    return false;
}
function robots_table_draw(_g) {
    var stacks=robots_table_stacks(_g);
    for(var group=0;group<4;++group) {
        var machines=stacks[group],count=array_length(machines);if(count==0) continue;
        var first=clamp(_g.robot_stack_front[group],0,count-1);_g.robot_stack_front[group]=first;
        for(var stack_depth=min(3,count)-1;stack_depth>=0;--stack_depth) {
            var robot=machines[(first+stack_depth) mod count],sprite=robot_table_sprite(robot);
            if(!robot.powered) shader_set(shd_module_unpowered);
            campaign_sprite(sprite,robot_table_rect(robot,stack_depth),1,0,robot.working&&robot.powered?floor(robot.work_frame):0);
            if(!robot.powered) {
                shader_reset();
                // Keep the warning coloured and centred on the visible robot body.
                var bounds=robot_table_hit_rect(robot,stack_depth);
                var cx=floor((bounds[0]+bounds[2])/2),cy=floor((bounds[1]+bounds[3])/2);
                campaign_sprite(spr_enrgy_off,[cx-48,cy-48,cx+48,cy+48],robot_power_hint_alpha(robot));
            }
        }
        if(count>1) {
            campaign_button(robot_stack_arrow(group,false),"<");
            campaign_button(robot_stack_arrow(group,true),">");
            draw_set_halign(fa_center);draw_set_color(c_white);
            ui_text(robot_table_group_center(group),670,string(first+1)+" / "+string(count));
            draw_set_halign(fa_left);
        }
    }
}
function robot_create_recycler(_g) {
    var robot=instance_create_depth(0,0,0,obj_robot,{product_id:"recycle_robot",energy_cost:2,work_seconds:30,reward:1});
    array_push(_g.robots,robot);
    recycler_setup(robot);
    return robot;
}
function recycler_setup(_robot) {
    _robot.board_device=campaign_create_device(obj_recycler_board);
    _robot.board_device.robot_owner=_robot;
    campaign_visible(_robot.board_device,false);
}
// Row-major queue order. A part being moved is never taken from under the cursor.
function recycler_first_module(_robot) {
    var d=_robot.board_device;if(!instance_exists(d)) return noone;
    for(var row=0;row<d.rows;++row) for(var col=0;col<d.cols;++col) {
        var item=d.board[row][col];
        if(!instance_exists(item)||item==d.selected_module) continue;
        if(item.device==d&&!item.in_inventory&&item.inventory_origin<0&&!item.removing) return item;
    }
    return noone;
}
function robot_start(_g,_robot) {
    if(!instance_exists(_robot)||_robot.working||array_length(_robot.outputs)>0) return false;
    var recycler=_robot.product_id=="recycle_robot";
    if(_robot.product_id=="assembler_robot") return false; // Select an explicit recipe in its panel.
    if(global.mode!=GameMode.Menu&&!(recycler&&global.mode==GameMode.Play)) return false;
    if(!robot_require_power(_g,_robot)) return false;
    if(_robot.product_id=="solder_robot") {
        if(!campaign_plate_available(_g)||_robot.has_plate) return false;
        _g.table_plate=false;_robot.has_plate=true;
    }
    if(recycler) {
        var item=recycler_first_module(_robot);if(!instance_exists(item)) return false;
        module_detach(item);item.visible=false;item.interaction_enabled=false;
        _robot.target_module=item;
        _robot.recycle_value=max(0,item.scrap_cost)*0.5; // Capture the physical part's value once.
    }
    if(_robot.product_id=="dismantle_robot") {
        if(array_length(_g.table_devices)==0) return false;
        var d=_g.table_devices[0];
        if(!instance_exists(d)||d.is_order||d.is_generator||d.completed||d==_g.active_device||instance_exists(d.automation_owner)) return false;
        // Reserve the actual workpiece, so other robots and the player cannot take it.
        array_delete(_g.table_devices,0,1);
        d.automation_owner=_robot;
        _robot.target_device=d;
        campaign_visible(d,false);
    }
    _robot.working=true;_robot.remaining=_robot.work_seconds;_robot.work_frame=0;
    power_update(_g);return true;
}
function robot_store_outputs(_g,_robot) {
    for(var i=array_length(_robot.outputs)-1;i>=0;--i) {
        var item=_robot.outputs[i];
        if(!instance_exists(item)||inventory_add(_g,item)) array_delete(_robot.outputs,i,1);
    }
}
function robot_finish(_g,_robot) {
    if(!_robot.working) return;
    // Clear the running state before rewards; each job can finish only once.
    _robot.working=false;_robot.remaining=0;
    _robot.work_frame=0;
    if(_robot.product_id=="solder_robot") {
        if(_robot.has_plate) {_robot.has_plate=false;campaign_credit(_g,_robot.reward);sfx_play(snd_robotDone);}
        return;
    }
    if(_robot.product_id=="recycle_robot") {
        var item=_robot.target_module;_robot.target_module=noone;
        if(instance_exists(item)) {instance_destroy(item);_g.scrap+=_robot.recycle_value;sfx_play(snd_robotDone);}
        _robot.recycle_value=0;
        return;
    }
    if(_robot.product_id=="assembler_robot") {
        var item=_robot.target_module;_robot.target_module=noone;
        if(instance_exists(item)) {
            item.interaction_enabled=true;
            array_push(_robot.outputs,item);
            robot_store_outputs(_g,_robot);
            sfx_play(snd_robotDone);
        }
        return;
    }
    var d=_robot.target_device;_robot.target_device=noone;
    if(!instance_exists(d)) return;
    // Uses precisely the manual opening path and this device's generation rules.
    // An already-open device retains its existing parts rather than rolling again.
    if(!d.cover_open) d.open_cover();
    var parts=[];
    for(var i=0;i<instance_number(par_module);++i) {
        var item=instance_find(par_module,i);
        if(item.device==d&&!item.in_inventory) array_push(parts,item);
    }
    for(var i=0;i<array_length(parts);++i) {
        var item=parts[i];module_detach(item);
        item.visible=false;item.interaction_enabled=true;
        array_push(_robot.outputs,item);
    }
    instance_destroy(d);
    // Extra inventory pages are used automatically. Oversized parts remain on the
    // robot until they fit, so a layout change can never silently destroy loot.
    robot_store_outputs(_g,_robot);
    sfx_play(snd_robotDone);
}
function robots_tick(_g,_seconds) {
    if(global.mode==GameMode.Pause) return;
    for(var i=0;i<array_length(_g.robots);++i) {
        var robot=_g.robots[i];if(!instance_exists(robot)) continue;
        if(robot.powered) {robot.power_hint_remaining=0;robot.power_hint_elapsed=0;}
        else if(robot.power_hint_remaining>0) {
            var seconds=max(0,_seconds);
            robot.power_hint_elapsed+=seconds;
            robot.power_hint_remaining=max(0,robot.power_hint_remaining-seconds);
        }
        if(array_length(robot.outputs)>0) robot_store_outputs(_g,robot);
        if(robot.product_id=="recycle_robot"&&!robot.working&&robot.powered)
            robot_start(_g,robot);
        robot_animation_tick(robot,_seconds);
        if(!robot.working||!robot.powered) continue;
        robot.remaining=max(0,robot.remaining-_seconds);
        if(robot.remaining<=0) robot_finish(_g,robot);
    }
    power_update(_g);
}
// Bottom-up rows: recycler, assembler, solder robots, dismantle robots.
function robot_card_rect(_slot,_row=0) {
    var g=instance_find(obj_game,0),compact=instance_exists(g)&&array_length(robot_groups(g))>3;
    var top=display_get_gui_height()-(compact?104:112)-_row*(compact?48:56);
    return [16+_slot*144,top,152+_slot*144,top+(compact?46:48)];
}

function robot_groups(_g) {
    var types=["recycle_robot","assembler_robot","solder_robot","dismantle_robot"],groups=[];
    for(var type_index=0;type_index<array_length(types);++type_index) {
        var machines=[];
        for(var i=0;i<array_length(_g.robots);++i) {
            var robot=_g.robots[i];
            if(instance_exists(robot)&&robot.product_id==types[type_index]) array_push(machines,robot);
        }
        if(array_length(machines)>0) array_push(groups,{machines:machines,stack_index:type_index});
    }
    return groups;
}
// Keep every instance's power cells visible in purchase order, independently
// of which robot is at the front of the table stack.
function robot_row_layout(_group,_row) {
    var r=robot_card_rect(0,_row),machines=_group.machines,total=0;
    for(var i=0;i<array_length(machines);++i) total+=machines[i].energy_cost;
    var recycler=machines[0].product_id=="recycle_robot";
    var available=max(1,display_get_gui_width()-r[0]-44-4-40-(recycler?56:0)-16);
    var width=min(total>2?16:20,available/max(1,total)),left=r[0]+44,blocks=[];
    for(var i=0;i<array_length(machines);++i) {
        var right=left+machines[i].energy_cost*width;
        array_push(blocks,{robot:machines[i],index:i,rect:[left,r[1]+4,right,r[1]+36]});
        left=right;
    }
    var action_left=max(r[0]+96,left+4),job=[action_left,r[1]+4,action_left+36,r[1]+40];
    r[2]=job[2]+4+(recycler?56:0);
    return {card:r,job:job,energy:blocks,cell_width:width};
}
function robots_click(_g,_x,_y,_button=mb_left) {
    if(global.mode!=GameMode.Menu) return false;
    var groups=robot_groups(_g);
    for(var row=0;row<array_length(groups);++row) {
        var group=groups[row],first=clamp(_g.robot_stack_front[group.stack_index],0,array_length(group.machines)-1);
        var robot=group.machines[first],layout=robot_row_layout(group,row);
        if(!campaign_hit(_x,_y,layout.card)) continue;
        for(var i=0;i<array_length(layout.energy);++i) {
            var block=layout.energy[i];
            if(!campaign_hit(_x,_y,block.rect)) continue;
            if(_button==mb_left||_button==mb_right) {
                _g.robot_stack_front[group.stack_index]=block.index;
                if(_button==mb_right) sfx_action(robot_release_power(_g,block.robot));
                else sfx_action(robot_assign_power(_g,block.robot));
            }
            return true;
        }
        if(_button==mb_right) sfx_action(robot_release_power(_g,robot));
        else if(_button==mb_left) {
            if(campaign_hit(_x,_y,layout.job)) {
                if(robot.product_id=="recycle_robot"||robot.product_id=="assembler_robot") sfx_action(campaign_open(_g,robot.board_device));
                else sfx_action(robot_start(_g,robot));
            }
            else sfx_action(robot_assign_power(_g,robot));
        }
        return true;
    }
    return false;
}
function robots_draw(_g) {
    if(global.mode!=GameMode.Menu) return;
    draw_set_alpha(1);draw_set_halign(fa_left);draw_set_valign(fa_top);
    var filtering=gpu_get_texfilter();gpu_set_texfilter(false);
    var groups=robot_groups(_g);
    for(var row=0;row<array_length(groups);++row) {
        var group=groups[row],count=array_length(group.machines);
        var first=clamp(_g.robot_stack_front[group.stack_index],0,count-1);
        var robot=group.machines[first],layout=robot_row_layout(group,row),r=layout.card,recycler=robot.product_id=="recycle_robot";
        draw_set_color(make_color_rgb(22,35,48));draw_rectangle(r[0],r[1],r[2],r[3],false);
        draw_set_color(make_color_rgb(65,85,105));draw_rectangle(r[0],r[1],r[2],r[3],true);
        var icon=robot_idle_sprite(robot);if(!sprite_exists(icon)) icon=spr_cog;
        if(!robot.powered) shader_set(shd_module_unpowered);
        campaign_sprite(icon,[r[0]+8,r[1]+8,r[0]+32,r[1]+32]);
        if(!robot.powered) shader_reset();
        for(var i=0;i<array_length(layout.energy);++i) {
            var block=layout.energy[i],energy_robot=block.robot;
            for(var cell=0;cell<energy_robot.energy_cost;++cell) {
                var left=block.rect[0]+cell*layout.cell_width;
                campaign_sprite(energy_robot.powered?spr_stat_blue_full:spr_stat_blue_empty,[left,block.rect[1],left+layout.cell_width,block.rect[3]],robot_power_hint_alpha(energy_robot));
            }
            if(count>1&&block.index==first) {
                draw_set_color(make_color_rgb(125,155,175));
                draw_rectangle(block.rect[0]-1,block.rect[1]-1,block.rect[2],block.rect[3],true);
                draw_set_color(c_white);
            }
        }
        var assembler=robot.product_id=="assembler_robot",solder=robot.product_id=="solder_robot",blocked=array_length(robot.outputs)>0;
        var has_input=recycler?instance_exists(recycler_first_module(robot)):(solder?campaign_plate_available(_g):array_length(_g.table_devices)>0);
        var enabled=robot.powered&&(recycler||assembler||(!robot.working&&!blocked&&has_input));
        draw_set_alpha((solder&&robot.has_plate)||enabled?1:0.3);
        campaign_sprite(solder&&robot.has_plate?spr_plate:((recycler||assembler)?spr_modifyGenerator:spr_play),[layout.job[0]+4,r[1]+8,layout.job[0]+28,r[1]+32]);
        draw_set_alpha(1);
        if(recycler) {
            var preview_left=layout.job[2]+12;
            draw_set_color(make_color_rgb(35,49,61));draw_rectangle(preview_left,r[1]+4,r[2]-4,r[3]-10,false);
            robot_module_preview(robot.target_module,[preview_left+2,r[1]+6,r[2]-6,r[3]-12]);
        }
        draw_set_color(make_color_rgb(40,54,65));draw_rectangle(r[0]+2,r[3]-6,r[2]-2,r[3]-2,false);
        if(robot.working) {
            draw_set_color(robot.powered?c_aqua:make_color_rgb(80,110,135));
            draw_rectangle(r[0]+2,r[3]-6,r[0]+2+(r[2]-r[0]-4)*(1-robot.remaining/robot.work_seconds),r[3]-2,false);
        }
    }
    gpu_set_texfilter(filtering);draw_set_font(game_font_default());draw_set_color(c_white);draw_set_alpha(1);
}

// Preview the reserved physical module, including its current rotation.
function robot_module_preview(_item,_rect) {
    if(!is_struct(_item)&&!instance_exists(_item)) return;
    var w=array_length(_item.shape[0])*16,h=array_length(_item.shape)*16;
    var scale=min((_rect[2]-_rect[0])/w,(_rect[3]-_rect[1])/h);
    var left=(_rect[0]+_rect[2]-w*scale)/2,top=(_rect[1]+_rect[3]-h*scale)/2;
    if(sprite_exists(_item.sprite_index)) {
        var off=module_sprite_offset(_item.sprite_index,_item.rotation_steps,scale);
        draw_sprite_ext(_item.sprite_index,_item.image_index,left+off[0],top+off[1],scale,scale,-90*_item.rotation_steps,_item.image_blend,1);
    } else {
        draw_set_color(_item.module_color);
        for(var row=0;row<array_length(_item.shape);++row) for(var col=0;col<array_length(_item.shape[row]);++col)
            if(_item.shape[row][col]!=Cell.Empty) draw_rectangle(left+col*16*scale+1,top+row*16*scale+1,left+(col+1)*16*scale-1,top+(row+1)*16*scale-1,false);
        draw_set_color(c_white);
    }
}
function recycler_board_draw(_g,_d) {
    var robot=_d.robot_owner;if(!instance_exists(robot)) return;
    var left=_d.board_x+_d.cols*_d.cell_size+16,top=_d.board_y;
    draw_set_font(_g.ui_font);draw_set_color(c_white);ui_text(left,top,"Processing");
    draw_set_color(make_color_rgb(22,35,48));draw_rectangle(left,top+28,left+144,top+124,false);
    robot_module_preview(robot.target_module,[left+8,top+36,left+136,top+112]);
    draw_set_color(make_color_rgb(40,54,65));draw_rectangle(left,top+132,left+144,top+140,false);
    if(robot.working) {
        draw_set_color(robot.powered?c_aqua:c_gray);
        draw_rectangle(left,top+132,left+144*(1-robot.remaining/robot.work_seconds),top+140,false);
    }
    draw_set_color(c_white);ui_text(left,top+152,"{scrap} "+string(_g.scrap));
}
