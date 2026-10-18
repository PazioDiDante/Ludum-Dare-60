draw_set_alpha(1);
draw_set_color(make_color_rgb(25,31,44));
draw_roundrect(x-half_w,y-half_h,x+half_w,y+half_h,false);
if (!cover_open) {
    device_cover_draw(id);
} else {
    if (sprite_exists(board_sprite))
        draw_sprite_ext(board_sprite,0,board_x+sprite_get_xoffset(board_sprite)*draw_scale,board_y+sprite_get_yoffset(board_sprite)*draw_scale,draw_scale,draw_scale,0,c_white,1);
    for (var row = 0; row < rows; ++row) {
        for (var col = 0; col < cols; ++col) {
            if (!board_shape[row][col]) continue;
            var px = board_x+col*cell_size, py = board_y+row*cell_size;
            if (!sprite_exists(board_sprite)) {
                draw_set_color(make_color_rgb(25,65,50));
                draw_rectangle(px,py,px+cell_size,py+cell_size,false);
            }
            draw_set_color(make_color_rgb(70,115,90));
            draw_rectangle(px,py,px+cell_size,py+cell_size,true);
        }
    }
}
draw_set_color(c_white);
