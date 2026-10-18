// Standalone suite; attach only to an isolated project copy.
function order_test_assert(_ok,_message) {
    if(!_ok) throw "ORDER_TEST_FAILURE: "+_message;
    global.order_test_passes++;
}
function order_test_ready(_g) {
    var started=get_timer(),ticks=0,max_slice=0;
    while(is_undefined(_g.order_system.next)&&ticks++<20000) {
        var step_started=get_timer();orders_tick(_g);
        max_slice=max(max_slice,get_timer()-step_started);
    }
    order_test_assert(!is_undefined(_g.order_system.next),"bounded preparation terminates");
    return {elapsed:(get_timer()-started)/1000,ticks:ticks,max_slice:max_slice/1000};
}
function order_test_recipe(_s,_d) {
    var goal={min:_d.stats_min,max:_d.stats_max};
    for(var i=0;i<array_length(_s.cache.recipes);++i)
        if(bal_matches(_s.cache.recipe_stats[i],goal)&&orders_recipe_fits(_s,i)) return _s.cache.recipes[i];
    throw "ORDER_TEST_FAILURE: no authored recipe";
}
function order_test_assemble(_g,_d,_counts) {
    campaign_open(_g,_d);
    var s=_g.order_system,previous=board_port_reference(_d,0);
    for(var t=0;t<array_length(s.packing_order);++t) {
        var index=s.packing_order[t].index;
        repeat(_counts[index]) {
            var item=instance_create_depth(0,0,-10,s.model.items[index].object_type);
            item.device=_d;var placed=false;
            for(var turn=0;turn<4&&!placed;++turn) {
                for(var row=0;row<_d.rows&&!placed;++row) for(var col=0;col<_d.cols&&!placed;++col)
                    placed=board_place(item,col,row);
                if(!placed) {item.shape=orders_rotate(item.shape);item.rotation_steps=(item.rotation_steps+1) mod 4;}
            }
            order_test_assert(placed,"cached solution physically fits actual board");
            array_push(_d.children,item);
            var ports=[];
            for(var row=0;row<array_length(item.shape);++row) for(var col=0;col<array_length(item.shape[row]);++col) {
                var directions=cell_directions(item.shape[row][col]);
                for(var p=0;p<array_length(directions);++p) array_push(ports,port_reference(item,col,row,directions[p]));
            }
            order_test_assert(wire_connect(_d,previous,ports[0]),"solution forms actual powered chain");
            previous=ports[1];
        }
    }
    order_test_assert(wire_connect(_d,previous,board_port_reference(_d,1)),"solution closes circuit");
    device_stats_update(_d);
    order_test_assert(_d.requirements_met,"real stats meet instance requirements");
}
function order_generation_tests() {
    global.order_test_passes=0;
    var g=instance_find(obj_game,0),s=g.order_system;
    s.settings.fixed_tier2=false; // Exercise the retained tier-one generator independently.
    order_test_assert(g.order_device.object_index==obj_order&&g.order_index==0,"first order unchanged");
    var init_timing=order_test_ready(g);
    order_test_assert(s.cache.phase=="done"&&array_length(s.cache.recipes)==3002,"complete shared eight-type/six-module numeric cache");
    order_test_assert(array_length(s.cache.recipe_stats)==array_length(s.cache.recipes),"cached stats match recipes");
    show_debug_message("ORDER_CACHE ms="+string(s.cache_elapsed_us/1000)+" preparation_ms="+string(init_timing.elapsed)+" max_slice_ms="+string(init_timing.max_slice));
    var generated=0,fallbacks=0,total_ms=0,slowest=0,slice_max=0,signatures=[];
    for(var seed=1;seed<=20;++seed) {
        s.rng=seed*104729+1;s.next=undefined;orders_prepare(s,3);
        var timing=order_test_ready(g),def=s.next;
        total_ms+=timing.elapsed;slowest=max(slowest,timing.elapsed);slice_max=max(slice_max,timing.max_slice);
        if(def.generation.fallback) fallbacks++;
        else {
            generated++;
            order_test_assert(def.generation.trials==s.settings.trials,"all simulation runs succeed by five");
            order_test_assert(def.generation.mean_devices>=2.5&&def.generation.mean_devices<=3.5,"mean near three dismantles");
            array_push(signatures,json_stringify({min:def.min,max:def.max}));
        }
        show_debug_message("ORDER_SAMPLE seed="+string(seed)+" fallback="+string(def.generation.fallback)+" ms="+string(timing.elapsed)+(def.generation.fallback?"":" mean="+string(def.generation.mean_devices)+" attempts="+string(def.generation.attempts)));
    }
    order_test_assert(generated>=10,"most seeds produce new orders within budget");
    var varied=false;
    for(var i=1;i<array_length(signatures);++i) if(signatures[i]!=signatures[0]) varied=true;
    order_test_assert(varied,"generated requirements vary");
    var rng_before=random_get_seed();orders_tick(g);
    order_test_assert(random_get_seed()==rng_before,"background preparation preserves gameplay RNG");
    s.next=undefined;orders_prepare(s,3);
    var cache_before=s.cache.nodes;
    global.mode=GameMode.Pause;orders_tick(g);
    order_test_assert(is_undefined(s.next)&&s.worker.phase=="candidate"&&s.worker.attempt==0&&s.cache.nodes==cache_before,"pause freezes pending order preparation");global.mode=GameMode.Menu;
    order_test_ready(g);
    // Deliver the three authored orders using real placements, wires and reward path.
    var authored=[obj_order,obj_order_2,obj_order_3];
    for(var i=0;i<3;++i) {
        var d=g.order_device;
        order_test_assert(d.object_index==authored[i],"authored order sequence retained");
        var counts=order_test_recipe(s,d),before=g.money;
        order_test_assemble(g,d,counts);var reward=d.order_reward;
        order_test_assert(campaign_complete(g)&&g.money==before+reward,"delivery awards once and advances");
        order_test_assert(!instance_exists(d),"delivered device and installed parts removed");
        before=g.money;
        order_test_assert(!campaign_complete(g)&&g.money==before,"double delivery cannot pay or advance again");
    }
    order_test_assert(g.order_index==3&&g.order_device.object_index==obj_big_order&&!g.orders_finished,"fourth order is generic; campaign continues");
    // Verify a generated definition against actual gameplay, then keep issuing indefinitely.
    for(var i=0;i<4;++i) {
        var d=g.order_device,counts=order_test_recipe(s,d);
        order_test_assert(sprite_exists(d.small_sprite)&&sprite_exists(d.cover_sprite)&&sprite_exists(d.board_sprite),"instance owns all three sprites");
        order_test_ready(g);order_test_assemble(g,d,counts);
        order_test_assert(campaign_complete(g)&&g.order_device.object_index==obj_big_order,"generated delivery creates another generic order");
    }
    // No ready result must immediately reuse authored data, without waiting.
    s.next=undefined;var old=g.order_device;
    var fallback_device=orders_create(g);
    order_test_assert(fallback_device.order_generation.fallback,"unfinished generation uses authored fallback");
    instance_destroy(fallback_device);g.order_device=old;
    var saved=s.settings.generation_us;s.settings.generation_us=0;s.next=undefined;orders_prepare(s,g.order_index+1);orders_tick(g);
    order_test_assert(!is_undefined(s.next)&&s.next.generation.fallback,"CPU timeout produces fallback");s.settings.generation_us=saved;
    s.next=undefined;orders_prepare(s,g.order_index+1);s.worker.attempt=s.settings.attempts;orders_tick(g);
    order_test_assert(s.next.generation.fallback,"attempt limit produces fallback");
    var def=orders_fallback(s),d=instance_create_depth(-10000,-10000,0,obj_big_order,{balance_probe:true,order_definition:def});
    var original=struct_get(def.min,"energy");d.stats_min.energy=999;
    order_test_assert(def.min.energy==original,"requirements copied independently into instances");instance_destroy(d);
    // Cache search exhaustion is also bounded and cannot expose partial recipes.
    var cache_phase=s.cache.phase;s.cache.phase="limited";s.next=undefined;orders_tick(g);
    order_test_assert(s.next.generation.fallback,"incomplete cache uses fallback");s.cache.phase=cache_phase;
    show_debug_message("ORDER_PERFORMANCE generated="+string(generated)+" fallback="+string(fallbacks)+" mean_ms="+string(total_ms/20)+" max_ms="+string(slowest)+" max_slice_ms="+string(slice_max));
    show_debug_message("ORDER_TEST_RESULT passes="+string(global.order_test_passes)+" failures=0");game_end();
}
