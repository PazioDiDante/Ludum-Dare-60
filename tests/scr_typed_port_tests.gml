// Attach only in an isolated copy; run after obj_game initialization.
function typed_port_assert(_ok,_label) {
    if(!_ok) throw "TYPED_PORT_FAILURE: "+_label;
    global.typed_port_passes++;
}
function typed_port_fixture(_d,_shape,_col,_row) {
    var item=instance_create_depth(0,0,-10,par_module);item.device=_d;item.shape=_shape;
    array_push(_d.children,item);
    typed_port_assert(board_place(item,_col,_row),"typed fixture fits");
    return item;
}
function typed_port_tests() {
    global.typed_port_passes=0;
    typed_port_assert(cell_port_letters("LRD_1")=="LRD"&&cell_port_type("LRD_1")==1,"three sides, type one");
    typed_port_assert(cell_port_letters("R_2")=="R"&&cell_port_type("R_2")==2,"single side, type two");
    typed_port_assert(array_length(cell_directions("LRD_1"))==3,"suffix does not add directions");
    typed_port_assert(cell_port_letters("  drll_12 ")=="LRD"&&cell_port_type("drll_12")==12,"normalization and arbitrary type numbers");
    typed_port_assert(cell_port_type(Cell.LRD)==1&&cell_port_type("LR")==1,"legacy cells default to type one");
    typed_port_assert(cell_port_type(0)==0&&cell_port_type(1)==0,"empty and body cells are not ports");
    var invalid=["LR_","LR_0","LR_-1","LR_1.5","LR_1_2","LR_a","X_2","LRD_1 R_2",""];
    for(var i=0;i<array_length(invalid);++i)
        typed_port_assert(array_length(cell_directions(invalid[i]))==0&&cell_port_type(invalid[i])==0,"invalid cell creates no contacts: "+invalid[i]);
    var rotated="LRD_12";
    repeat(4) {rotated=cell_rotate(rotated);typed_port_assert(cell_port_type(rotated)==12,"rotation retains type");}
    typed_port_assert(rotated=="LRD_12"&&cell_rotate("R_2")=="D_2","four-turn roundtrip and clockwise direction");
    var g=instance_find(obj_game,0),d=g.generator;campaign_open(g,d);
    d.board_ports=[{col:0,row:0,direction:Cell.L,port_type:1},{col:9,row:6,direction:Cell.R,port_type:1}];
    var a=typed_port_fixture(d,[["L_1","R_2"]],2,2);
    var b=typed_port_fixture(d,[["L_2","R_1"]],6,2);
    var c=typed_port_fixture(d,[["LRD_1","R_2"]],3,4);
    var source=board_port_reference(d,0),target=board_port_reference(d,1);
    var a1=port_reference(a,0,0),a2=port_reference(a,1,0),b2=port_reference(b,0,0),b1=port_reference(b,1,0);
    typed_port_assert(port_current(a1).port_type==1&&port_current(a2).port_type==2,"current ports expose cell types");
    typed_port_assert(!wire_connect(d,a1,b2)&&array_length(d.wires)==0,"different types cannot connect");
    typed_port_assert(wire_connect(d,source,a1)&&wire_connect(d,a2,b2)&&wire_connect(d,b1,target),"mixed-type module chain uses matching cable ends");
    typed_port_assert(d.circuit_connected&&a.circuit_powered&&b.circuit_powered,"typed chain powers modules and closes circuit");
    var wires=array_length(d.wires);
    typed_port_assert(!wire_connect(d,port_reference(c,1,0),a1,true)&&array_length(d.wires)==wires&&wire_for_port(d,source)>=0,"incompatible replacement preserves existing target wire");
    wire_click(d,port_reference(c,1,0));
    var before=array_length(d.wires);
    typed_port_assert(!wire_click(d,a1)&&!is_undefined(d.wire_start)&&array_length(d.wires)==before,"manual mismatch keeps draft and old wire");
    var position=port_current(a1),snap=port_find_snap(d,position.x,position.y);
    typed_port_assert(is_undefined(snap)||ports_compatible(d.wire_start,snap),"snapping excludes incompatible contacts");
    wire_cancel(d);
    typed_port_assert(board_pick(a,a.x+d.cell_size/2,a.y+d.cell_size/2),"pick typed module");
    repeat(4) {
        typed_port_assert(board_rotate(d),"rotate wired typed module");
        typed_port_assert(port_current(a1).port_type==1&&port_current(a2).port_type==2,"stable references retain types after rotation");
        typed_port_assert(port_equal(port_reference(a,port_current(a2).col,port_current(a2).row,port_current(a2).direction),a2),"rotated hit reference retains identity");
    }
    typed_port_assert(board_cancel(d)&&a.shape[0][1]=="R_2"&&d.circuit_connected,"cancel restores typed shape and connected wiring");
    var prior=port_reference(c,1,0);c.shape[0][1]="R_3";
    typed_port_assert(is_undefined(port_current(prior))&&!port_equal(prior,port_reference(c,1,0)),"changed cell type invalidates old reference");
    c.shape[0][1]="R_2";
    var sf=surface_create(1280,720);surface_set_target(sf);draw_clear(c_black);
    draw_sprite_stretched(spr_table,0,0,0,1280,720);
    with(d) event_perform(ev_draw,0);
    module_draw_held(a);module_draw_held(b);module_draw_held(c);board_ports_draw(d);wire_draw(d);
    surface_reset_target();surface_save(sf,"typed-ports-preview.png");surface_free(sf);
    typed_port_assert(port_type_color(1)!=port_type_color(2),"types have distinct default colours");
    wire_remove_module(c);wire_remove_module(a);wire_remove_module(b);
    d.board_port_types=[2,2];board_ports_generate(d);
    typed_port_assert(port_current(board_port_reference(d,0)).port_type==2,"board contact types are configurable");
    typed_port_assert(!wire_connect(d,board_port_reference(d,0),a1)&&wire_connect(d,board_port_reference(d,0),a2),"board contacts follow type compatibility");
    // Automatic donor wiring must never create a mismatched wire.
    var donor=instance_create_depth(850,375,0,par_device);
    donor.module_min=0;donor.module_max=0;donor.board_port_types=[2,2];
    donor.board_shape=[[1,1,1,1,1,1]];with(donor) device_build();
    typed_port_fixture(donor,[["L_1","R_1"]],0,0);
    typed_port_fixture(donor,[["L_2","R_2"]],3,0);
    device_wire_generated(donor);
    typed_port_assert(array_length(donor.wires)==2&&donor.circuit_connected&&donor.powered_count==1,"generated wiring skips incompatible module and closes compatible path");
    for(var i=0;i<array_length(donor.wires);++i)
        typed_port_assert(ports_compatible(donor.wires[i].a,donor.wires[i].b),"all generated wire ends have matching types");
    instance_destroy(donor);
    show_debug_message("TYPED_PORT_RESULT passes="+string(global.typed_port_passes)+" failures=0");
    game_end();
}
