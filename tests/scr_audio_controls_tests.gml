// Run only in an isolated copy; call audio_controls_tests each Begin Step.
function audio_control_assert(_ok,_label) {
    if(!_ok) throw "AUDIO_CONTROLS_FAILURE: "+_label;
    global.audio_control_passes++;
}
function audio_controls_capture(_g,_name) {
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    campaign_table_draw(_g);campaign_gui_draw(_g);generator_draw(_g);robots_draw(_g);
    surface_reset_target();surface_save(sf,environment_get_variable("AUDIO_CONTROLS_OUTPUT")+"/"+_name+".png");surface_free(sf);
}
function audio_controls_tests() {
    var g=instance_find(obj_game,0);
    if(++g.audio_control_ticks==5) {
        global.audio_control_passes=0;
        audio_control_assert(g.music_enabled&&g.sfx_enabled&&audio_is_playing(g.music_sound),"music starts automatically with sound effects enabled");
        audio_control_assert(abs(audio_sound_length(snd_scrap_treasure)-85.333333)<0.1,"full supplied track imported");
        var voice=g.music_sound,music=audio_control_rect(true),sounds=audio_control_rect(false),cash=g.money,donors=array_length(g.table_devices);
        audio_control_assert(music[0]==24&&music[1]>58&&music[2]<sounds[0]&&sounds[3]<128,"separate icons sit below Buy device");
        audio_controls_capture(g,"audio-on");
        audio_control_assert(campaign_gui_click(g,music[0]+22,music[1]+22),"table click reaches music control");
        audio_control_assert(!g.music_enabled&&audio_is_paused(voice)&&g.sfx_enabled,"music toggle pauses only music");
        audio_control_assert(sfx_play(snd_click)!=-1&&audio_is_playing(snd_click),"effects still work with music paused");
        campaign_gui_click(g,sounds[0]+22,sounds[1]+22);
        audio_control_assert(!g.sfx_enabled&&!audio_is_playing(snd_click)&&audio_is_paused(voice),"effects stop immediately without resuming music");
        audio_control_assert(sfx_play(snd_coin)==-1&&!audio_is_playing(snd_coin),"muted effects reject new playback");
        audio_controls_capture(g,"audio-muted");
        campaign_gui_click(g,music[0]+22,music[1]+22);
        audio_control_assert(g.music_enabled&&g.music_sound==voice&&audio_is_playing(voice)&&!audio_is_paused(voice)&&!g.sfx_enabled,"music resumes its existing voice independently");
        g.table_plate=true;g.earn_remaining=3;
        sfx_set_enabled(g,true);sfx_solder_update(g);
        audio_control_assert(g.solder_sound!=-1&&audio_is_playing(g.solder_sound),"enabled effects can start the shared soldering loop");
        campaign_gui_click(g,sounds[0]+22,sounds[1]+22);
        audio_control_assert(g.solder_sound==-1&&!audio_is_playing(snd_solider)&&audio_is_playing(voice),"muting stops running effect loops while music continues");
        g.table_plate=false;g.earn_remaining=0;
        campaign_gui_click(g,sounds[0]+22,sounds[1]+22);
        audio_control_assert(g.sfx_enabled&&sfx_play(snd_click)!=-1,"effects can be enabled again");
        audio_control_assert(g.money==cash&&array_length(g.table_devices)==donors,"audio buttons never buy devices or change money");
        campaign_open(g,g.order_device);
        audio_control_assert(audio_is_playing(voice)&&!audio_controls_click(g,46,98),"music continues on a device and table controls stay inactive there");
        global.mode=GameMode.Pause;
        audio_control_assert(audio_is_playing(voice)&&!audio_controls_click(g,106,98),"music continues through pause without exposing table controls");
        campaign_table(g);
        audio_sound_set_track_position(voice,audio_sound_length(snd_scrap_treasure)-0.15);
        g.audio_control_music_voice=voice;
    }
    if(g.audio_control_ticks==65) {
        var voice=g.audio_control_music_voice;
        audio_control_assert(audio_is_playing(voice)&&audio_sound_get_track_position(voice)<5,"track loops past its end without replacing the voice");
        audio_controls_capture(g,"audio-final");
        with(g) event_perform(ev_cleanup,0);
        audio_control_assert(!audio_is_playing(voice),"controller cleanup stops background music");
        show_debug_message("AUDIO_CONTROLS_RESULT passes="+string(global.audio_control_passes)+" failures=0");game_end();
    }
}
