// Explicit animation clock: image_speed stays zero. Call anim_tick once per active Step.
function anim_init() {
    image_speed = 0;
    anim_fps = 0; anim_loop = true; anim_done = false;
    anim_cursor = 0; anim_previous = 0; anim_advance = 0; anim_ended = false;
}
function anim_set(_sprite, _fps = 8, _loop = true, _restart = false) {
    if (!sprite_exists(_sprite)) return false;
    if (sprite_index == _sprite && !_restart) {
        anim_fps = max(0, _fps); anim_loop = _loop;
        return true;
    }
    sprite_index = _sprite;
    image_index = 0; image_speed = 0;
    anim_cursor = 0; anim_previous = 0; anim_advance = 0;
    anim_fps = max(0, _fps); anim_loop = _loop;
    anim_done = false; anim_ended = false;
    return true;
}
function anim_tick(_dt) {
    anim_ended = false; anim_advance = 0;
    if (!sprite_exists(sprite_index)) return;
    var count = sprite_get_number(sprite_index);
    anim_previous = anim_cursor;
    if (anim_done || count <= 0) return;
    anim_advance = anim_fps * max(0, _dt);
    var next_frame = anim_cursor + anim_advance;
    anim_ended = next_frame >= count;
    if (anim_loop) {
        anim_cursor = next_frame mod count;
        image_index = anim_cursor;
    }
    else {
        anim_cursor = min(count, next_frame);
        image_index = min(count - 1, anim_cursor);
        if (anim_ended) anim_done = true;
    }
}
function anim_frame() { return floor(image_index); }
function anim_last() {
    return sprite_exists(sprite_index) && anim_frame() == sprite_get_number(sprite_index) - 1;
}
// Crossing check catches skipped frames; true at most once per Step, even on many loops.
function anim_entered(_frame) {
    if (!sprite_exists(sprite_index) || anim_advance <= 0) return false;
    var count = sprite_get_number(sprite_index);
    if (_frame < 0 || _frame >= count) return false;
    if (!anim_loop) return anim_previous < _frame && anim_previous + anim_advance >= _frame;
    var distance = (_frame - anim_previous + count) mod count;
    if (distance == 0) distance = count;
    return anim_advance >= distance;
}

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
