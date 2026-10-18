// Standalone isolated lab preview; lab_name_test_root is an absolute workspace folder.
function lab_name_assert(_ok,_label) {
    if(!_ok) throw "LAB_NAME_FAILURE: "+_label;
    global.lab_name_passes++;
}
function lab_name_unicode(_codes) {
    var text="";
    for(var i=0;i<array_length(_codes);++i) text+=chr(_codes[i]);
    return text;
}
function lab_name_tests(_ui) {
    global.lab_name_passes=0;
    var cfg=lab_defaults();lab_sync_game(cfg);
    // Unicode code points retain legacy-name and Cyrillic fallback coverage.
    var legacy_name=lab_name_unicode([1041,1072,1090,1072,1088,1077,1081,1082,1072]);
    var custom_name=lab_name_unicode([1052,1086,1081,32,1084,1086,1076,1091,1083,1100,32,1089,1082,1086,1088,1086,1089,1090,1080]);
    var yo_sample=lab_name_unicode([1025,1078,1080,1082,32,1080,32,1089,1082,1086,1088,1086,1089,1090,1100]);
    var stat_sample=lab_name_unicode([1057,1082,1086,1088,1086,1089,1090,1100,32,1080,32,1101,1092,1092,1077,1082,1090,1080,1074,1085,1086,1089,1090,1100]);
    var item=cfg.modules[0],expected=item.name;
    item.name=legacy_name;item.qty="7";item.drop_weight="0.25";item.stats.energy="-99";item.stats.speed="8";
    cfg.min.speed="12";cfg.slots="4";cfg.start_money="465";
    var custom={name:custom_name,qty:"2",drop_weight:"3",stats:{}};
    var keys=bal_keys();
    for(var i=0;i<array_length(keys);++i) struct_set(custom.stats,keys[i],"0");
    custom.stats.speed="5";array_push(cfg.modules,custom);
    var count=instance_number(par_module),seed=random_get_seed();
    lab_sync_names(cfg);
    lab_name_assert(item.name==expected,"legacy linked name refreshed from actual module");
    lab_name_assert(item.qty=="7"&&item.drop_weight=="0.25"&&item.stats.energy=="-99"&&item.stats.speed=="8","tuned inventory, drop weights and stats preserved");
    lab_name_assert(cfg.min.speed=="12"&&cfg.slots=="4"&&cfg.start_money=="465","order and economy preserved");
    lab_name_assert(custom.name==custom_name,"custom Cyrillic name retained");
    lab_name_assert(instance_number(par_module)==count&&random_get_seed()==seed,"name refresh leaves scene and gameplay RNG untouched");
    _ui.cfg=cfg;item.name=legacy_name;
    lab_save(_ui,lab_name_test_root+"/fixture.json");
    lab_load(_ui,lab_name_test_root+"/fixture.json");
    lab_name_assert(_ui.cfg.modules[0].name==expected,"loading an old file refreshes linked names");
    lab_name_assert(_ui.cfg.modules[0].stats.energy=="-99"&&_ui.cfg.modules[0].qty=="7"&&_ui.cfg.min.speed=="12","load migration changes no tuned values");
    _ui.cfg.modules[0].name=legacy_name;ana_ui_init(_ui);
    lab_name_assert(_ui.cfg.modules[0].name==expected,"returning with in-memory settings refreshes names");
    lab_name_assert(font_exists(_ui.cyrillic_font),"Cyrillic fallback font loaded");
    lab_name_assert(lab_text_font(_ui,"Battery")==_ui.font,"English retains pixel font");
    lab_name_assert(lab_text_font(_ui,yo_sample)==_ui.cyrillic_font,"Cyrillic including Yo selects fallback");
    draw_set_font(_ui.font);ana_text(24,130,stat_sample,600);
    lab_name_assert(draw_get_font()==_ui.font,"analysis text restores pixel font");
    _ui.tab=1;_ui.selected=array_length(_ui.cfg.modules)-1;_ui.module_page=0;
    lab_rebuild(_ui);_ui.notice="Cyrillic names + refreshed game names. Tuned values retained.";
}
function lab_name_test_draw(_ui) {
    if(_ui.ticks==2) lab_name_tests(_ui);
    if(_ui.ticks==5) screen_save(lab_name_test_root+"/preview.png");
    if(_ui.ticks==6) {
        show_debug_message("LAB_NAME_RESULT passes="+string(global.lab_name_passes)+" failures=0");
        game_end();
    }
}
