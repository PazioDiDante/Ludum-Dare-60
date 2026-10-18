campaign_gui_draw(id);
generator_draw(id);
robots_draw(id);
draw_set_alpha(1); draw_set_font(game_font_default());
draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_color(c_white);
if (game_running()) {
    draw_set_color(make_color_rgb(65,75,95)); draw_rectangle((room_width-120),16,(room_width-24),50,false);
    draw_set_color(c_white); draw_text((room_width-104),23,"Pause");
}
if (global.mode == GameMode.Pause) {
    draw_set_color(c_black); draw_set_alpha(0.85); draw_rectangle(240,175,720,430,false);
    draw_set_alpha(1); draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(480,205,"PAUSED");
    var labels = ["Resume","Table"];
    for (var i = 0; i < array_length(labels); ++i) {
        var r = ui_item_rect(i);
        draw_set_color(i == menu_index ? make_color_rgb(95,105,130) : make_color_rgb(45,50,65));
        draw_rectangle(r[0],r[1],r[2],r[3],false);
        draw_set_color(c_white); draw_text(480,r[1]+8,labels[i]);
    }
}
draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_color(c_white); draw_set_alpha(1);
