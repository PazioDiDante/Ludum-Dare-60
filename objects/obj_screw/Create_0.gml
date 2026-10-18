event_inherited();
device = noone;
interaction_label = "Cover screw";
primary_hint = "Unscrew";
unscrew_base_seconds=2;unscrew_seconds=unscrew_base_seconds;unscrew_remaining=0;unscrewing=false;
can_interact = function() { return interaction_enabled && instance_exists(device); };
hit_test = function(_px,_py) { return point_distance(x,y,_px,_py) <= 15; };
on_primary = function() {
    if (!can_interact()) return false;
    return screw_start(id);
};
on_secondary = function() { notice_show("LMB: remove screw."); return true; };
