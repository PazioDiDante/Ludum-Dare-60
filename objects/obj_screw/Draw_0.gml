draw_set_alpha(1);
draw_set_color(unscrewing ? c_aqua : (global.hover_target == id ? c_yellow : make_color_rgb(190,200,215)));
draw_circle(x,y,13,false);
draw_set_color(make_color_rgb(45,50,60));
var angle=unscrewing?(unscrew_seconds-unscrew_remaining)*240:0;
var dx=lengthdir_x(7,angle),dy=lengthdir_y(7,angle);
draw_line(x-dx,y-dy,x+dx,y+dy);
draw_line(x-dy,y+dx,x+dy,y-dx);
if(unscrewing) {
    draw_set_color(c_dkgray);draw_rectangle(x-20,y+18,x+20,y+22,false);
    draw_set_color(c_aqua);draw_rectangle(x-20,y+18,x-20+40*(1-unscrew_remaining/unscrew_seconds),y+22,false);
}
draw_set_color(c_white);
