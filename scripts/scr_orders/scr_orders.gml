// The authored sequence comes from obj_game.order_types; later orders use definitions.
function orders_settings() {
    return {fixed_tier2:true,slots:6,trials:32,device_limit:5,mean_min:2.5,mean_max:3.5,
        attempts:16,slice_us:1500,generation_us:600000,cache_us:1500000};
}
function orders_copy(_data) {
    var out={},names=struct_get_names(_data);
    for(var i=0;i<array_length(names);++i) struct_set(out,names[i],struct_get(_data,names[i]));
    return out;
}
function orders_definition(_device) {
    return {name:_device.device_name,base:orders_copy(_device.stats_base),
        min:orders_copy(_device.stats_min),max:orders_copy(_device.stats_max),
        small_sprite:_device.small_sprite,cover_sprite:_device.cover_sprite,
        board_sprite:_device.board_sprite,mask_sprite:_device.board_mask_sprite,
        reward:_device.order_reward,tier:_device.order_tier,generation:{fallback:true}};
}
function orders_apply(_device,_definition) {
    _device.order_tier=struct_exists(_definition,"tier")?_definition.tier:1;
    _device.device_name=_definition.name;
    _device.stats_base=orders_copy(_definition.base);
    _device.stats_min=orders_copy(_definition.min);
    _device.stats_max=orders_copy(_definition.max);
    _device.small_sprite=_definition.small_sprite;
    _device.cover_sprite=_definition.cover_sprite;
    _device.board_sprite=_definition.board_sprite;
    _device.board_mask_sprite=_definition.mask_sprite;
    _device.order_reward=_definition.reward;
    _device.order_generation=_definition.generation;
}
function orders_rotate(_shape) {
    var h=array_length(_shape),w=array_length(_shape[0]),out=[];
    for(var row=0;row<w;++row) {
        var line=[];
        for(var col=0;col<h;++col) array_push(line,cell_rotate(_shape[h-1-col][row]));
        array_push(out,line);
    }
    return out;
}
// Precompute legal occupied cells. No instances, gameplay RNG or live boards are changed.
function orders_placements(_shape,_board) {
    var out=[],rows=array_length(_board),cols=array_length(_board[0]);
    repeat(4) {
        for(var row=0;row<rows;++row) for(var col=0;col<cols;++col) {
            var cells=[],fits=true;
            for(var sy=0;sy<array_length(_shape)&&fits;++sy) for(var sx=0;sx<array_length(_shape[sy]);++sx) {
                if(_shape[sy][sx]==Cell.Empty) continue;
                var bx=col+sx,by=row+sy;
                if(bx>=cols||by>=rows||!_board[by][bx]) {fits=false;break;}
                array_push(cells,by*cols+bx);
            }
            if(fits&&array_length(cells)>0) array_push(out,cells);
        }
        _shape=orders_rotate(_shape);
    }
    return out;
}
function orders_init(_g) {
    var settings=orders_settings(),templates=[];
    for(var i=0;i<array_length(_g.order_types);++i) {
        var probe=instance_create_depth(-10000,-10000,0,_g.order_types[i],{balance_probe:true});
        array_push(templates,orders_definition(probe));instance_destroy(probe);
    }
    var board=board_shape_from_sprite(templates[0].mask_sprite,16);
    var items=[],placements=[],packing_order=[];
    for(var i=0;i<array_length(_g.module_types);++i) {
        var type=_g.module_types[i];
        var probe=instance_create_depth(-10000,-10000,0,type,{balance_probe:true});
        var ports=0,area=0;
        for(var row=0;row<array_length(probe.shape);++row) for(var col=0;col<array_length(probe.shape[row]);++col) {
            if(probe.shape[row][col]!=Cell.Empty) area++;
            ports+=array_length(cell_directions(probe.shape[row][col]));
        }
        // Every generated solution can form a chain between the two board contacts.
        if(probe.drop_weight>0&&probe.unlock_after_orders<=_g.order_index) {
            array_push(items,{name:probe.module_name,object_type:type,qty:0,
                drop_weight:probe.drop_weight,stats:lab_stats_copy(probe.stats)});
            array_push(placements,ports>=2?orders_placements(probe.shape,board):[]);
            array_push(packing_order,{index:array_length(items)-1,area:area});
        }
        instance_destroy(probe);
    }
    array_sort(packing_order,function(_a,_b){return _b.area-_a.area;});
    var model={items:items,goal:{slots:settings.slots,min_installed:1,allow_unpowered:false,
        base:lab_stats_copy(templates[0].base),min:{},max:{}},
        econ:{seed:1,trials:settings.trials,device_limit:settings.device_limit,
            start_money:0,device_price:25,order_price:0,gift:10,gift_seconds:5,
            dismantle_seconds:30,assembly_seconds:30,batch_min:1,batch_max:1,loot_min:2,loot_max:3}};
    var cache=lab_job(model);cache.compact=true;cache.recipe_stats=[];
    _g.order_system={settings:settings,templates:templates,model:model,cache:cache,
        placements:placements,packing_order:packing_order,cells:array_length(board)*array_length(board[0]),
        fits:[],cache_elapsed_us:0,rng:irandom(1000000)+1,worker:undefined,next:undefined,
        next_index:array_length(_g.order_types),last:undefined};
}
// Conservative first-fit with rotations. Rejection may miss a layout; acceptance is real.
function orders_recipe_fits(_system,_index) {
    if(_index<array_length(_system.fits)&&!is_undefined(_system.fits[_index])) return _system.fits[_index];
    var counts=_system.cache.recipes[_index],occupied=array_create(_system.cells,false),ok=true;
    for(var t=0;t<array_length(_system.packing_order)&&ok;++t) {
        var index=_system.packing_order[t].index,options=_system.placements[index];
        repeat(counts[index]) {
            var chosen=-1;
            for(var p=0;p<array_length(options);++p) {
                var cells=options[p],free=true;
                for(var c=0;c<array_length(cells);++c) if(occupied[cells[c]]) {free=false;break;}
                if(free) {chosen=p;break;}
            }
            if(chosen<0) {ok=false;break;}
            var cells=options[chosen];
            for(var c=0;c<array_length(cells);++c) occupied[cells[c]]=true;
        }
    }
    _system.fits[_index]=ok;return ok;
}
function orders_fallback(_system) {
    var at=lab_roll(_system,0,array_length(_system.templates)-1),out=orders_copy(_system.templates[at]);
    out.generation={fallback:true};return out;
}
function orders_prepare(_system,_index) {
    _system.next_index=_index;
    _system.worker={phase:"candidate",attempt:0,elapsed_us:0,cursor:0,definition:undefined,sim:undefined};
}
function orders_candidate(_system) {
    var w=_system.worker;
    if(w.attempt++>=_system.settings.attempts) {
        _system.next=orders_fallback(_system);w.phase="done";return;
    }
    var out=orders_copy(_system.templates[0]);
    out.name="Big order";
    var energy=lab_roll(_system,5,7);
    out.min={energy:energy,stability:0};
    out.max={energy:energy+lab_roll(_system,4,7),heat:lab_roll(_system,4,8),weight:lab_roll(_system,12,18)};
    if(lab_roll(_system,0,1)==1) out.max.stability=lab_roll(_system,6,10);
    out.reward=150+5*energy; // Stable jam economy; no unlimited reward scaling.
    var model={items:_system.model.items,econ:orders_copy(_system.model.econ),
        goal:{slots:_system.settings.slots,min_installed:1,allow_unpowered:false,
            base:out.base,min:out.min,max:out.max}};
    model.econ.seed=lab_roll(_system,1,1000000);
    var sim=lab_job(model);sim.phase="simulate";sim.stack=[];
    w.definition=out;w.sim=sim;w.cursor=0;w.phase="filter";
}
function orders_work(_system) {
    var w=_system.worker;
    switch(w.phase) {
        case "candidate":orders_candidate(_system);break;
        case "filter":
            if(w.cursor>=array_length(_system.cache.recipes)) {
                w.phase=array_length(w.sim.recipes)>0?"simulate":"candidate";break;
            }
            var at=w.cursor++;
            // Generated goals use these four gameplay stats. Avoid eight dynamic
            // property lookups for every record on every candidate.
            var values=_system.cache.recipe_stats[at],goal=w.sim.model.goal;
            if(values.energy<goal.min.energy||values.energy>goal.max.energy
                ||values.heat>goal.max.heat||values.weight>goal.max.weight
                ||values.stability<goal.min.stability
                ||(struct_exists(goal.max,"stability")&&values.stability>goal.max.stability)) break;
            if(orders_recipe_fits(_system,at))
                array_push(w.sim.recipes,_system.cache.recipes[at]);
            break;
        case "simulate":
            lab_sim_step(w.sim,64);
            // A capped failure rejects the candidate, never disappears from its mean.
            if(array_length(w.sim.runs)>w.sim.successes) {w.phase="candidate";break;}
            if(w.sim.phase!="done") break;
            var total=0;
            for(var i=0;i<array_length(w.sim.runs);++i) total+=w.sim.runs[i].devices;
            var average_devices=total/array_length(w.sim.runs);
            if(average_devices<_system.settings.mean_min||average_devices>_system.settings.mean_max) {w.phase="candidate";break;}
            w.definition.generation={fallback:false,mean_devices:average_devices,trials:w.sim.successes,
                max_devices:_system.settings.device_limit,attempts:w.attempt,
                recipe:w.sim.recipes[0],elapsed_us:w.elapsed_us};
            _system.next=w.definition;w.phase="done";
            break;
    }
}
function orders_tick(_g) {
    if(global.mode==GameMode.Pause) return;
    var s=_g.order_system,start=get_timer(),deadline=start+s.settings.slice_us;
    // The tested second-tier order is fixed for now; no background rerolls needed.
    if(s.settings.fixed_tier2) return;
    if(s.cache.phase=="count") {
        while(s.cache.phase=="count"&&get_timer()<deadline) lab_count_step(s.cache,8);
        s.cache_elapsed_us+=get_timer()-start;
        if(s.cache.phase=="count"&&s.cache_elapsed_us>=s.settings.cache_us) s.cache.phase="limited";
        // This cache enumerates all combinations, so its simulation is unnecessary.
        if(s.cache.phase=="simulate") {
            s.cache.phase="done";
            s.fits=array_create(array_length(s.cache.recipes),undefined);
        }
        return;
    }
    if(!is_undefined(s.next)) return;
    if(s.cache.phase!="done") {s.next=orders_fallback(s);return;}
    if(is_undefined(s.worker)) orders_prepare(s,max(array_length(_g.order_types),_g.order_index+1));
    var w=s.worker;
    while(w.phase!="done"&&get_timer()<deadline) orders_work(s);
    w.elapsed_us+=get_timer()-start;
    if(w.phase!="done"&&w.elapsed_us>=s.settings.generation_us) {s.next=orders_fallback(s);w.phase="done";}
}
function orders_create(_g) {
    if(_g.order_index<array_length(_g.order_types)) return campaign_create_device(_g.order_types[_g.order_index]);
    var s=_g.order_system,definition=s.settings.fixed_tier2?orders_tier2_definition():
        (is_undefined(s.next)?orders_fallback(s):s.next);
    s.last=definition.generation;
    var d=instance_create_depth(floor(room_width/3)+(room_width-floor(room_width/3))/2,
        (80+room_height-48)/2,0,obj_big_order,{work_layout:true,order_definition:definition});
    s.next=undefined;
    if(!s.settings.fixed_tier2) orders_prepare(s,_g.order_index+1);
    return d;
}

// Tested balance_settings - Copy.json goal; keep these bounds exact until retuned.
function orders_tier2_definition() {
    return {name:"Big order / Tier 2",tier:2,
        base:{energy:0,heat:0,stability:0,weight:0,speed:0,efficiency:0,accuracy:0,wear:0},
        min:{energy:3,heat:0,stability:0,speed:2},
        max:{energy:7,heat:5,stability:5,speed:5},
        small_sprite:spr_drone_small,cover_sprite:spr_drone_cover,
        board_sprite:spr_drone_board,mask_sprite:spr_drone_board,
        reward:300,generation:{fallback:false,authored:true,tier:2}};
}
