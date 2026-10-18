display_set_gui_size(1280,720);
window_set_size(1280,720);
font = game_font_create(16);
// The pixel font has Latin glyphs only. Keep custom Russian experiment names legible.
var old_aa=font_add_get_enable_aa();
font_add_enable_aa(false);
cyrillic_font=font_add("Arial",16,false,false,32,1279);
font_add_enable_aa(old_aa);
draw_set_font(font);
cfg = lab_defaults();
tab=0;selected=0;module_page=0;focus=-1;fields=[];buttons=[];
ticks=0;dirty=false;confirm_reset=false;notice="";job=undefined;report=[];
if(variable_global_exists("balance_config")) cfg=global.balance_config;
else if(file_exists("balance_settings.json")) lab_load(id);
ana_ui_init(id);
lab_rebuild(id);
