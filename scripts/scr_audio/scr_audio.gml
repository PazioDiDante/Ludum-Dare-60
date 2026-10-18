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
// Only actual gameplay income belongs here; lab simulations stay silent.
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
