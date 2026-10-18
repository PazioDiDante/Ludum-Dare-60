function audio_test_assert(_ok,_message) {
    if(!_ok) throw "AUDIO_FAILURE: "+_message;
    global.audio_test_passes++;
}
function audio_test_part(_d,_energy) {
    var part=instance_create_depth(0,0,0,par_module);
    part.device=_d;part.shape=[["L_1","R_1"]];part.stats.energy=_energy;part.stats.weight=1;
    array_push(_d.children,part);
    var placed=false;
    for(var row=0;row<_d.rows&&!placed;++row) for(var col=0;col<_d.cols&&!placed;++col)
        if(board_place(part,col,row)) placed=true;
    audio_test_assert(placed,"fixture fits actual board");return part;
}
function audio_tests() {
    global.audio_test_passes=0;var g=instance_find(obj_game,0);
    audio_variation_tests(g);
    audio_stop_all();
    var sounds=[snd_click,snd_coin,snd_vint,snd_modul_take_place,snd_remove_cover];
    for(var i=0;i<array_length(sounds);++i) {
        audio_test_assert(audio_exists(sounds[i]),"imported sound exists");
        audio_test_assert(audio_sound_length(sounds[i])>0,"imported WAV has playable duration");
    }
    audio_test_assert(!sfx_ui(false)&&!audio_is_playing(snd_click),"unhandled UI remains silent");
    audio_test_assert(sfx_ui(true)&&audio_is_playing(snd_click),"handled UI plays click");
    audio_stop_all();g.sfx_enabled=false;sfx_ui(true);
    audio_test_assert(!audio_is_playing(snd_click),"disabled audio stays silent");g.sfx_enabled=true;
    campaign_table(g);g.money=0;g.table_plate=false;g.earn_remaining=0;
    campaign_earn(g);campaign_solder_plate(g);
    audio_test_assert(!audio_is_playing(snd_coin),"starting plate does not pay or play coin");
    campaign_tick(g,4);audio_test_assert(g.money==0&&!audio_is_playing(snd_coin),"unfinished plate remains silent");
    campaign_tick(g,1);audio_test_assert(g.money==20&&audio_is_playing(snd_coin),"manual payout plays coin");
    audio_stop_all();campaign_tick(g,10);
    audio_test_assert(g.money==20&&!audio_is_playing(snd_coin),"completed plate cannot pay twice");
    var robot=instance_create_depth(0,0,0,obj_robot,{product_id:"solder_robot",reward:10});
    robot.has_plate=true;robot.working=true;robot_finish(g,robot);
    audio_test_assert(g.money==30&&audio_is_playing(snd_coin),"solder robot payout plays coin");
    audio_stop_all();robot_finish(g,robot);
    audio_test_assert(g.money==30&&!audio_is_playing(snd_coin),"finished robot cannot pay twice");instance_destroy(robot);
    campaign_credit(g,0);campaign_credit(g,-1);
    audio_test_assert(g.money==30&&!audio_is_playing(snd_coin),"nonpositive credit has no sound or cash change");
    var d=g.table_devices[0];campaign_open(g,d);
    var screws=[];
    for(var i=0;i<array_length(d.children);++i) {
        var child=d.children[i];if(instance_exists(child)&&child.object_index==obj_screw) array_push(screws,child);
    }
    audio_test_assert(screw_start(screws[0]),"manual screw starts");sfx_screw_update(g);
    var handle=g.screw_sound;
    audio_test_assert(handle!=-1&&audio_is_playing(handle),"screw starts an audio instance");sfx_screw_update(g);
    audio_test_assert(g.screw_sound==handle,"screw update does not duplicate pulse");
    sfx_screw_update(g,0.31);var remaining=g.screw_sound_wait;
    audio_test_assert(g.screw_sound==handle&&remaining>0,"no repeat before screwdriver interval");
    global.mode=GameMode.Pause;sfx_screw_update(g,10);
    audio_test_assert(audio_is_paused(handle),"pause suspends screw audio");
    audio_test_assert(g.screw_sound_wait==remaining,"pause freezes screwdriver interval");
    global.mode=GameMode.Play;sfx_screw_update(g,0);
    audio_test_assert(g.screw_sound==handle&&!audio_is_paused(handle),"resume reuses same audio instance");
    audio_stop_sound(handle);sfx_screw_update(g,remaining-0.01);
    audio_test_assert(g.screw_sound==-1&&!audio_is_playing(handle),"silence remains between screwdriver turns");
    sfx_screw_update(g,0.02);
    audio_test_assert(g.screw_sound!=handle&&audio_is_playing(g.screw_sound),"next screwdriver pulse starts at interval");
    handle=g.screw_sound;
    audio_test_assert(audio_sound_get_pitch(handle)>=0.90&&audio_sound_get_pitch(handle)<=1.10,"screwdriver pulse uses randomized pitch");
    screw_cancel(g);audio_test_assert(g.screw_sound==-1&&!audio_is_playing(handle),"cancel stops screw audio");
    screw_start(screws[0]);sfx_screw_update(g);handle=g.screw_sound;screw_tick(g,10);
    audio_test_assert(g.screw_sound==-1&&!audio_is_playing(handle),"completion stops screw audio");
    audio_test_assert(d.remaining>0&&audio_is_playing(snd_remove_cover),"nonfinal screw completion plays opening sound while cover remains attached");
    for(var i=1;i<array_length(screws);++i) {
        audio_stop_all();screw_start(screws[i]);screw_tick(g,10);
        audio_test_assert(audio_is_playing(snd_remove_cover),"every manual screw completion plays opening sound");
    }
    audio_test_assert(d.cover_open&&audio_is_playing(snd_remove_cover),"last screw plays cover sound");
    audio_stop_all();d.open_cover();
    audio_test_assert(!audio_is_playing(snd_remove_cover),"already open cover stays silent");
    // Remove generated contents. Direct generation/cleanup must not play interaction sounds.
    for(var i=array_length(d.children)-1;i>=0;--i) {
        var child=d.children[i];
        if(instance_exists(child)&&object_is_ancestor(child.object_index,par_module)) {module_detach(child);instance_destroy(child);}
    }
    audio_test_assert(!audio_is_playing(snd_modul_take_place),"automatic disconnect/cleanup stays silent");
    var part=audio_test_part(d,4);
    audio_test_assert(!audio_is_playing(snd_modul_take_place),"programmatic placement stays silent");
    audio_test_assert(board_pick(part,part.x+1,part.y+1)&&audio_is_playing(snd_modul_take_place),"module pickup plays detail sound");
    audio_stop_all();part.preview_col=-100;
    audio_test_assert(!board_drop(d)&&!audio_is_playing(snd_modul_take_place),"rejected placement stays silent");
    board_cancel(d);board_pick(part,part.x+1,part.y+1);audio_stop_all();
    audio_test_assert(board_drop(d)&&audio_is_playing(snd_modul_take_place),"valid placement plays detail sound");
    board_pick(part,part.x+1,part.y+1);audio_stop_all();board_rotate(d);
    audio_test_assert(audio_is_playing(snd_modul_take_place),"rotation uses detail sound");board_cancel(d);
    board_pick(part,part.x+1,part.y+1);audio_stop_all();
    audio_test_assert(storage_drop(g,g.inventory_x+1,g.inventory_y+1)&&audio_is_playing(snd_modul_take_place),"inventory drop plays detail sound");
    audio_stop_all();var slot=inventory_slot(g,g.inventory_x+1,g.inventory_y+1);
    audio_test_assert(inventory_pick(g,slot,g.inventory_x+1,g.inventory_y+1)&&audio_is_playing(snd_modul_take_place),"inventory pickup plays detail sound");
    var placed=false;
    for(var row=0;row<d.rows&&!placed;++row) for(var col=0;col<d.cols&&!placed;++col)
        if(board_can_place(part,col,row)) {part.preview_col=col;part.preview_row=row;placed=board_drop(d);}
    var a=board_port_reference(d,0),b=port_reference(part,0,0),c=port_reference(part,1,0),e=board_port_reference(d,1);
    audio_stop_all();wire_connect(d,a,b);wire_connect(d,c,e);
    audio_test_assert(!audio_is_playing(snd_modul_take_place),"generated/direct wiring stays silent");
    wire_click(d,a);audio_test_assert(audio_is_playing(snd_modul_take_place),"manual unplug shares detail sound");
    audio_stop_all();wire_click(d,b);
    audio_test_assert(audio_is_playing(snd_modul_take_place),"manual connection shares detail sound");
    d.stats_min={energy:4};d.stats_max={energy:6,weight:2};device_stats_update(d);
    audio_stop_all();var cash=g.money,price=d.repair_price;
    audio_test_assert(campaign_sell(g)&&g.money==cash+price&&audio_is_playing(snd_coin),"repaired device sale plays coin");
    audio_stop_all();audio_test_assert(!campaign_sell(g)&&!audio_is_playing(snd_coin),"failed sale stays silent");
    var order=g.order_device;campaign_open(g,order);var order_part=audio_test_part(order,6);
    wire_connect(order,board_port_reference(order,0),port_reference(order_part,0,0));
    wire_connect(order,port_reference(order_part,1,0),board_port_reference(order,1));
    audio_stop_all();cash=g.money;var reward=order.order_reward;
    audio_test_assert(campaign_complete(g)&&g.money==cash+reward&&audio_is_playing(snd_coin),"order delivery plays coin");
    audio_stop_all();audio_test_assert(!campaign_complete(g)&&!audio_is_playing(snd_coin),"failed delivery stays silent");
    var hidden=campaign_create_device(obj_remote);hidden.visible=false;hidden.open_cover();
    audio_test_assert(!audio_is_playing(snd_remove_cover)&&!audio_is_playing(snd_modul_take_place),"robot-style hidden opening stays silent");instance_destroy(hidden);
    audio_more_tests(g);
    show_debug_message("AUDIO_RESULT passes="+string(global.audio_test_passes)+" failures=0");game_end();
}
function audio_variation_tests(_g) {
    var sounds=[snd_click,snd_modul_take_place,snd_vint],spreads=[0.06,0.08,0.10];
    for(var i=0;i<array_length(sounds);++i) {
        var low=2,high=0;
        repeat(12) {
            audio_stop_sound(sounds[i]);var voice=sfx_play(sounds[i]),pitch=audio_sound_get_pitch(voice);
            audio_test_assert(pitch>=1-spreads[i]-0.00001&&pitch<=1+spreads[i]+0.00001,"pitch stays in configured subtle range");
            low=min(low,pitch);high=max(high,pitch);
        }
        audio_test_assert(high-low>0.01,"successive sounds have varied pitch");
    }
    audio_stop_all();var voice=sfx_play(snd_coin);
    audio_test_assert(abs(audio_sound_get_pitch(voice)-audio_sound_get_pitch(snd_coin))<0.001,"other sounds retain original pitch");
    random_set_seed(981);var expected=random(1);random_set_seed(981);
    sfx_play(snd_click);audio_test_assert(random(1)==expected,"audio pitch does not consume gameplay RNG");
    audio_stop_all();var before=_g.sfx_random_state;_g.sfx_enabled=false;sfx_play(snd_click);
    audio_test_assert(_g.sfx_random_state==before,"muted cues do not advance audio variation");_g.sfx_enabled=true;
    audio_stop_all();
}
function audio_more_tests(_g) {
    audio_stop_all();
    var sounds=[snd_generator_break,snd_solider,snd_imposible,snd_device_ready,snd_robotDone];
    for(var i=0;i<array_length(sounds);++i) {
        audio_test_assert(audio_exists(sounds[i]),"new sound exists");
        audio_test_assert(audio_sound_length(sounds[i])>0,"new WAV has playable duration");
    }
    campaign_table(_g);var gen=_g.generator;gen.broken=false;gen.running=true;
    generator_break(_g);
    audio_test_assert(gen.broken&&!gen.running&&audio_is_playing(snd_generator_break),"generator failure plays alarm and stops power");
    audio_stop_all();generator_break(_g);
    audio_test_assert(!audio_is_playing(snd_generator_break),"already broken generator cannot repeat alarm");
    generator_begin_repair(_g);generator_tick(_g,100);
    audio_test_assert(!gen.broken&&!audio_is_playing(snd_generator_break),"repair does not play break alarm");
    _g.table_plate=false;_g.earn_remaining=0;campaign_earn(_g);campaign_solder_plate(_g);sfx_solder_update(_g);
    var handle=_g.solder_sound;
    audio_test_assert(handle!=-1&&audio_is_playing(handle),"manual soldering starts loop");
    sfx_solder_update(_g);audio_test_assert(_g.solder_sound==handle,"solder update retains single loop");
    global.mode=GameMode.Pause;sfx_solder_update(_g);
    audio_test_assert(audio_is_paused(handle),"pause suspends soldering sound");
    global.mode=GameMode.Menu;sfx_solder_update(_g);
    audio_test_assert(_g.solder_sound==handle&&!audio_is_paused(handle),"resume reuses soldering instance");
    _g.sfx_enabled=false;sfx_solder_update(_g);
    audio_test_assert(_g.solder_sound==-1&&!audio_is_playing(handle),"disable stops solder loop");_g.sfx_enabled=true;
    sfx_solder_update(_g);handle=_g.solder_sound;campaign_tick(_g,100);sfx_solder_update(_g);
    audio_test_assert(_g.solder_sound==-1&&!audio_is_playing(handle),"manual payout stops solder loop");
    var robot=instance_create_depth(0,0,0,obj_robot,{product_id:"solder_robot",reward:10,energy_cost:2});
    var second=instance_create_depth(0,0,0,obj_robot,{product_id:"solder_robot",reward:10,energy_cost:2});
    array_push(_g.robots,robot);array_push(_g.robots,second);
    robot.working=true;robot.has_plate=true;robot.powered=true;
    second.working=true;second.has_plate=true;second.powered=true;
    sfx_solder_update(_g);handle=_g.solder_sound;
    audio_test_assert(handle!=-1&&audio_is_playing(handle),"powered solder robots start shared loop");
    robot.powered=false;sfx_solder_update(_g);
    audio_test_assert(_g.solder_sound==handle,"one remaining powered robot retains same loop");
    second.powered=false;sfx_solder_update(_g);
    audio_test_assert(_g.solder_sound==-1&&!audio_is_playing(handle),"power outage silences soldering");
    robot.powered=true;sfx_solder_update(_g);
    audio_test_assert(_g.solder_sound!=-1,"power restoration resumes solder sound");
    sfx_solder_stop(_g);audio_stop_all();robot_finish(_g,robot);
    audio_test_assert(audio_is_playing(snd_robotDone)&&audio_is_playing(snd_coin),"solder completion plays done and preserves coin");
    audio_stop_all();robot_finish(_g,robot);
    audio_test_assert(!audio_is_playing(snd_robotDone),"finished robot cannot repeat done");
    second.working=false;second.has_plate=false;
    robot.product_id="recycle_robot";robot.working=true;robot.recycle_value=1;
    robot.target_module=instance_create_depth(0,0,0,obj_module_battery);robot_finish(_g,robot);
    audio_test_assert(audio_is_playing(snd_robotDone),"recycler completion plays done");
    audio_stop_all();robot.product_id="assembler_robot";robot.working=true;
    var assembled=instance_create_depth(0,0,0,obj_module_battery);robot.target_module=assembled;robot_finish(_g,robot);
    audio_test_assert(assembled.in_inventory&&audio_is_playing(snd_robotDone),"assembler output plays done");
    audio_stop_all();robot.product_id="dismantle_robot";robot.working=true;
    var donor=campaign_create_device(obj_remote);campaign_visible(donor,false);robot.target_device=donor;robot_finish(_g,robot);
    audio_test_assert(!instance_exists(donor)&&audio_is_playing(snd_robotDone),"dismantler completion plays done");
    audio_test_assert(!audio_is_playing(snd_remove_cover)&&!audio_is_playing(snd_device_ready),"hidden dismantling has no cover or ready cue");
    array_delete(_g.robots,array_length(_g.robots)-2,2);instance_destroy(robot);instance_destroy(second);
    audio_stop_all();robot_start(_g,_g.recycler_robot);robots_tick(_g,0);
    audio_test_assert(!audio_is_playing(snd_imposible),"automatic unpowered recycler retries stay silent");
    // Use an actual order board, with a deterministic single-module requirement.
    var order=_g.order_device;order.stats_min={energy:4};order.stats_max={energy:6};
    campaign_open(_g,order);sfx_ready_update(_g);
    var part=audio_test_part(order,4),a=board_port_reference(order,0),b=port_reference(part,0,0);
    var c=port_reference(part,1,0),e=board_port_reference(order,1);
    wire_connect(order,a,b);sfx_ready_update(_g);
    audio_test_assert(!audio_is_playing(snd_device_ready),"powered branch without circuit is not ready");
    wire_connect(order,c,e);sfx_ready_update(_g);
    audio_test_assert(order.requirements_met&&audio_is_playing(snd_device_ready),"complete circuit and valid stats play ready");
    audio_stop_all();device_stats_update(order);sfx_ready_update(_g);sfx_ready_update(_g);
    audio_test_assert(!audio_is_playing(snd_device_ready),"steady valid state never repeats cue");
    campaign_table(_g);campaign_open(_g,order);sfx_ready_update(_g);
    audio_test_assert(!audio_is_playing(snd_device_ready),"reopening ready order stays silent");
    wire_disconnect(order,wire_for_port(order,a));sfx_ready_update(_g);
    wire_connect(order,a,b);sfx_ready_update(_g);
    audio_test_assert(audio_is_playing(snd_device_ready),"restoring circuit can play ready again");
    audio_stop_all();part.stats.energy=3;device_stats_update(order);sfx_ready_update(_g);
    audio_test_assert(!order.requirements_met&&!audio_is_playing(snd_device_ready),"closed circuit with invalid stats stays silent");
    part.stats.energy=4;device_stats_update(order);sfx_ready_update(_g);
    audio_test_assert(audio_is_playing(snd_device_ready),"meeting stats after correction plays ready");
    audio_stop_all();wire_click(order,a);sfx_ready_update(_g);
    var incompatible=audio_test_part(order,0);incompatible.shape=[["L_2","R_2"]];
    var bad=port_current(port_reference(incompatible,0,0));
    wire_input(order,bad.x,bad.y,true,false);
    audio_test_assert(audio_is_playing(snd_imposible)&&!is_undefined(order.wire_start),"incompatible port click plays rejection and preserves draft");
    audio_stop_all();wire_input(order,bad.x,bad.y,false,false);
    audio_test_assert(!audio_is_playing(snd_imposible),"hover over invalid port stays silent");wire_cancel(order);
    campaign_table(_g);_g.money=0;
    audio_test_assert(campaign_gui_click(_g,30,30)&&audio_is_playing(snd_imposible),"purchase click without money plays rejection");
    audio_stop_all();campaign_buy(_g);
    audio_test_assert(!audio_is_playing(snd_imposible),"direct automatic/model failure stays silent");
    var shop=_g.shop;shop.open=true;var button=shop_row_button(0,shop.scroll);
    shop_click(shop,(button[0]+button[2])/2,(button[1]+button[3])/2);
    audio_test_assert(audio_is_playing(snd_imposible)&&!audio_is_playing(snd_click),"failed shop purchase uses rejection instead of click");
    audio_stop_all();_g.sfx_enabled=false;sfx_action(false);
    audio_test_assert(!audio_is_playing(snd_imposible),"mute also disables rejection sounds");_g.sfx_enabled=true;
    sfx_solder_stop(_g);audio_stop_all();
}
