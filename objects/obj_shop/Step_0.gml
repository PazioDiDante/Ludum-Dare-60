if(!instance_exists(game)) {instance_destroy();exit;}
if(global.mode!=GameMode.Menu) {open=false;exit;}
shop_items(id);
if(open) {
    if(input_pressed(Action.Cancel) || input_pressed(Action.Pause)) {open=false;game.pointer_ready=false;sfx_play(snd_click);}
    var px=device_mouse_x_to_gui(0),py=device_mouse_y_to_gui(0);
    if(campaign_hit(px,py,shop_panel_rect())) shop_scroll(id,mouse_wheel_down()-mouse_wheel_up());
}
