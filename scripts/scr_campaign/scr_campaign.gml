	// Single module list for gameplay and analysis. Add new par_module children here.
function game_module_types() {
    return [
    obj_module_battery,
    obj_module_cooler,
    obj_module_stabilizer,
    obj_module_accumulator,
    obj_module_coil,
    obj_module_double_battery,
    obj_module_balancer,
    obj_module_universal,
    obj_module_little_speed,
    obj_module_little_efficiency,
    obj_module_speed_efficiency,
    obj_module_fast_rewind,
    obj_module_productivity,
    obj_module_big_boy,
    obj_module_adapter,
    obj_module_adapter_corner
];
}

// Keep the four-stat manual sandbox independent of active gameplay characteristics.
function game_stat_keys() {return ["energy","weight","heat","stability","speed","efficiency"];}
function game_stat_icons() {return [spr_stat_energy,spr_stat_weight,spr_stat_heat,spr_stat_stability,spr_stat_speed,spr_stat_eff];}
function game_stat_icon(_icon,_x,_y) {
    campaign_sprite(_icon,[_x,_y,_x+32,_y+32]);
}

// Shared layout for all workpieces; the left third belongs to UI.
function campaign_create_device(_type) {
    return instance_create_depth(floor(room_width/3)+(room_width-floor(room_width/3))/2,
        (80+room_height-48)/2,0,_type,{work_layout:true});
}
// Session economy and persistent workpieces. Values requested for the prototype.
function campaign_load() {
    var names=["manual_modules.json","campaign_catalog.json"];
    for(var i=0;i<array_length(names);++i) {
        if(!file_exists(names[i])) continue;
        try {
            var f=file_text_open_read(names[i]),data="";
            while(!file_text_eof(f)) {data+=file_text_read_string(f);file_text_readln(f);}file_text_close(f);
            var model=manual_validate(json_parse(data));
            if(model.ok) return model;
        } catch(err) {}
    }
    return undefined;
}
function campaign_visible(_device,_visible) {
    if(!instance_exists(_device)) return;
    _device.visible=_visible;_device.interaction_enabled=_visible && !_device.completed;
    for(var i=0;i<array_length(_device.children);++i) {
        var item=_device.children[i];if(!instance_exists(item)) continue;
        item.visible=_visible && !_device.completed;item.interaction_enabled=_visible && !_device.completed;
    }
}
function campaign_table(_g) {
    screw_cancel(_g);
    var d=_g.active_device;
    if(instance_exists(d)) {
        board_cancel(d);wire_cancel(d);campaign_visible(d,false);
    }
    _g.active_device=noone;global.hover_target=noone;global.mode=GameMode.Menu;
    _g.pointer_ready=false;_g.finish_confirm=false;
}
function campaign_open(_g,_device) {
    if(!instance_exists(_device)) return false;
    if(_device.is_generator && (_device.broken || _device.repair_remaining>0)) return false;
    if(instance_exists(_device.automation_owner)) return false;
    campaign_table(_g);_g.active_device=_device;_g.active_type=_device.object_index;
    if(_device.is_generator) generator_stop(_g,"Stopped to edit the board");
    campaign_visible(_device,true);global.mode=GameMode.Play;
    device_stats_update(_device);
    _g.ready_sound_device=_device;_g.ready_sound_state=_device.requirements_met;
    campaign_device_layout(_g,_device);
    _g.pointer_ready=false;return true;
}
// Assign starter contents when acquired, independently of opening/robot order.
function campaign_add_device(_g) {
    var type=_g.device_types[irandom(array_length(_g.device_types)-1)];
    var d=campaign_create_device(type);
    d.campaign=true;d.module_min=2;d.module_max=3;
    switch(_g.campaign_devices_created) {
        case 0:
            d.campaign_loot_types=[obj_module_battery,obj_module_battery,obj_module_cooler,obj_module_stabilizer];
            break;
        case 1:
            d.campaign_loot_types=[obj_module_double_battery,obj_module_coil,obj_module_universal];
            break;
    }
    _g.campaign_devices_created++;
    array_push(_g.table_devices,d);campaign_visible(d,false);
    return d;
}
function campaign_buy(_g) {
    if(global.mode!=GameMode.Menu || _g.money<25 || array_length(_g.table_devices)>=6) return false;
    var d=campaign_add_device(_g);
    d.arrival_progress=0;
    _g.money-=25;
    return true;
}
function campaign_earn_seconds(_g) {return shop_owned(_g,"fast_manual_income")?2.5:5;}
function campaign_earn(_g) {
    if(global.mode!=GameMode.Menu||_g.table_plate||_g.earn_remaining>0) return false;
    _g.table_plate=true;return true;
}
function campaign_plate_available(_g) {return _g.table_plate&&_g.earn_remaining<=0;}
function campaign_solder_plate(_g) {
    if(global.mode!=GameMode.Menu||!campaign_plate_available(_g)) return false;
    _g.earn_duration=campaign_earn_seconds(_g);
    _g.earn_remaining=_g.earn_duration;return true;
}
function campaign_table_item_size() {return 64*max(1,floor(obj_game.table_pixel_scale));}
function campaign_plate_rect() {
    var size=campaign_table_item_size(),order=campaign_order_rect(),top=order[3]+16;
    return [order[0],top,order[0]+size,top+size];
}
function campaign_order_rect() {
    var row=campaign_item_rect(0),size=campaign_table_item_size();
    return [852,row[1],852+size,row[1]+size];
}
// DEBUG: remove all screws instantly, including the one being unscrewed manually.
function campaign_debug_unscrew(_g) {
    if(!_g.debug_tools || global.mode!=GameMode.Play) return false;
    var d=_g.active_device;
    if(!instance_exists(d) || d.cover_open || d.completed) return false;
    screw_cancel(_g);
    for(var i=array_length(d.children)-1;i>=0;--i) {
        var child=d.children[i];
        if(instance_exists(child) && child.object_index==obj_screw) {
            instance_destroy(child);
            array_delete(d.children,i,1);
        }
    }
    d.remaining=0;
    d.open_cover();
    return true;
}
function campaign_tick(_g,_seconds) {
    if(global.mode==GameMode.Pause || _g.earn_remaining<=0) return;
    if(!_g.table_plate) {_g.earn_remaining=0;return;}
    _g.earn_remaining=max(0,_g.earn_remaining-_seconds);
    if(_g.earn_remaining<=0) {_g.table_plate=false;campaign_credit(_g,20);}
}
function campaign_module_count(_device) {
    var n=0;
    // Count by owner, so held inventory items and removed children cannot duplicate.
    for(var i=0;i<instance_number(par_module);++i) {
        var item=instance_find(par_module,i);
        if(item.device==_device && item.inventory_origin<0 && !item.in_inventory) n++;
    }
    return n;
}
function campaign_finish(_g) {
    var d=_g.active_device;
    if(!instance_exists(d) || d.is_order || d.is_generator || d.is_recycler || d.is_assembler || !d.cover_open) return false;
    board_cancel(d);wire_cancel(d);
    if(campaign_module_count(d)>0 && !_g.finish_confirm) {_g.finish_confirm=true;return false;}
    for(var i=0;i<array_length(_g.table_devices);++i) if(_g.table_devices[i]==d) {array_delete(_g.table_devices,i,1);break;}
    _g.active_device=noone;instance_destroy(d);campaign_table(_g);
    return true;
}
// Loot alone never qualifies: the player must wire a working circuit.
function campaign_can_sell(_g,_d) {
    if(!instance_exists(_d)||_d.is_order||_d.is_generator||_d.is_recycler||_d.is_assembler||_d.completed||!_d.cover_open||!_d.user_wired||!_d.requirements_met) return false;
    if(instance_exists(_d.selected_module)||!is_undefined(_d.wire_start)) return false;
    for(var i=0;i<array_length(_g.table_devices);++i) if(_g.table_devices[i]==_d) return true;
    return false;
}
function campaign_sell(_g) {
    if(global.mode!=GameMode.Play) return false;
    var d=_g.active_device;if(!instance_exists(d)) return false;
    device_stats_update(d);
    if(!campaign_can_sell(_g,d)) return false;
    d.completed=true;campaign_credit(_g,max(0,d.repair_price));
    for(var i=0;i<array_length(_g.table_devices);++i) if(_g.table_devices[i]==d) {array_delete(_g.table_devices,i,1);break;}
    campaign_table(_g);instance_destroy(d);
    return true;
}
function campaign_loot(_device) {
    var g=instance_find(obj_game,0);if(!instance_exists(g)) return;
    var fixed_types=_device.campaign_loot_types;
    if(array_length(fixed_types)>0) {
        _device.requested_modules=array_length(fixed_types);_device.placed_modules=0;
        // First-fit keeps these small known sets complete on either donor board.
        for(var i=0;i<array_length(fixed_types);++i)
            campaign_place_loot(_device,fixed_types[i],false);
        campaign_adapter_bonus(_device);
        return;
    }
    _device.requested_modules=irandom_range(2,3);_device.placed_modules=0;
    // Read child object drop weights once when opening the device.
    // Temporary instances never enter the board or inventory.
    var types=[],weights=[],total=0;
    for(var i=0;i<array_length(g.module_types);++i) {
        var type=g.module_types[i];
        if(!object_exists(type)) continue;
        if(!object_is_ancestor(type,par_module)) continue;
        var probe=instance_create_depth(0,0,0,type);
        var weight=max(0,probe.drop_weight);
        if(g.order_index<probe.unlock_after_orders) weight=0;
        instance_destroy(probe);
        if(weight<=0) continue;
        array_push(types,type);array_push(weights,weight);total+=weight;
    }
    if(total<=0) return;
    repeat(_device.requested_modules) {
        var roll=random(total),index=array_length(types)-1;
        for(var i=0;i<array_length(types);++i) {
            roll-=weights[i];if(roll<0) {index=i;break;}
        }
        campaign_place_loot(_device,types[index],true);
    }
    campaign_adapter_bonus(_device);
}
function campaign_adapter_bonus(_device) {
    if(_device.is_order||_device.is_generator||_device.adapter_bonus_rolled) return false;
    _device.adapter_bonus_rolled=true;
    var g=instance_find(obj_game,0);
    if(!instance_exists(g)||g.order_index<3||random(1)>=0.33) return false;
    var types=[obj_module_adapter,obj_module_adapter_corner],chosen=irandom(1);
    // Ordinary loot keeps priority. Try the other shape if the chosen one cannot fit.
    if(!campaign_place_loot(_device,types[chosen],true,true)
        &&!campaign_place_loot(_device,types[1-chosen],true,true)) return false;
    _device.adapter_bonus_added=true;
    _device.requested_modules++;
    return true;
}
function campaign_place_loot(_device,_type,_random_position,_allow_rotation=false) {
    var item=instance_create_depth(0,0,_device.depth-10,_type);
    item.device=_device;
    repeat(_allow_rotation?4:1) {
        var positions=[];
        for(var row=0;row<_device.rows;++row) for(var col=0;col<_device.cols;++col)
            if(board_can_place(item,col,row)) array_push(positions,[col,row]);
        if(array_length(positions)>0) {
            var pos=positions[_random_position?irandom(array_length(positions)-1):0];
            board_place(item,pos[0],pos[1]);
            array_push(_device.children,item);_device.placed_modules++;
            return true;
        }
        if(_allow_rotation) {item.shape=orders_rotate(item.shape);item.rotation_steps=(item.rotation_steps+1) mod 4;}
    }
    // Missing bonus space never displaces ordinary loot or inflates its counters.
    instance_destroy(item);
    return false;
}
function device_stats_update(_d) {
    if(!instance_exists(_d)) return;
    if(variable_instance_exists(_d,"balance_probe") && _d.balance_probe) return;
    var model={base:_d.stats_base,min:_d.stats_min,max:_d.stats_max},keys=bal_keys();
    _d.current_stats={};_d.installed_count=0;_d.powered_count=0;
    for(var k=0;k<array_length(keys);++k) struct_set(_d.current_stats,keys[k],bal_stat(model.base,keys[k]));
    var connected=[];
    // Either board contact powers its attached branch before the circuit closes.
    // Seed both ends, counting modules shared by those branches only once.
    for(var p=0;p<array_length(_d.board_ports);++p) {
        var start=board_port_reference(_d,p),wi=wire_for_port(_d,start);
        if(wi<0) continue;
        var w=_d.wires[wi],other_port=port_equal(w.a,start)?w.b:w.a;
        if(!instance_exists(other_port.module)||other_port.module==_d) continue;
        var seen=false;for(var n=0;n<array_length(connected);++n) if(connected[n]==other_port.module) {seen=true;break;}
        if(!seen) array_push(connected,other_port.module);
    }
    for(var head=0;head<array_length(connected);++head) {
        var item=connected[head];
        for(var j=0;j<array_length(item.connections);++j) {
            var peer=item.connections[j].module;if(!instance_exists(peer)||peer==_d) continue;
            var seen=false;for(var n=0;n<array_length(connected);++n) if(connected[n]==peer) {seen=true;break;}
            if(!seen) array_push(connected,peer);
        }
    }
    for(var i=0;i<instance_number(par_module);++i) {
        var item=instance_find(par_module,i);
        if(item.removing || item.device!=_d || item.in_inventory || item.inventory_origin>=0) continue;
        _d.installed_count++;
        var powered=false;for(var j=0;j<array_length(connected);++j) if(connected[j]==item){powered=true;break;}
        item.circuit_powered=powered;
        if(powered) _d.powered_count++;
        for(var k=0;k<array_length(keys);++k) if(keys[k]=="weight"||powered)
            struct_set(_d.current_stats,keys[k],struct_get(_d.current_stats,keys[k])+bal_stat(item.stats,keys[k]));
    }
    _d.requirements_met=_d.circuit_connected;
    for(var k=0;k<array_length(keys);++k) {
        var key=keys[k],v=struct_get(_d.current_stats,key);
        if(struct_exists(model.min,key)&&v<struct_get(model.min,key)) _d.requirements_met=false;
        if(struct_exists(model.max,key)&&v>struct_get(model.max,key)) _d.requirements_met=false;
    }
}
function campaign_complete(_g) {
    var d=_g.active_device;
    if(!instance_exists(d)||d!=_g.order_device||!d.is_order||d.completed||instance_exists(d.selected_module)) return false;
    device_stats_update(d);if(!d.requirements_met) return false;
    wire_cancel(d);d.completed=true;d.cover_open=false;
    campaign_visible(d,false);d.visible=true;
    campaign_credit(_g,max(0,d.order_reward));
    campaign_advance_order(_g);
    return true;
}
function campaign_advance_order(_g,_open_next=false) {
    var d=_g.order_device;
    campaign_table(_g);
    _g.order_device=noone;
    instance_destroy(d); // Installed parts leave with the delivered order.
    _g.order_index++;
    _g.order_device=orders_create(_g);
    campaign_visible(_g.order_device,false); // Next order waits on the table.
    if(_g.order_index==3) notice_show("Tier 2 unlocked: speed and efficiency modules. Big orders pay 300 {coin}.");
    if(_open_next) campaign_open(_g,_g.order_device);
}
function campaign_debug_skip_order(_g) {
    if(!_g.debug_tools||global.mode!=GameMode.Play||!instance_exists(_g.active_device)) return false;
    if(_g.active_device!=_g.order_device||!_g.active_device.is_order||_g.active_device.completed) return false;
    campaign_advance_order(_g,true);
    return true;
}
function campaign_skip_rect(_g) {return [_g.sidebar_width+448,16,_g.sidebar_width+616,50];}
function campaign_hit(_x,_y,_r) {return _x>=_r[0]&&_x<_r[2]&&_y>=_r[1]&&_y<_r[3];}
function campaign_item_rect(_slot) {
    var size=campaign_table_item_size(),left=216+(_slot mod 3)*(size+16),top=128+(_slot div 3)*(size+8);
    return [left,top,left+size,top+size];
}
function campaign_table_click(_g,_x,_y) {
    if(global.mode!=GameMode.Menu) return false;
    if(robots_table_click(_g,_x,_y)) return true;
    if(_g.table_plate&&campaign_hit(_x,_y,campaign_plate_rect())) {sfx_action(campaign_solder_plate(_g));return true;}
    if(campaign_hit(_x,_y,generator_table_rect())) return sfx_action(campaign_open(_g,_g.generator));
    if(campaign_hit(_x,_y,campaign_order_rect())) return sfx_action(campaign_open(_g,_g.order_device));
    for(var i=0;i<6;++i) {
        var at=i;if(at>=array_length(_g.table_devices)) break;
        if(campaign_hit(_x,_y,campaign_item_rect(i))) return sfx_action(campaign_open(_g,_g.table_devices[at]));
    }
    return false;
}
function campaign_inventory_page(_g,_delta) {
    var last=0;
    for(var i=0;i<array_length(_g.inventory);++i) {
        var m=_g.inventory[i];if(instance_exists(m)&&variable_instance_exists(m,"storage_page")) last=max(last,m.storage_page);
    }
    _g.inventory_page=clamp(_g.inventory_page+_delta,0,last+1);
}
function campaign_gui_click(_g,_x,_y) {
    if(global.mode==GameMode.Menu) {
        if(generator_click(_g,_x,_y)) return true;
        if(campaign_hit(_x,_y,[24,20,240,58])) {sfx_action(campaign_buy(_g));return true;}
        if(campaign_hit(_x,_y,[255,20,475,58])) {sfx_action(campaign_earn(_g));return true;}
    }
    if(global.mode==GameMode.Play) {
        if(instance_exists(_g.active_device)&&_g.active_device.is_assembler) {
            if(campaign_hit(_x,_y,assembler_back_rect(_g))) {campaign_table(_g);return true;}
            return false;
        }
        if(instance_exists(_g.active_device)&&_g.active_device.is_order&&_g.debug_tools&&campaign_hit(_x,_y,campaign_skip_rect(_g))) {
            campaign_debug_skip_order(_g);return true;
        }
        if(campaign_hit(_x,_y,[_g.sidebar_width+448,16,_g.sidebar_width+616,50])) {sfx_action(campaign_sell(_g));return true;}
        if(campaign_hit(_x,_y,[_g.sidebar_width+16,16,_g.sidebar_width+152,50])) {campaign_table(_g);return true;}
        if(campaign_hit(_x,_y,[_g.sidebar_width+168,16,_g.sidebar_width+433,50])) {
            if(_g.active_device.is_generator) campaign_table(_g);
            else if(_g.active_device.is_recycler||_g.active_device.is_assembler) return false;
            else if(_g.active_device.is_order) sfx_action(campaign_complete(_g));
            else if(!_g.active_device.cover_open) campaign_debug_unscrew(_g);
            else campaign_finish(_g);
            return true;
        }
        if(campaign_hit(_x,_y,[16,_g.inventory_footer,64,_g.inventory_footer+30])) {campaign_inventory_page(_g,-1);return true;}
        if(campaign_hit(_x,_y,[_g.sidebar_width-74,_g.inventory_footer,_g.sidebar_width-26,_g.inventory_footer+30])) {campaign_inventory_page(_g,1);return true;}
    }
    return false;
}
function campaign_button(_r,_label,_enabled=true) {
    draw_set_color(_enabled?make_color_rgb(55,80,105):make_color_rgb(42,47,55));draw_rectangle(_r[0],_r[1],_r[2],_r[3],false);
    draw_set_color(_enabled?c_white:c_gray);ui_text(_r[0]+8,_r[1]+8,_label);
}
function campaign_sprite(_sprite,_r,_alpha=1,_offset_y=0,_frame=0) {
    var scale=min((_r[2]-_r[0])/sprite_get_width(_sprite),(_r[3]-_r[1])/sprite_get_height(_sprite));
    var px=(_r[0]+_r[2]-sprite_get_width(_sprite)*scale)/2+sprite_get_xoffset(_sprite)*scale;
    var py=(_r[1]+_r[3]-sprite_get_height(_sprite)*scale)/2+sprite_get_yoffset(_sprite)*scale;
    draw_sprite_ext(_sprite,_frame,px,py+_offset_y,scale,scale,0,c_white,_alpha);
}
function campaign_table_draw(_g) {
    if(_g.table_plate) {
        var r=campaign_plate_rect();campaign_sprite(spr_plate,r);
        if(_g.earn_remaining>0) {
            draw_set_color(make_color_rgb(40,54,65));draw_rectangle(r[0],r[3]-8,r[2],r[3]-2,false);
            draw_set_color(c_aqua);draw_rectangle(r[0],r[3]-8,r[0]+(r[2]-r[0])*(1-_g.earn_remaining/_g.earn_duration),r[3]-2,false);
            draw_set_color(c_white);
        }
    }
    if(instance_exists(_g.order_device)) campaign_sprite(_g.order_device.small_sprite,campaign_order_rect());
    for(var i=0;i<6;++i) {
        var at=i;if(at>=array_length(_g.table_devices)) break;
        var d=_g.table_devices[at];
        var eased=1-power(1-d.arrival_progress,3);
        campaign_sprite(d.object_index==obj_radio?spr_radio_small:spr_remote_small,campaign_item_rect(i),eased,-d.arrival_offset*(1-eased));
    }
    robots_table_draw(_g);
}
function campaign_gui_draw(_g) {
    draw_set_font(_g.ui_font);draw_set_alpha(1);draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(c_white);
    if(global.mode==GameMode.Menu) {
        campaign_button([24,20,240,58],"Buy device {coin} 25",_g.money>=25&&array_length(_g.table_devices)<6);
        campaign_button([255,20,475,58],"Get a plate",!_g.table_plate&&_g.earn_remaining<=0);
        draw_set_color(c_white);ui_text(500,28,"{coin} "+string(_g.money));
        ui_text(730,28,"{scrap} "+string(_g.scrap));
        var tier_label=instance_exists(_g.order_device)&&_g.order_device.order_tier==2?" / Tier 2":"";
        var order_rect=campaign_order_rect();
        draw_set_color(c_white);ui_text(order_rect[0],order_rect[3]+8,"Order "+string(_g.order_index+1)+tier_label);
    }
    if(global.mode==GameMode.Play && instance_exists(_g.active_device)) {
        var d=_g.active_device;
        if(d.is_assembler) {
            var l=assembler_layout(_g);
            campaign_button(assembler_back_rect(_g),"Table");
            campaign_sprite(spr_cog,[l.left+168,20,l.left+196,48]);
            draw_set_color(c_white);ui_text(l.left+208,24,string(_g.scrap));
            draw_set_font(game_font_default());return;
        }
        campaign_button([_g.sidebar_width+16,16,_g.sidebar_width+152,50],"Table");
        if(!d.is_generator&&!d.is_assembler)
            campaign_sprite(spr_RMB_Rotate,[_g.sidebar_width+16,58,_g.sidebar_width+80,90]);
        if(d.is_generator) campaign_button([_g.sidebar_width+168,16,_g.sidebar_width+433,50],"Finish setup");
        else if(d.is_recycler) {
            var robot=d.robot_owner;
            draw_set_color(c_white);
            ui_text(_g.sidebar_width+168,24,robot.powered?(robot.working?"Recycling...":"Auto recycling"):"Needs 2 energy");
        }
        else if(d.is_order) {
            campaign_button([_g.sidebar_width+168,16,_g.sidebar_width+433,50],d.completed?"All orders complete":"Deliver {coin} +"+string(d.order_reward),d.requirements_met&&!d.completed);
            if(_g.debug_tools) campaign_button(campaign_skip_rect(_g),"Skip (debug)",!d.completed);
        }
        else if(d.cover_open) campaign_button([_g.sidebar_width+168,16,_g.sidebar_width+433,50],_g.finish_confirm?"Discard parts?":"Finish dismantling");
        else if(_g.debug_tools) campaign_button([_g.sidebar_width+168,16,_g.sidebar_width+433,50],"Unscrew all (debug)");
        if(!d.is_order&&!d.is_generator&&!d.is_recycler&&!d.is_assembler&&d.cover_open) campaign_button([_g.sidebar_width+448,16,_g.sidebar_width+616,50],"Sell {coin} +"+string(d.repair_price),campaign_can_sell(_g,d));
        if(_g.finish_confirm) {draw_set_color(c_red);ui_text(_g.sidebar_width+16,98,"Parts inside will be lost. Click again to confirm.");}
        if(_g.stats_height>0) {
            var keys=game_stat_keys(),icons=game_stat_icons();
            var all_stats_valid=true;
            for(var k=0;k<array_length(keys);++k) {
                var key=keys[k];
                if(!struct_exists(d.stats_min,key)&&!struct_exists(d.stats_max,key)&&!(d.is_generator&&k<4)) continue;
                var lower=struct_exists(d.stats_min,key)?struct_get(d.stats_min,key):undefined;
                var upper=struct_exists(d.stats_max,key)?struct_get(d.stats_max,key):undefined;
                if(!stat_bar_model(struct_get(d.current_stats,key),lower,upper).valid) all_stats_valid=false;
            }
            // Opaque backing keeps the stat sprites readable over the table.
            draw_set_alpha(1);
            draw_set_color(all_stats_valid?make_color_rgb(20,43,34):make_color_rgb(20,27,38));
            draw_rectangle(8,8,_g.sidebar_width-8,_g.stats_height,false);
            draw_set_color(make_color_rgb(100,125,150));
            draw_rectangle(8,8,_g.sidebar_width-8,_g.stats_height,true);
            draw_set_color(c_white);
            var visible_row=0;
            for(var k=0;k<array_length(keys);++k) {
                var key=keys[k],goal={min:d.stats_min,max:d.stats_max};
                if(!struct_exists(goal.min,key)&&!struct_exists(goal.max,key)&&!(d.is_generator&&k<4)) continue;
                var lower=struct_exists(goal.min,key)?struct_get(goal.min,key):undefined;
                var upper=struct_exists(goal.max,key)?struct_get(goal.max,key):undefined;
                stat_bar_draw(16,16+visible_row*38,icons[k],struct_get(d.current_stats,key),lower,upper);
                visible_row++;
            }
        }
        campaign_button([16,_g.inventory_footer,64,_g.inventory_footer+30],"<");campaign_button([_g.sidebar_width-74,_g.inventory_footer,_g.sidebar_width-26,_g.inventory_footer+30],">");
        draw_set_color(c_white);ui_text(82,_g.inventory_footer+8,"Page "+string(_g.inventory_page+1));
        // Hover cards show property icons and exact signed numeric changes.
        var item=noone,anchor_x=0,anchor_y=0,slot=inventory_slot(_g,mouse_x,mouse_y);
        if(slot>=0 && slot<array_length(_g.inventory)) {
            item=_g.inventory[slot];
            if(instance_exists(item)) {
                anchor_x=_g.inventory_x+(item.storage_col+array_length(item.shape[0])/2)*_g.inventory_size;
                anchor_y=_g.inventory_y+item.storage_row*_g.inventory_size;
            }
        } else if(instance_exists(global.hover_target)&&variable_instance_exists(global.hover_target,"stats")) {
            item=global.hover_target;
            anchor_x=item.x+array_length(item.shape[0])*d.cell_size/2;anchor_y=item.y;
        }
        if(instance_exists(item)&&!instance_exists(d.selected_module)&&is_undefined(d.wire_start))
            module_stat_card(item,anchor_x,anchor_y);

    }
    draw_set_font(game_font_default());draw_set_color(c_white);
}

// Fixed requirement scale: one cell is always one unit, from 0 to 20.
// Validation still uses the actual value, even when it is outside this display.
function stat_bar_model(_value,_min,_max) {
    var valid=(is_undefined(_min)||_value>=_min)&&(is_undefined(_max)||_value<=_max);
    return {low:0,high:20,unit:1,count:20,valid:valid};
}
function stat_bar_goal(_min,_max) {
    if(is_undefined(_min)&&is_undefined(_max)) return "-";
    if(is_undefined(_min)) return "<= "+string(_max);
    if(is_undefined(_max)) return ">= "+string(_min);
    if(_min==_max) return "= "+string(_min);
    if(_min>_max) return "Invalid bounds";
    return string(_min)+".."+string(_max);
}
function stat_bar_draw(_x,_y,_icon,_value,_min,_max,_module_stat = false) {
    var m=stat_bar_model(_value,_min,_max);
    var filtering=gpu_get_texfilter();gpu_set_texfilter(false);
    game_stat_icon(_icon,_x,_y);
    // Show the actual value, including values outside the displayed 0..20 scale.
    var value_text=string(_value),text_scale=min(1,32/max(1,string_width(value_text)));
    var halign=draw_get_halign(),valign=draw_get_valign();
    draw_set_halign(fa_center);draw_set_valign(fa_middle);
    draw_set_color(m.valid?make_color_rgb(0,166,81):make_color_rgb(0,174,240));
    draw_text_transformed(_x+56,_y+16,value_text,text_scale,1,0);
    draw_set_halign(halign);draw_set_valign(valign);
    _x+=80;
    var bar_y=_y,cell_width=16;
    // Twenty 16x32 cells leave room for the icon and number in the same sidebar.
    // Lamps represent values 1..20: the minimum's lamp is included in green.
    var green_min=is_undefined(_min)?undefined:_min-1;
    var ordered=is_undefined(_min)||is_undefined(_max)||_min<=_max;
    // Split cells at fill and colour boundaries for fractional values.
    // The order's limits only choose colours; they never determine bar length.
    for(var i=0;i<20;++i) {
        var a=i,b=i+1,cuts=[a,b];
        var edges=[0,_value,green_min,_max];
        for(var j=0;j<4;++j) if(!is_undefined(edges[j])&&edges[j]>a&&edges[j]<b) array_push(cuts,edges[j]);
        array_sort(cuts,true);
        for(var j=0;j<array_length(cuts)-1;++j) {
            var from=cuts[j],to=cuts[j+1];if(to<=from) continue;
            var mid=(from+to)/2;
            var green=ordered&&(!is_undefined(_min)||!is_undefined(_max))&&(is_undefined(green_min)||mid>=green_min)&&(is_undefined(_max)||mid<=_max);
            var full=mid>=min(0,_value)&&mid<max(0,_value);
            var spr=green?(full?spr_stat_green_full:spr_stat_green_empty):(full?spr_stat_blue_full:spr_stat_blue_empty);
            var left=(from-a)/m.unit,span=(to-from)/m.unit;
            draw_sprite_part_ext(spr,0,left*sprite_get_width(spr),0,span*sprite_get_width(spr),sprite_get_height(spr),_x+i*cell_width+left*cell_width,bar_y,cell_width/sprite_get_width(spr),2,c_white,1);
        }
    }
    // Mark the numeric boundary of exact targets.
    if(!is_undefined(_min)&&!is_undefined(_max)&&_min==_max&&_min>=m.low&&_min<=m.high) {
        var goal_x=_x+(_min-m.low)/m.unit*cell_width;
        draw_set_color(m.valid?c_lime:c_orange);draw_line(goal_x,bar_y-2,goal_x,bar_y+32);
    }
    gpu_set_texfilter(filtering);
    draw_set_color(c_white);
}

function module_stat_card(_item,_anchor_x,_anchor_y) {
    var keys=game_stat_keys(),icons=game_stat_icons();
    var value_width=0,visible_count=0;
    for(var i=0;i<array_length(keys);++i) {
        var value=bal_stat(_item.stats,keys[i]);
        if(value==0) continue;
        visible_count++;
        value_width=max(value_width,string_width((value>0?"+":"")+string(value)));
    }
    if(visible_count==0) return;
    var width=max(96,64+value_width),height=16+visible_count*38;
    var px=clamp(_anchor_x-width/2,8,room_width-width-8);
    var py=clamp(_anchor_y-height-10,8,room_height-height-8);
    draw_set_alpha(1);draw_set_color(make_color_rgb(15,22,32));draw_rectangle(px,py,px+width,py+height,false);
    draw_set_color(make_color_rgb(130,155,180));draw_rectangle(px,py,px+width,py+height,true);
    var visible_row=0;
    for(var i=0;i<array_length(keys);++i) {
        var value=bal_stat(_item.stats,keys[i]);
        if(value==0) continue;
        module_stat_row(px+8,py+8+visible_row*38,icons[i],keys[i],value);
        visible_row++;
    }
    draw_set_color(c_white);
}

// Sign describes the change; colour describes whether that change is beneficial.
function module_stat_beneficial(_key,_value) {
    var higher_good=(_key=="energy"||_key=="stability"||_key=="speed"||_key=="efficiency");
    return _value!=0 && (higher_good ? _value>0 : _value<0);
}
function module_stat_row(_x,_y,_icon,_key,_value) {
    if(_value==0) return;
    var filtering=gpu_get_texfilter();gpu_set_texfilter(false);
    draw_set_color(c_white);
    game_stat_icon(_icon,_x,_y);
    var good=module_stat_beneficial(_key,_value);
    draw_set_color(good?c_lime:c_red);
    ui_text(_x+48,_y+8,(_value>0?"+":"")+string(_value));
    gpu_set_texfilter(filtering);draw_set_color(c_white);
}

// Reflow UI for the selected device; inventory contents keep their absolute indices.
function campaign_device_layout(_g,_device) {
    // Inventory and active board use the same pixel size per cell.
    _g.inventory_size=_device.cell_size;
    _g.inventory_cols=max(1,floor((_g.sidebar_width-32)/_g.inventory_size));
    var keys=game_stat_keys(),required=0;
    for(var i=0;i<array_length(keys);++i)
        if((_device.is_generator&&i<4)||struct_exists(_device.stats_min,keys[i])||struct_exists(_device.stats_max,keys[i])) required++;
    _g.stats_height=required>0?24+required*38:0;
    _g.inventory_y=_g.stats_height+16;
    _g.inventory_rows=max(1,floor((room_height-_g.inventory_y-56)/_g.inventory_size));
    _g.inventory_capacity=_g.inventory_cols*_g.inventory_rows;
    _g.inventory_footer=_g.inventory_y+_g.inventory_rows*_g.inventory_size+12;
    inventory_reflow(_g);
    var capacity=_g.inventory_capacity;
    var needed=max(capacity,ceil(array_length(_g.inventory)/capacity)*capacity);
    while(array_length(_g.inventory)<needed) array_push(_g.inventory,noone);
    campaign_inventory_page(_g,0);
}
