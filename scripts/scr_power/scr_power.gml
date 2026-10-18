// Energy is continuous capacity, not a currency spent per click.
// Player allocations remain attached to their robot, including between jobs.
function power_update(_g) {
    var capacity=0,gen=_g.generator;
    if(instance_exists(gen) && gen.running && !gen.broken && gen.repair_remaining<=0) capacity=max(0,gen.current_stats.energy);
    _g.power_capacity=capacity;_g.power_demand=0;
    for(var i=0;i<array_length(_g.robots);++i) {
        var robot=_g.robots[i];if(!instance_exists(robot)) continue;
        if(robot.power_allocated) _g.power_demand+=robot.energy_cost;
    }
    // Never silently move an allocation to a different robot. Outages preserve
    // reservations; a smaller generator requires the player to release excess.
    var supplied=capacity>=_g.power_demand;
    _g.power_used=supplied?_g.power_demand:0;
    _g.power_free=max(0,capacity-_g.power_demand);
    for(var i=0;i<array_length(_g.robots);++i) {
        var robot=_g.robots[i];if(instance_exists(robot)) robot.powered=robot.power_allocated&&supplied;
    }
}
function robot_assign_power(_g,_robot) {
    if(global.mode!=GameMode.Menu||!instance_exists(_robot)) return false;
    power_update(_g);
    var gen=_g.generator;if(!instance_exists(gen)) return false;
    if(!gen.running||gen.broken||gen.repair_remaining>0) {
        generator_power_hint(gen,"start");return false;
    }
    if(_robot.power_allocated) return false;
    if(_g.power_free<_robot.energy_cost) {
        generator_power_hint(gen,"energy");return false;
    }
    generator_power_hint_clear(gen);
    _robot.power_allocated=true;power_update(_g);return true;
}
function robot_release_power(_g,_robot) {
    if(global.mode!=GameMode.Menu||!instance_exists(_robot)||!_robot.power_allocated) return false;
    _robot.power_allocated=false;generator_power_hint_clear(_g.generator);power_update(_g);return true;
}
// Brief visual feedback only: failed clicks never change generator or allocations.
function generator_power_hint(_gen,_kind) {
    _gen.power_hint=_kind;_gen.power_hint_remaining=1.44;_gen.power_hint_elapsed=0;
}
function generator_power_hint_clear(_gen) {
    if(!instance_exists(_gen)) return;
    _gen.power_hint="";_gen.power_hint_remaining=0;_gen.power_hint_elapsed=0;
}
function generator_power_hint_flash(_gen) {
    return _gen.power_hint_remaining>0&&(floor(_gen.power_hint_elapsed/0.18) mod 2)==0;
}
function generator_stop(_g,_reason) {
    if(!instance_exists(_g.generator)) return;
    generator_power_hint_clear(_g.generator);
    _g.generator.running=false;_g.generator.shutdown_reason=_reason;
    power_update(_g);
}
function generator_restart(_g) {
    if(global.mode!=GameMode.Menu || !instance_exists(_g.generator)) return false;
    var gen=_g.generator;device_stats_update(gen);
    if(gen.broken || gen.repair_remaining>0) return false;
    if(gen.current_stats.stability<gen.stats_min.stability) {
        generator_stop(_g,"Not enough stability");return false;
    }
    if(gen.running) return false;
    gen.running=true;gen.shutdown_reason="";generator_power_hint_clear(gen);
    gen.failure_remaining=-ln(max(0.000001,random(1)));
    power_update(_g);return true;
}
function generator_tick(_g,_seconds) {
    if(global.mode==GameMode.Pause || !instance_exists(_g.generator)) return;
    var gen=_g.generator;
    if(gen.power_hint_remaining>0) {
        var seconds=max(0,_seconds);
        gen.power_hint_elapsed+=seconds;
        gen.power_hint_remaining=max(0,gen.power_hint_remaining-seconds);
        if(gen.power_hint_remaining<=0) generator_power_hint_clear(gen);
    }
    if(gen.repair_remaining>0) {
        gen.repair_remaining=max(0,gen.repair_remaining-_seconds);
        if(gen.repair_remaining<=0) {
            gen.broken=false;gen.burning=false;gen.running=false;
            gen.shutdown_reason="Repaired. Restart required";
        }
        power_update(_g);return;
    }
    if(gen.running) {
        if(gen.current_stats.stability<gen.stats_min.stability) generator_stop(_g,"Not enough stability");
        else {
            // Integrated exponential hazard: independent of frame rate.
            gen.failure_remaining-=max(0,gen.current_stats.heat)*gen.heat_failure_rate*_seconds;
            if(gen.failure_remaining<=0) generator_break(_g);
        }
    }
    power_update(_g);
}
function generator_break(_g) {
    var gen=_g.generator;if(!instance_exists(gen)) return;
    if(gen.broken) return;
    gen.broken=true;gen.burning=true;gen.repair_remaining=0;
    generator_stop(_g,"Generator fire");
    sfx_play(snd_generator_break);
}
function generator_begin_repair(_g) {
    if(global.mode!=GameMode.Menu || !instance_exists(_g.generator)) return false;
    var gen=_g.generator;
    if(!gen.broken || gen.repair_remaining>0) return false;
    gen.running=false;gen.repair_remaining=gen.repair_seconds;generator_power_hint_clear(gen);
    power_update(_g);return true;
}
function generator_max_energy(_g) {
    return instance_exists(_g.generator)?max(0,_g.generator.current_stats.energy):0;
}
function generator_layout(_g) {
    var top=display_get_gui_height()-56,count=ceil(generator_max_energy(_g));
    var gen=_g.generator,heat_count=max(1,ceil(max(0,gen.current_stats.heat)));
    var warning=gen.burning||generator_unstable(gen);
    // Only actual heat cells and visible warning icons occupy horizontal space.
    var cell_width=min(18,max(1,display_get_gui_width()-260-(warning?40:0))/max(1,count+heat_count));
    var heat_x=56+count*cell_width,heat_bar_x=heat_x+36;
    var risk_x=heat_bar_x+heat_count*cell_width+8,modify_x=risk_x+64,control_x=modify_x+40;
    return {
        count:count,cell_width:cell_width,energy_x:56,top:top,
        heat_count:heat_count,heat_x:heat_x,heat_bar_x:heat_bar_x,risk_x:risk_x,
        energy_icon:[16,top+8,48,top+40],
        open:[modify_x,top+4,modify_x+40,top+44],
        control:[control_x,top+4,control_x+40,top+44],
        fire:[control_x+40,top+4,control_x+80,top+44],
        panel:[8,top,control_x+48+(warning?40:0),top+48]
    };
}
function generator_table_rect() {
    return generator_layout(instance_find(obj_game,0)).open;
}
function generator_restart_rect() {
    return generator_layout(instance_find(obj_game,0)).control;
}
function generator_energy_rect() {
    return generator_layout(instance_find(obj_game,0)).panel;
}
function generator_state_sprite(_gen) {
    if(!_gen.running&&_gen.power_hint=="start"&&_gen.power_hint_remaining>0)
        return generator_power_hint_flash(_gen)?spr_broke:spr_OFF;
    return (_gen.broken||generator_unstable(_gen))?spr_broke:(_gen.running?spr_ON:spr_OFF);
}
function generator_unstable(_gen) {
    return _gen.current_stats.stability<_gen.stats_min.stability;
}
function generator_click(_g,_px,_py) {
    if(global.mode!=GameMode.Menu || !instance_exists(_g.generator)) return false;
    var gen=_g.generator,layout=generator_layout(_g);
    if(!campaign_hit(_px,_py,layout.panel)) return false;
    // Any part of the broken generator strip starts the same repair job.
    if(gen.broken) {sfx_action(generator_begin_repair(_g));return true;}
    if(campaign_hit(_px,_py,layout.open)) {sfx_action(campaign_open(_g,gen));return true;}
    if(campaign_hit(_px,_py,layout.control)) {
        if(gen.running) generator_stop(_g,"Turned off manually");
        else sfx_action(generator_restart(_g));
    }
    return true;
}
function generator_energy_draw(_g) {
    var gen=_g.generator,layout=generator_layout(_g),r=layout.panel;
    draw_set_alpha(1);draw_set_color(make_color_rgb(20,27,38));draw_rectangle(r[0],r[1],r[2],r[3],false);
    draw_set_color(make_color_rgb(65,85,105));draw_rectangle(r[0],r[1],r[2],r[3],true);
    var energy_alpha=gen.power_hint=="energy"&&generator_power_hint_flash(gen)?0.2:1;
    campaign_sprite(spr_stat_energy,layout.energy_icon,energy_alpha);
    var filtering=gpu_get_texfilter();gpu_set_texfilter(false);
    for(var cell=0;cell<layout.count;++cell) {
        var filled=clamp(_g.power_free-cell,0,1),px=layout.energy_x+cell*layout.cell_width,py=layout.top+8;
        draw_sprite_part_ext(spr_stat_blue_empty,0,0,0,10,16,px,py,layout.cell_width/10,2,c_white,energy_alpha);
        if(filled>0) draw_sprite_part_ext(spr_stat_blue_full,0,0,0,10*filled,16,px,py,layout.cell_width/10,2,c_white,energy_alpha);
    }
    campaign_sprite(spr_stat_heat,[layout.heat_x,layout.top+8,layout.heat_x+32,layout.top+40]);
    for(var cell=0;cell<layout.heat_count;++cell) {
        var filled=clamp(gen.current_stats.heat-cell,0,1),px=layout.heat_bar_x+cell*layout.cell_width,py=layout.top+8;
        draw_sprite_part_ext(spr_stat_blue_empty,0,0,0,10,16,px,py,layout.cell_width/10,2,c_white,1);
        if(filled>0) draw_sprite_part_ext(spr_stat_red_full,0,0,0,10*filled,16,px,py,layout.cell_width/10,2,c_white,1);
    }
    draw_set_color(c_white);draw_set_font(_g.ui_font);
    var risk=100*(1-exp(-max(0,gen.current_stats.heat)*gen.heat_failure_rate));
    draw_text(layout.risk_x,layout.top+16,string_format(risk,0,1)+"%");
    var modify=layout.open;
    campaign_sprite(spr_modifyGenerator,[modify[0]+4,modify[1]+4,modify[2]-4,modify[3]-4]);
    var button=layout.control;
    campaign_sprite(generator_state_sprite(gen),[button[0]+4,button[1]+4,button[2]-4,button[3]-4]);
    if(gen.burning) {
        var fire=layout.fire;
        campaign_sprite(spr_fire,[fire[0]+4,fire[1]+4,fire[2]-4,fire[3]-4]);
    }
    else if(generator_unstable(gen)) {
        var warning=layout.fire;
        campaign_sprite(spr_unstable,[warning[0]+4,warning[1]+4,warning[2]-4,warning[3]-4]);
    }
    // Same fill style as the five-second earn action.
    if(gen.repair_remaining>0) {
        draw_set_color(c_dkgray);draw_rectangle(r[0]+2,r[3]-6,r[2]-2,r[3]-2,false);
        draw_set_color(c_lime);draw_rectangle(r[0]+2,r[3]-6,r[0]+2+(r[2]-r[0]-4)*(1-gen.repair_remaining/gen.repair_seconds),r[3]-2,false);
    }
    gpu_set_texfilter(filtering);draw_set_color(c_white);draw_set_font(game_font_default());
}
function generator_draw(_g) {
    if(global.mode!=GameMode.Menu || !instance_exists(_g.generator)) return;
    generator_energy_draw(_g);
}
