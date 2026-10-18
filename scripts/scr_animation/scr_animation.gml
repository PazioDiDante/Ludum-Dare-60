// Called once in End Step, including table mode where devices are hidden.
function device_visual_tick(_dt) {
    if (global.mode == GameMode.Pause || !window_has_focus()) return;
    var seconds = max(0,_dt);
    with (par_device) {
        if (global.mode == GameMode.Menu)
            arrival_progress = min(1,arrival_progress+seconds/arrival_seconds);
        // Returning to the table preserves the lid's progress until reopening.
        if (visible && cover_open)
            cover_flight_progress = min(1,cover_flight_progress+seconds/cover_flight_seconds);
    }
}

// Draw the same lid closed or in flight, rotating around its visual centre.
function device_cover_draw(_d) {
    var eased = _d.cover_open ? sqr(_d.cover_flight_progress) : 0;
    var alpha = 1-eased;
    if (alpha <= 0) return;
    var cx = _d.x, cy = _d.y-_d.cover_flight_distance*eased;
    var angle = _d.cover_flight_angle*eased;
    var cosine = dcos(angle), sine = dsin(angle);
    var sprite = _d.cover_sprite;
    if (sprite_exists(sprite)) {
        var scale = min((_d.half_w*2-20)/sprite_get_width(sprite),(_d.half_h*2-20)/sprite_get_height(sprite));
        if (scale >= 1) scale = floor(scale);
        var ox = (sprite_get_xoffset(sprite)-sprite_get_width(sprite)/2)*scale;
        var oy = (sprite_get_yoffset(sprite)-sprite_get_height(sprite)/2)*scale;
        draw_sprite_ext(sprite,0,cx+ox*cosine+oy*sine,cy-ox*sine+oy*cosine,scale,scale,angle,c_white,alpha);
    } else {
        // Preserve the rounded fallback cover, including its centre detail.
        var world = matrix_get(matrix_world);
        var transform = matrix_build(cx,cy,0,0,0,angle,1,1,1);
        matrix_set(matrix_world,matrix_multiply(transform,world));
        draw_set_alpha(alpha);
        draw_set_color(make_color_rgb(67,78,96));
        draw_roundrect(-_d.half_w+10,-_d.half_h+10,_d.half_w-10,_d.half_h-10,false);
        draw_set_color(make_color_rgb(130,145,160));
        draw_rectangle(-46,-60,46,60,true);
        matrix_set(matrix_world,world);
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
