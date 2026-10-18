if (sprite_exists(sprite_index)) draw_self();
else {
    draw_set_color(c_white);
    draw_rectangle(x-half_w,y-half_h,x+half_w,y+half_h,false);
    draw_set_color(c_white);
}
