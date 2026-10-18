// One click goes to the topmost item (smaller depth). Avoid overlapping items at equal depth.
function pointer_find(_px, _py) {
    var best = noone;
    for (var i = 0; i < instance_number(par_interactable); ++i) {
        var item = instance_find(par_interactable, i);
        if (!item.visible || !item.can_interact() || !item.hit_test(_px, _py)) continue;
        if (best == noone) { best = item; continue; }
        if (item.depth < best.depth) best = item;
    }
    return best;
}
function pointer_dispatch(_target, _button) {
    if (!game_running() || !instance_exists(_target)) return false;
    if (!_target.can_interact()) return false;
    if (_button == mb_left) return _target.on_primary();
    if (_button == mb_right) return _target.on_secondary();
    return false;
}
function notice_show(_text) { global.notice = _text; global.notice_time = 3; }
// GUI rectangles are shared by rendering and hit testing.
function ui_item_rect(_index) { return [330, 250 + _index * 42, 630, 284 + _index * 42]; }
function ui_item_at(_px, _py, _count) {
    for (var i = 0; i < _count; ++i) {
        var r = ui_item_rect(i);
        if (_px >= r[0] && _px <= r[2] && _py >= r[1] && _py <= r[3]) return i;
    }
    return -1;
}
