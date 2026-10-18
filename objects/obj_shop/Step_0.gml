if(!instance_exists(game)) {instance_destroy();exit;}
if(global.mode!=GameMode.Menu) {open=false;exit;}
page_size=max(1,floor((display_get_gui_height()-158)/168));
var count=array_length(shop_items(id));
if(open) {
    if(input_pressed(Action.Cancel) || input_pressed(Action.Pause)) {open=false;game.pointer_ready=false;sfx_play(snd_click);}
    var px=device_mouse_x_to_gui(0),py=device_mouse_y_to_gui(0);
    if(campaign_hit(px,py,shop_panel_rect())) scroll+=mouse_wheel_down()-mouse_wheel_up();
}
scroll=clamp(scroll,0,max(0,count-page_size));
