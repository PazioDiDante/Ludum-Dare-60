// Axis-aligned rectangles with centered origin; independent of sprite masks.
// Call from an actor instance. Stationary solids; x first, then y, so walls slide.
// Sweep the full distance instead of testing only the destination (no tunneling).
function actor_move(_dx, _dy) {
    var n = instance_number(par_solid);
    for (var i = 0; i < n; ++i) {
        var s = instance_find(par_solid, i);
        if (s == id || !s.blocks_motion) continue;
        if (y + half_h <= s.y - s.half_h || y - half_h >= s.y + s.half_h) continue;
        var gap;
        if (_dx > 0 && x + half_w <= s.x - s.half_w) {
            gap = s.x - s.half_w - (x + half_w);
            _dx = min(_dx, gap);
        } else if (_dx < 0 && x - half_w >= s.x + s.half_w) {
            gap = s.x + s.half_w - (x - half_w);
            _dx = max(_dx, gap);
        }
    }
    x += _dx;
    for (var i = 0; i < n; ++i) {
        var s = instance_find(par_solid, i);
        if (s == id || !s.blocks_motion) continue;
        if (x + half_w <= s.x - s.half_w || x - half_w >= s.x + s.half_w) continue;
        var gap;
        if (_dy > 0 && y + half_h <= s.y - s.half_h) {
            gap = s.y - s.half_h - (y + half_h);
            _dy = min(_dy, gap);
        } else if (_dy < 0 && y - half_h >= s.y + s.half_h) {
            gap = s.y + s.half_h - (y - half_h);
            _dy = max(_dy, gap);
        }
    }
    y += _dy;
}
function segment_hits_box(_x1, _y1, _x2, _y2, _s) {
    var t0 = 0, t1 = 1;
    var origins = [_x1, _y1];
    var deltas = [_x2 - _x1, _y2 - _y1];
    var lo = [_s.x - _s.half_w, _s.y - _s.half_h];
    var hi = [_s.x + _s.half_w, _s.y + _s.half_h];
    for (var i = 0; i < 2; ++i) {
        if (abs(deltas[i]) < 0.000001) {
            if (origins[i] < lo[i] || origins[i] > hi[i]) return false;
        } else {
            var a = (lo[i] - origins[i]) / deltas[i];
            var b = (hi[i] - origins[i]) / deltas[i];
            t0 = max(t0, min(a, b));
            t1 = min(t1, max(a, b));
            if (t0 > t1) return false;
        }
    }
    return true;
}
function interaction_find(_actor, _range) {
    var best = noone, best_dist = _range + 1;
    for (var i = 0; i < instance_number(par_interactable); ++i) {
        var target = instance_find(par_interactable, i);
        if (!target.can_interact(_actor)) continue;
        var dist = point_distance(_actor.x, _actor.y, target.x, target.y);
        if (dist > _range || dist >= best_dist) continue;
        var blocked = false;
        for (var j = 0; j < instance_number(par_solid); ++j) {
            var s = instance_find(par_solid, j);
            if (s == target || s == _actor || !s.blocks_motion) continue;
            if (segment_hits_box(_actor.x, _actor.y, target.x, target.y, s)) {
                blocked = true;
                break;
            }
        }
        if (!blocked) { best = target; best_dist = dist; }
    }
    return best;
}
