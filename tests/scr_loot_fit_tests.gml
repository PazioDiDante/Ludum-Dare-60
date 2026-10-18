function loot_fit_assert(_ok,_message) {
    if(!_ok) throw "LOOT_FIT_FAILURE: "+_message;
    global.loot_fit_passes++;
}
function loot_fit_tests() {
    global.loot_fit_passes=0;
    var g=instance_find(obj_game,0);g.module_types=[obj_module_battery];
    var before=instance_number(par_module),inventory_before=json_stringify(g.inventory);
    var tiny=campaign_create_device(obj_remote);tiny.campaign=true;
    tiny.rows=1;tiny.cols=1;tiny.board_shape=[[1]];tiny.board=[[noone]];
    tiny.open_cover();
    loot_fit_assert(tiny.requested_modules>=2&&tiny.placed_modules==0,"oversized generated parts are not placed");
    loot_fit_assert(instance_number(par_module)==before&&json_stringify(g.inventory)==inventory_before,"failed parts neither survive nor enter inventory");
    instance_destroy(tiny);
    var small=campaign_create_device(obj_remote);small.campaign=true;
    small.rows=1;small.cols=2;small.board_shape=[[1,1]];small.board=[[noone,noone]];
    small.open_cover();
    loot_fit_assert(small.placed_modules==1&&instance_number(par_module)==before+1,"fitting part remains on board, overflow is discarded");
    loot_fit_assert(json_stringify(g.inventory)==inventory_before,"partial generation never gives inventory overflow");
    small.open_cover();
    loot_fit_assert(instance_number(par_module)==before+1,"reopening cannot reroll or duplicate parts");
    instance_destroy(small);
    loot_fit_assert(instance_number(par_module)==before,"device cleanup leaves no orphaned failed modules");
    show_debug_message("LOOT_FIT_RESULT passes="+string(global.loot_fit_passes)+" failures=0");game_end();
}
