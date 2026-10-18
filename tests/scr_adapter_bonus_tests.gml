function bonus_assert(_ok,_label) {
    if(!_ok) throw "ADAPTER_BONUS_FAILURE: "+_label;
    global.adapter_bonus_passes++;
}
function bonus_fixture(_seed,_shape=undefined) {
    var d=instance_create_depth(850,370,0,par_device);
    d.campaign=true;d.campaign_loot_types=[obj_module_universal,obj_module_universal];
    if(is_undefined(_shape)) {
        d.board_shape=[];for(var row=0;row<7;++row) array_push(d.board_shape,array_create(10,1));
    } else d.board_shape=_shape;
    random_set_seed(_seed);
    with(d) device_build();
    return d;
}
function bonus_counts(_d) {
    var out={normal:0,adapter:0,straight:0,corner:0};
    for(var i=0;i<array_length(_d.children);++i) {
        var item=_d.children[i];if(!instance_exists(item)) continue;
        if(item.object_index==obj_module_universal) out.normal++;
        else if(item.object_index==obj_module_adapter) {out.adapter++;out.straight++;}
        else if(item.object_index==obj_module_adapter_corner) {out.adapter++;out.corner++;}
    }
    return out;
}
function adapter_bonus_tests() {
    global.adapter_bonus_passes=0;
    var g=instance_find(obj_game,0),old_index=g.order_index,pool=g.module_types;
    var hit_seed=-1,miss_seed=-1;
    for(var i=1;i<=100&&(hit_seed<0||miss_seed<0);++i) {
        var seed=i*104729;random_set_seed(seed);
        if(random(1)<0.33) hit_seed=seed;else miss_seed=seed;
    }
    bonus_assert(hit_seed>=0&&miss_seed>=0,"deterministic hit and miss seeds available");
    g.order_index=3;
    var d=bonus_fixture(hit_seed),parts=bonus_counts(d);
    bonus_assert(parts.normal==2&&parts.adapter==1&&d.placed_modules==3&&d.requested_modules==3,"successful roll adds one adapter after all normal parts");
    var count=instance_number(par_module);d.open_cover();campaign_adapter_bonus(d);
    bonus_assert(instance_number(par_module)==count&&bonus_counts(d).adapter==1,"reopening and repeated bonus call cannot reroll or duplicate");instance_destroy(d);
    d=bonus_fixture(miss_seed);parts=bonus_counts(d);
    bonus_assert(parts.normal==2&&parts.adapter==0&&d.requested_modules==2,"failed roll retains full normal loot");instance_destroy(d);
    g.order_index=2;d=bonus_fixture(hit_seed);parts=bonus_counts(d);
    bonus_assert(parts.normal==2&&parts.adapter==0,"bonus remains locked before third delivery");
    g.order_index=3;campaign_adapter_bonus(d);
    bonus_assert(bonus_counts(d).adapter==0,"already opened donor cannot gain a bonus on later unlock");instance_destroy(d);
    d=bonus_fixture(hit_seed,[[1,1]]);parts=bonus_counts(d);
    bonus_assert(parts.normal==2&&parts.adapter==0&&d.requested_modules==2&&d.placed_modules==2,"full board preserves normal loot and counters without leaking bonus parts");instance_destroy(d);
    d=bonus_fixture(hit_seed,[[1],[1],[1],[1]]);parts=bonus_counts(d);
    bonus_assert(parts.normal==2&&parts.adapter==1&&parts.straight==1,"bonus tries the alternative footprint and rotates into remaining vertical space");
    var rotated_ok=false;
    for(var i=0;i<array_length(d.children);++i) {
        var item=d.children[i];
        if(instance_exists(item)&&item.object_index==obj_module_adapter) {
            var ports=adapter_ports(item);
            rotated_ok=item.rotation_steps mod 2==1&&board_can_place(item,item.grid_col,item.grid_row)
                &&port_current(ports[0]).port_type==1&&port_current(ports[1]).port_type==2;
        }
    }
    bonus_assert(rotated_ok,"rotated bonus retains valid typed contacts and legal placement");instance_destroy(d);
    // All ordinary choices remain ordinary even when adapter types are in the catalog.
    g.module_types=[obj_module_universal,obj_module_adapter,obj_module_adapter_corner];
    var ordinary_valid=true,bonus_valid=true,hits=0,straight=0,corner=0;
    for(var i=1;i<=500;++i) {
        d=bonus_fixture(i*104729);parts=bonus_counts(d);
        if(parts.normal!=2) ordinary_valid=false;
        if(parts.adapter>1||d.placed_modules!=2+parts.adapter||d.requested_modules!=d.placed_modules) bonus_valid=false;
        hits+=parts.adapter;straight+=parts.straight;corner+=parts.corner;
        instance_destroy(d);
    }
    bonus_assert(ordinary_valid&&bonus_valid,"500 fixed donors retain normal count and at most one extra");
    bonus_assert(hits>=125&&hits<=205,"observed rate consistent with one 33 percent roll per donor");
    bonus_assert(straight>0&&corner>0&&abs(straight-corner)<hits*0.3,"both adapter variants selected with roughly equal frequency");
    // Actual weighted donor path must also add, rather than replace, ordinary parts.
    for(var i=1;i<=30;++i) {
        d=instance_create_depth(850,370,0,par_device);d.campaign=true;
        d.board_shape=[];for(var row=0;row<7;++row) array_push(d.board_shape,array_create(10,1));
        random_set_seed(i*104729);with(d) device_build();parts=bonus_counts(d);
        bonus_assert(parts.normal>=2&&parts.normal<=3&&parts.adapter<=1,"weighted donor retains its two or three normal drops");
        instance_destroy(d);
    }
    bonus_assert(!campaign_adapter_bonus(g.generator)&&!campaign_adapter_bonus(g.order_device),"orders and generator receive no bonus loot");
    g.order_index=old_index;g.module_types=pool;
    show_debug_message("ADAPTER_BONUS_RESULT passes="+string(global.adapter_bonus_passes)+" failures=0 sample=500 hits="+string(hits)+" straight="+string(straight)+" corner="+string(corner));
}
