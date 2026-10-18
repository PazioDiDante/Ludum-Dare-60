// Standalone suite: run starter_device_tests() in an isolated project copy.
function starter_assert(_ok,_message) {
    if(!_ok) throw "STARTER_TEST_FAILURE: "+_message;
    global.starter_passes++;
}
function starter_parts(_d) {
    var result=[];
    for(var i=0;i<array_length(_d.children);++i) {
        var item=_d.children[i];
        if(instance_exists(item)&&object_is_ancestor(item.object_index,par_module)&&item.device==_d)
            array_push(result,item);
    }
    return result;
}
function starter_check_loot(_d,_expected) {
    _d.open_cover();
    var parts=starter_parts(_d),actual=[];
    for(var i=0;i<array_length(parts);++i) {
        array_push(actual,parts[i].object_index);
        starter_assert(board_can_place(parts[i],parts[i].grid_col,parts[i].grid_row),"starter part fits without overlap");
    }
    array_sort(actual,true);array_sort(_expected,true);
    starter_assert(json_stringify(actual)==json_stringify(_expected),"exact starter contents");
    starter_assert(_d.requested_modules==array_length(_expected)&&_d.placed_modules==array_length(_expected),"all starter modules placed");
    var count=instance_number(par_module);_d.open_cover();
    starter_assert(instance_number(par_module)==count,"reopening cannot duplicate starter loot");
    return parts;
}
function starter_device_tests() {
    global.starter_passes=0;
    var g=instance_find(obj_game,0);
    starter_assert(array_length(g.table_devices)==1&&g.money==50&&global.mode==GameMode.Menu,"one free closed donor on the initial table");
    starter_assert(!g.table_devices[0].cover_open&&g.campaign_devices_created==1,"initial donor reserves first contents before opening");
    instance_destroy(g.table_devices[0]);g.table_devices=[];
    var first_types=[obj_module_battery,obj_module_battery,obj_module_cooler,obj_module_stabilizer];
    var second_types=[obj_module_double_battery,obj_module_coil,obj_module_universal];
    // Both boards must fit both sets, including opening the purchased one first.
    var device_types=[obj_remote,obj_radio];
    for(var k=0;k<2;++k) {
        g.campaign_devices_created=0;g.device_types=[device_types[k]];g.money=50;
        var first=campaign_add_device(g);
        starter_assert(campaign_buy(g)&&g.money==25,"second donor retains normal purchase price");
        var second=g.table_devices[1];
        var modules=g.module_types;g.module_types=[];
        var second_parts=starter_check_loot(second,second_types);
        var first_parts=starter_check_loot(first,first_types);
        g.module_types=modules;
        starter_assert(g.campaign_devices_created==2,"opening order does not change acquisition sequence");
        if(k==0) {
            // Assemble all seven real parts into the real first order.
            var order=g.order_device,parts=array_concat(first_parts,second_parts);
            var previous=board_port_reference(order,0);
            for(var i=0;i<array_length(parts);++i) {
                var item=parts[i];module_detach(item);item.device=order;
                var placed=false;
                for(var row=0;row<order.rows&&!placed;++row) for(var col=0;col<order.cols&&!placed;++col)
                    placed=board_place(item,col,row);
                starter_assert(placed,"starter module fits first order");
                array_push(order.children,item);
                var ports=[];
                for(var row=0;row<array_length(item.shape);++row) for(var col=0;col<array_length(item.shape[row]);++col) {
                    var directions=cell_directions(item.shape[row][col]);
                    for(var p=0;p<array_length(directions);++p) array_push(ports,port_reference(item,col,row,directions[p]));
                }
                starter_assert(array_length(ports)==2&&wire_connect(order,previous,ports[0]),"starter modules form connected chain");
                previous=ports[1];
            }
            starter_assert(wire_connect(order,previous,board_port_reference(order,1)),"starter chain connects both order contacts");
            device_stats_update(order);
            starter_assert(order.requirements_met,"the two guaranteed sets satisfy the actual first order");
            starter_assert(order.current_stats.energy==9&&order.current_stats.heat==4&&order.current_stats.stability==3&&order.current_stats.weight==7,"expected first-order totals");
        }
        instance_destroy(first);instance_destroy(second);g.table_devices=[];
        g.money=0;
        starter_assert(!campaign_buy(g)&&g.campaign_devices_created==2,"failed purchase cannot advance sequence");
        g.money=25;g.module_types=[obj_module_universal];
        starter_assert(campaign_buy(g),"third donor can be purchased");
        var third=g.table_devices[0];
        starter_assert(array_length(third.campaign_loot_types)==0,"third donor uses normal weighted loot");
        third.open_cover();var parts=starter_parts(third);
        starter_assert(array_length(parts)>=2&&array_length(parts)<=3,"normal loot has two or three modules");
        for(var i=0;i<array_length(parts);++i) starter_assert(parts[i].object_index==obj_module_universal,"normal loot follows module pool");
        instance_destroy(third);g.table_devices=[];g.module_types=modules;
    }
    show_debug_message("STARTER_TEST_RESULT passes="+string(global.starter_passes)+" failures=0");
    game_end();
}
