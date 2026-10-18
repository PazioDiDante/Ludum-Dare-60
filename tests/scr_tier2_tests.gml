// Run with the shared order_test_assemble/order_test_recipe helpers in an isolated copy.
function tier2_assert(_ok,_label) {
    if(!_ok) throw "TIER2_FAILURE: "+_label;
    global.tier2_passes++;
}
function tier2_chain(_g,_d,_types) {
    campaign_open(_g,_d);var previous=board_port_reference(_d,0),parts=[];
    for(var i=0;i<array_length(_types);++i) {
        var item=instance_create_depth(0,0,-10,_types[i]);item.device=_d;
        var placed=false;
        for(var row=0;row<_d.rows&&!placed;++row) for(var col=0;col<_d.cols&&!placed;++col)
            placed=board_place(item,col,row);
        tier2_assert(placed,"new module footprint fits actual order board");
        array_push(_d.children,item);array_push(parts,item);var ports=[];
        for(var row=0;row<array_length(item.shape);++row) for(var col=0;col<array_length(item.shape[row]);++col) {
            var directions=cell_directions(item.shape[row][col]);
            for(var p=0;p<array_length(directions);++p) array_push(ports,port_reference(item,col,row,directions[p]));
        }
        tier2_assert(wire_connect(_d,previous,ports[0]),"new modules form working chain");previous=ports[1];
    }
    tier2_assert(wire_connect(_d,previous,board_port_reference(_d,1)),"new chain closes between board contacts");
    device_stats_update(_d);return parts;
}
function tier2_tests(_g) {
    show_debug_message("TIER2_STAGE start");
    global.tier2_passes=0;global.order_test_passes=0;
    var handle=file_text_open_read("tier2_balance.json"),text="";
    while(!file_text_eof(handle)) {text+=file_text_read_string(handle);file_text_readln(handle);}file_text_close(handle);
    var source=json_parse(text),keys=bal_keys(),types=game_module_types(),new_types=[];
    show_debug_message("TIER2_STAGE source_read");
    tier2_assert(array_length(types)==14,"full catalog contains eight old and six new modules");
    for(var i=8;i<14;++i) {
        var module=instance_create_depth(-10000,-10000,0,types[i],{balance_probe:true}),expected=source.modules[i];
        tier2_assert(module.module_name==expected.name,"new name copied exactly");
        tier2_assert(module.drop_weight==lab_number(expected.drop_weight),"drop weights including 0.5 copied exactly");
        tier2_assert(module.unlock_after_orders==3,"new module unlock threshold is three deliveries");
        for(var k=0;k<array_length(keys);++k)
            tier2_assert(bal_stat(module.stats,keys[k])==lab_number(struct_get(expected.stats,keys[k])),"all eight module stats copied exactly");
        array_push(new_types,types[i]);instance_destroy(module);
    }
    var pool=_g.module_types;
    show_debug_message("TIER2_STAGE modules_checked");
    _g.module_types=new_types;
    for(var stage=0;stage<3;++stage) {
        _g.order_index=stage;
        var d=campaign_create_device(obj_remote);d.campaign=true;d.open_cover();
        tier2_assert(d.placed_modules==0,"new-only pool cannot drop before third delivery");instance_destroy(d);
    }
    _g.order_index=0;_g.module_types=pool;
    // Prove the unchanged authored sequence through actual placements and delivery.
    var s=_g.order_system;
    show_debug_message("TIER2_STAGE counting");
    while(s.cache.phase=="count") lab_count_step(s.cache,1000);
    tier2_assert(s.cache.phase=="simulate"&&array_length(s.model.items)==8,"tier-one recipe cache excludes locked module types");
    s.cache.phase="done";s.fits=array_create(array_length(s.cache.recipes),undefined);
    show_debug_message("TIER2_STAGE cache_done");
    var authored=[obj_order,obj_order_2,obj_order_3],rewards=[100,125,150];
    for(var i=0;i<3;++i) {
        var d=_g.order_device;
        tier2_assert(d.object_index==authored[i]&&d.order_reward==rewards[i],"first three orders and rewards unchanged");
        order_test_assemble(_g,d,order_test_recipe(s,d));
        tier2_assert(campaign_complete(_g),"authored order can still be delivered");
        show_debug_message("TIER2_STAGE delivered_"+string(i+1));
    }
    var d=_g.order_device;
    tier2_assert(_g.order_index==3&&d.object_index==obj_big_order&&d.order_tier==2,"third delivery creates second-tier generic order");
    tier2_assert(d.order_reward==300,"second tier reward is 300");
    for(var k=0;k<array_length(keys);++k) {
        var key=keys[k],lo=struct_get(source.min,key),hi=struct_get(source.max,key);
        tier2_assert((lo==""&&!struct_exists(d.stats_min,key))||(lo!=""&&struct_exists(d.stats_min,key)&&struct_get(d.stats_min,key)==lab_number(lo)),"exact source minimum, including absent bounds");
        tier2_assert((hi==""&&!struct_exists(d.stats_max,key))||(hi!=""&&struct_exists(d.stats_max,key)&&struct_get(d.stats_max,key)==lab_number(hi)),"exact source maximum, including absent bounds");
    }
    tier2_assert(!struct_exists(d.stats_min,"efficiency")&&!struct_exists(d.stats_max,"weight"),"no unrequested efficiency or weight requirement");
    // Each newly unlocked type can actually drop, fit and receive generated wiring.
    var samples=0;
    for(var i=0;i<array_length(new_types);++i) {
        _g.module_types=[new_types[i]];
        var donor=campaign_create_device(i mod 2==0?obj_remote:obj_radio);donor.campaign=true;donor.open_cover();
        tier2_assert(donor.placed_modules>=2,"new type drops after third delivery and fits donor");
        tier2_assert(donor.circuit_connected&&donor.powered_count==donor.placed_modules,"new donor modules are wired and powered");
        samples+=donor.placed_modules;instance_destroy(donor);
    }
    _g.module_types=pool;
    var recipe=[obj_module_battery,obj_module_battery,obj_module_coil,obj_module_little_speed,obj_module_universal];
    var parts=tier2_chain(_g,d,recipe),speed_module=parts[3];
    tier2_assert(d.circuit_connected&&d.requirements_met,"real second-tier assembly satisfies all imported bounds");
    tier2_assert(d.current_stats.energy==3&&d.current_stats.heat==3&&d.current_stats.stability==2&&d.current_stats.speed==2&&d.current_stats.efficiency==-1,"speed and efficiency sum with powered core stats");
    speed_module.stats.speed=0;device_stats_update(d);
    tier2_assert(d.circuit_connected&&!d.requirements_met,"speed below two blocks delivery even with closed circuit");
    speed_module.stats.speed=6;device_stats_update(d);
    tier2_assert(d.circuit_connected&&!d.requirements_met,"speed above five blocks delivery");
    speed_module.stats.speed=2;device_stats_update(d);
    var removed=[];
    for(var i=array_length(d.wires)-1;i>=0;--i) {
        var w=d.wires[i];
        if(w.a.module==speed_module||w.b.module==speed_module) {
            array_push(removed,{a:w.a,b:w.b});wire_disconnect(d,i);
        }
    }
    tier2_assert(!speed_module.circuit_powered&&d.current_stats.speed==0&&d.current_stats.efficiency==0&&d.current_stats.weight==5,"unpowered module loses speed and efficiency while retaining weight");
    for(var i=0;i<array_length(removed);++i) tier2_assert(wire_connect(d,removed[i].a,removed[i].b),"speed module can be reconnected");
    tier2_assert(d.requirements_met&&d.current_stats.speed==2&&d.current_stats.efficiency==-1,"reconnected new stats immediately restore requirements");
    tier2_assert(module_stat_beneficial("speed",2)&&module_stat_beneficial("efficiency",2)&&!module_stat_beneficial("efficiency",-1),"tooltip signs treat speed and efficiency as beneficial");
    var coins=_g.money;
    tier2_assert(campaign_complete(_g)&&_g.money==coins+300,"second-tier delivery pays exactly 300");
    tier2_assert(_g.order_device.order_tier==2&&_g.order_device.stats_min.speed==2&&_g.order_device.order_reward==300,"subsequent orders retain tested tier-two template");
    coins=_g.money;
    tier2_assert(!campaign_complete(_g)&&_g.money==coins,"double delivery cannot pay again");
    var cfg=lab_defaults();lab_sync_game(cfg);
    tier2_assert(array_length(cfg.modules)==14&&lab_number(cfg.modules[13].drop_weight)==0.5&&lab_number(cfg.modules[8].stats.speed)==2,"balance lab imports full catalog with fractional weight and new stats");
    array_resize(cfg.modules,8);cfg.modules[0].stats.energy="99";cfg.min.speed="4";
    lab_add_progression_modules(cfg);lab_add_progression_modules(cfg);
    tier2_assert(array_length(cfg.modules)==14&&cfg.modules[0].stats.energy=="99"&&cfg.min.speed=="4","old lab experiments receive new modules once without resetting tuning");
    array_resize(cfg.modules,13);lab_add_progression_modules(cfg);
    tier2_assert(array_length(cfg.modules)==13,"later intentional experiment deletions remain deleted");
    var imported={modules:source.modules};
    lab_add_progression_modules(imported);
    tier2_assert(array_length(imported.modules)==14,"imported unlinked modules match by name and are not duplicated");
    var nodes=s.cache.nodes;orders_tick(_g);
    tier2_assert(s.cache.nodes==nodes&&is_undefined(s.next),"fixed tier does not run or overwrite generated requirements");
    // A separate generic object can be used as an editable tier-two template probe.
    var probe=instance_create_depth(-10000,-10000,0,obj_big_order,{balance_probe:true,order_definition:orders_tier2_definition()});
    probe.stats_min.speed=99;
    tier2_assert(orders_tier2_definition().min.speed==2,"instance edits cannot mutate authored template");instance_destroy(probe);
    tier2_chain(_g,_g.order_device,recipe);
    _g.tier2_preview_module=instance_create_depth(-10000,-10000,0,obj_module_big_boy);_g.tier2_preview_module.in_inventory=true;
    show_debug_message("TIER2_RESULT passes="+string(global.tier2_passes)+" shared_order_passes="+string(global.order_test_passes)+" failures=0 drop_samples="+string(samples));
}
