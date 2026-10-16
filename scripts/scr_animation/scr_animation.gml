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
