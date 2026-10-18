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
    array_sort(out,function(_a,_b){return _a.port_type-_b.port_type;});
    return out;
}
function adapter_tests() {
    global.adapter_passes=0;
    var g=instance_find(obj_game,0),types=[obj_module_adapter,obj_module_adapter_corner],keys=device_stat_keys();
    var original_index=g.order_index,pool=g.module_types;
    for(var t=0;t<2;++t) {
        var probe=instance_create_depth(-10000,-10000,0,types[t]);
        adapter_assert(probe.drop_weight==0&&probe.unlock_after_orders==3,"bonus-only adapter unlocked at tier two");
        for(var k=0;k<array_length(keys);++k) adapter_assert(device_stat_value(probe.stats,keys[k])==0,"every adapter stat including mass is zero");
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
    var parts=[a,b];
    for(var i=0;i<array_length(parts);++i) {
        var item=parts[i],placed=false;
        for(var turn=0;turn<4&&!placed;++turn) {
            for(var row=0;row<d.rows&&!placed;++row) for(var col=0;col<d.cols&&!placed;++col)
                placed=board_place(item,col,row);
            if(!placed) {item.shape=orders_rotate(item.shape);item.rotation_steps=(item.rotation_steps+1) mod 4;}
        }
        adapter_assert(placed,"adapter fits the current generator board");
    }
    var ap=adapter_ports(a),bp=adapter_ports(b),source=board_port_reference(d,0),target=board_port_reference(d,1);
    adapter_assert(!wire_connect(d,ap[1],bp[0])&&array_length(d.wires)==0,"different socket types cannot connect directly");
    adapter_assert(wire_connect(d,source,ap[0])&&wire_connect(d,ap[1],bp[1])&&wire_connect(d,bp[0],target),"actual adapter chain bridges both types");
    adapter_assert(d.circuit_connected&&a.circuit_powered&&b.circuit_powered,"power passes through mixed-type adapter internals");
    for(var k=0;k<array_length(keys);++k) adapter_assert(device_stat_value(d.current_stats,keys[k])==device_stat_value(d.stats_base,keys[k]),"connected adapters have no stat effect");
    module_detach(a);instance_destroy(a);
    adapter_assert(!d.circuit_connected&&array_length(d.wires)==1,"removing adapter breaks chain and cleans its wires");
    module_detach(b);instance_destroy(b);campaign_table(g);
    show_debug_message("ADAPTER_TEST_RESULT passes="+string(global.adapter_passes)+" failures=0");
}
