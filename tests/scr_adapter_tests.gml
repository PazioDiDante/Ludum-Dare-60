// Standalone suite: add only to an isolated project copy.
function adapter_assert(_ok,_label) {
    if(!_ok) throw "ADAPTER_TEST_FAILURE: "+_label;
    global.adapter_passes++;
}
function adapter_ports(_module) {
    var out=[];
    for(var row=0;row<array_length(_module.shape);++row) for(var col=0;col<array_length(_module.shape[row]);++col) {
        var directions=cell_directions(_module.shape[row][col]);
        for(var i=0;i<array_length(directions);++i) array_push(out,port_reference(_module,col,row,directions[i]));
    }
    return out;
}
function adapter_tests() {
    global.adapter_passes=0;
    var g=instance_find(obj_game,0),types=[obj_module_adapter,obj_module_adapter_corner],keys=bal_keys();
    var original_index=g.order_index,pool=g.module_types;
    for(var t=0;t<2;++t) {
        var probe=instance_create_depth(-10000,-10000,0,types[t]);
        adapter_assert(probe.drop_weight==0&&probe.unlock_after_orders==3,"bonus-only adapter unlocked at tier two");
        for(var k=0;k<array_length(keys);++k) adapter_assert(bal_stat(probe.stats,keys[k])==0,"every adapter stat including mass is zero");
        var ports=adapter_ports(probe);
        adapter_assert(array_length(ports)==2&&ports[0].port_type==1&&ports[1].port_type==2,"exactly two distinct-type contacts");
        var rotated=probe.shape;
        repeat(4) {
            rotated=orders_rotate(rotated);var contacts=0,type_sum=0;
            for(var row=0;row<array_length(rotated);++row) for(var col=0;col<array_length(rotated[row]);++col) {
                var n=array_length(cell_directions(rotated[row][col]));contacts+=n;type_sum+=n*cell_port_type(rotated[row][col]);
            }
            adapter_assert(contacts==2&&type_sum==3,"rotation preserves one contact of each type");
        }
        instance_destroy(probe);
        g.module_types=[obj_module_universal,types[t]];g.order_index=2;
        var donor=campaign_create_device(obj_remote);donor.campaign=true;donor.open_cover();
        var adapters=0;
        for(var i=0;i<array_length(donor.children);++i) {
            var part=donor.children[i];
            if(instance_exists(part)&&(part.object_index==obj_module_adapter||part.object_index==obj_module_adapter_corner)) adapters++;
        }
        adapter_assert(adapters==0,"adapter is locked before fourth order");instance_destroy(donor);
        g.order_index=3;donor=campaign_create_device(obj_remote);donor.campaign=true;donor.open_cover();
        var ordinary=0;adapters=0;
        for(var i=0;i<array_length(donor.children);++i) {
            var part=donor.children[i];
            if(!instance_exists(part)) continue;
            if(part.object_index==obj_module_universal) ordinary++;
            else if(part.object_index==obj_module_adapter||part.object_index==obj_module_adapter_corner) adapters++;
        }
        adapter_assert(ordinary>=2&&ordinary<=3&&adapters<=1,"bonus never replaces normal modules or adds multiple adapters");
        for(var i=0;i<array_length(donor.wires);++i) adapter_assert(ports_compatible(donor.wires[i].a,donor.wires[i].b),"automatic adapter wiring respects port types");
        instance_destroy(donor);
    }
    g.module_types=pool;g.order_index=original_index;
    // Real adapters bridge 1 -> 2 -> 1 without changing a generator's stats.
    var d=g.generator;campaign_open(g,d);
    var a=instance_create_depth(0,0,-10,types[0]),b=instance_create_depth(0,0,-10,types[1]);
    a.device=d;b.device=d;array_push(d.children,a);array_push(d.children,b);
    adapter_assert(board_place(a,1,1)&&board_place(b,5,2),"both adapter shapes fit actual board");
    var ap=adapter_ports(a),bp=adapter_ports(b),source=board_port_reference(d,0),target=board_port_reference(d,1);
    adapter_assert(!wire_connect(d,ap[1],bp[0])&&array_length(d.wires)==0,"different socket types cannot connect directly");
    adapter_assert(wire_connect(d,source,ap[0])&&wire_connect(d,ap[1],bp[1])&&wire_connect(d,bp[0],target),"actual adapter chain bridges both types");
    adapter_assert(d.circuit_connected&&a.circuit_powered&&b.circuit_powered,"power passes through mixed-type adapter internals");
    for(var k=0;k<array_length(keys);++k) adapter_assert(bal_stat(d.current_stats,keys[k])==bal_stat(d.stats_base,keys[k]),"connected adapters have no stat effect");
    module_detach(a);instance_destroy(a);
    adapter_assert(!d.circuit_connected&&array_length(d.wires)==1,"removing adapter breaks chain and cleans its wires");
    module_detach(b);instance_destroy(b);campaign_table(g);
    var cfg=lab_defaults();lab_sync_game(cfg);
    adapter_assert(array_length(cfg.modules)==16,"fresh lab catalog includes both adapters");
    array_resize(cfg.modules,14);cfg.tier2_catalog_added=true;cfg.modules[0].stats.energy="99";cfg.min.speed="4";
    lab_add_progression_modules(cfg);
    adapter_assert(array_length(cfg.modules)==16&&cfg.modules[0].stats.energy=="99"&&cfg.min.speed=="4","existing tier-two save gains adapters without resetting tuning");
    adapter_assert(lab_number(cfg.modules[14].drop_weight)==0&&lab_number(cfg.modules[15].drop_weight)==0&&cfg.modules[14].adapter_bonus,"lab keeps bonus adapters outside weighted drops");
    array_resize(cfg.modules,15);lab_add_progression_modules(cfg);
    adapter_assert(array_length(cfg.modules)==15,"later intentional experiment deletion stays deleted");
    show_debug_message("ADAPTER_TEST_RESULT passes="+string(global.adapter_passes)+" failures=0");
}
