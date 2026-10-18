display_set_gui_size(1280,720);window_set_size(1280,720);
font=game_font_create(16);
draw_set_font(font);
cfg=manual_defaults();run=undefined;dirty=false;
if(variable_global_exists("manual_state")) {
    cfg=global.manual_state.cfg;run=global.manual_state.run;dirty=global.manual_state.dirty;
}
tab=is_undefined(run)?0:2;selected=0;page=0;inv_page=0;combo_page=0;
focus=-1;fields=[];buttons=[];ticks=0;notice="";
manual_rebuild(id);
