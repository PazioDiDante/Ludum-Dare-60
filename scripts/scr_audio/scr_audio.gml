// Music keeps its position when muted and is independent of gameplay sound effects.
function music_set_enabled(_g,_enabled) {
    _g.music_enabled=_enabled;
    if(_enabled) {
        if(_g.music_sound==-1) {
            _g.music_sound=audio_play_sound(snd_scrap_treasure,100,true);
            audio_sound_gain(_g.music_sound,0.5,0);
        } else if(audio_is_paused(_g.music_sound)) audio_resume_sound(_g.music_sound);
    } else if(_g.music_sound!=-1) audio_pause_sound(_g.music_sound);
}
function sfx_set_enabled(_g,_enabled) {
    _g.sfx_enabled=_enabled;
    if(_enabled) return;
    sfx_screw_stop(_g);
    sfx_solder_stop(_g);
    // Stop existing effects immediately; the music voice is deliberately separate.
    var effects=[snd_click,snd_coin,snd_device_ready,snd_generator_break,snd_imposible,
        snd_modul_take_place,snd_remove_cover,snd_robotDone,snd_solider,snd_vint];
    for(var i=0;i<array_length(effects);++i) audio_stop_sound(effects[i]);
}
function audio_control_rect(_music) {
    var left=_music?24:84;
    return [left,76,left+44,120];
}
function audio_controls_click(_g,_x,_y) {
    if(global.mode!=GameMode.Menu) return false;
    if(campaign_hit(_x,_y,audio_control_rect(true))) {
        music_set_enabled(_g,!_g.music_enabled);return true;
    }
    if(campaign_hit(_x,_y,audio_control_rect(false))) {
        sfx_set_enabled(_g,!_g.sfx_enabled);return true;
    }
    return false;
}
function audio_controls_draw(_g) {
    var mx=device_mouse_x_to_gui(0),my=device_mouse_y_to_gui(0);
    for(var i=0;i<2;++i) {
        var music=i==0,r=audio_control_rect(music),enabled=music?_g.music_enabled:_g.sfx_enabled;
        var hover=campaign_hit(mx,my,r),left=r[0],top=r[1];
        draw_set_color(hover?make_color_rgb(70,94,116):make_color_rgb(42,58,75));
        draw_rectangle(r[0],r[1],r[2],r[3],false);
        draw_set_color(enabled?make_color_rgb(178,226,231):make_color_rgb(120,132,145));
        // Integer rectangles keep the note and speaker crisp beside the pixel art.
        if(music) {
            draw_rectangle(left+17,top+11,left+20,top+29,false);
            draw_rectangle(left+29,top+9,left+32,top+26,false);
            draw_rectangle(left+17,top+9,left+32,top+13,false);
            draw_rectangle(left+11,top+27,left+20,top+33,false);
            draw_rectangle(left+23,top+24,left+32,top+30,false);
        } else {
            draw_rectangle(left+10,top+18,left+16,top+27,false);
            draw_rectangle(left+16,top+15,left+19,top+30,false);
            draw_rectangle(left+19,top+12,left+22,top+33,false);
            draw_rectangle(left+26,top+18,left+28,top+27,false);
            draw_rectangle(left+31,top+14,left+33,top+31,false);
        }
        if(!enabled) {
            draw_set_color(make_color_rgb(237,105,105));
            for(var step=0;step<26;++step) draw_rectangle(left+9+step,top+34-step,left+11+step,top+36-step,false);
        }
        if(hover) {
            var label=music?(enabled?"Mute music":"Unmute music"):(enabled?"Mute sounds":"Unmute sounds");
            var width=string_width(label)+16;
            draw_set_color(make_color_rgb(25,35,48));draw_rectangle(left,top+48,left+width,top+74,false);
            draw_set_color(c_white);draw_text(left+8,top+52,label);
        }
    }
    draw_set_color(c_white);
}

// Play only at interaction boundaries, never in layout/generation helpers.
function sfx_pitch(_g,_sound) {
    var spread=0;
    if(_sound==snd_click) spread=0.06;
    else if(_sound==snd_modul_take_place) spread=0.08;
    else if(_sound==snd_vint) spread=0.10;
    if(spread==0) return 1;
    // Cosmetic randomness must not change loot, orders or generator failures.
    _g.sfx_random_state=(_g.sfx_random_state*48271) mod 2147483647;
    return 1+spread*(2*_g.sfx_random_state/2147483647-1);
}
function sfx_play(_sound) {
    if(!instance_exists(obj_game)) return -1;
    var g=instance_find(obj_game,0);
    if(!g.sfx_enabled) return -1;
    // Concurrent rewards and compound interactions share one audible cue.
    if(audio_is_playing(_sound)) return -1;
    var voice=audio_play_sound(_sound,10,false);
    if(voice!=-1&&(_sound==snd_click||_sound==snd_modul_take_place||_sound==snd_vint))
        audio_sound_pitch(voice,sfx_pitch(g,_sound));
    return voice;
}
function sfx_ui(_handled,_sound=snd_click) {
    if(_handled&&!audio_is_playing(snd_imposible)) sfx_play(_sound);
    return _handled;
}
// Wrap explicit player attempts only; automatic retries remain silent.
function sfx_action(_success) {
    if(!_success) sfx_play(snd_imposible);
    return _success;
}
function sfx_screw_stop(_g) {
    if(_g.screw_sound!=-1&&(_g.screw_sound_paused||audio_is_playing(_g.screw_sound)))
        audio_stop_sound(_g.screw_sound);
    _g.screw_sound=-1;
    _g.screw_sound_paused=false;
    _g.screw_sound_wait=0;
}
function sfx_screw_update(_g,_seconds=global.dt) {
    // A short pulse may have ended since the preceding frame.
    if(_g.screw_sound!=-1&&!_g.screw_sound_paused&&!audio_is_playing(_g.screw_sound)) _g.screw_sound=-1;
    var screw=_g.active_screw;
    if(!_g.sfx_enabled||!instance_exists(screw)||!instance_exists(screw.device)
        ||_g.active_device!=screw.device||!screw.visible||!screw.unscrewing) {
        sfx_screw_stop(_g);return;
    }
    if(!game_running()||!window_has_focus()) {
        if(_g.screw_sound!=-1&&!_g.screw_sound_paused) {
            audio_pause_sound(_g.screw_sound);_g.screw_sound_paused=true;
        }
        return;
    }
    if(_g.screw_sound!=-1&&_g.screw_sound_paused) {
        audio_resume_sound(_g.screw_sound);_g.screw_sound_paused=false;
    }
    _g.screw_sound_wait=max(0,_g.screw_sound_wait-max(0,_seconds));
    if(_g.screw_sound_wait>0) return;
    // Short individual turns, separated by silence; never catch up in a burst.
    _g.screw_sound=sfx_play(snd_vint);
    _g.screw_sound_wait=_g.screw_sound_interval;
}
// Credit gameplay income and play its notification sound.
function campaign_credit(_g,_amount) {
    if(_amount<=0) return;
    _g.money+=_amount;
    sfx_play(snd_coin);
}
function sfx_solder_stop(_g) {
    if(_g.solder_sound!=-1) audio_stop_sound(_g.solder_sound);
    _g.solder_sound=-1;
}
function sfx_solder_update(_g) {
    var working=_g.table_plate&&_g.earn_remaining>0;
    for(var i=0;i<array_length(_g.robots)&&!working;++i) {
        var robot=_g.robots[i];
        if(instance_exists(robot)&&robot.product_id=="solder_robot")
            working=robot.working&&robot.powered&&robot.has_plate;
    }
    // One shared loop keeps a large fleet from multiplying the volume.
    if(!_g.sfx_enabled||!working) {sfx_solder_stop(_g);return;}
    if(global.mode==GameMode.Pause||!window_has_focus()) {
        if(_g.solder_sound!=-1&&!audio_is_paused(_g.solder_sound)) audio_pause_sound(_g.solder_sound);
        return;
    }
    if(_g.solder_sound==-1) _g.solder_sound=audio_play_sound(snd_solider,10,true);
    else if(audio_is_paused(_g.solder_sound)) audio_resume_sound(_g.solder_sound);
}
function sfx_ready_update(_g) {
    var d=_g.active_device;
    if(!instance_exists(d)) {_g.ready_sound_device=noone;_g.ready_sound_state=false;return;}
    if(_g.ready_sound_device!=d) {
        _g.ready_sound_device=d;_g.ready_sound_state=d.requirements_met;return;
    }
    var was_ready=_g.ready_sound_state;
    _g.ready_sound_state=d.requirements_met;
    if(!was_ready&&d.requirements_met&&d.visible&&d.cover_open&&!d.completed
        &&!d.is_generator&&!d.is_recycler&&!d.is_assembler&&(d.is_order||d.user_wired))
        sfx_play(snd_device_ready);
}
