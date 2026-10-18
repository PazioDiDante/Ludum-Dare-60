event_inherited();
interaction_enabled = true;
interaction_label = "Item";
primary_hint = "Use";
secondary_hint = "Inspect";
can_interact = function() { return interaction_enabled; };
hit_test = function(_px, _py) {
    return _px >= x-half_w && _px <= x+half_w && _py >= y-half_h && _py <= y+half_h;
};
on_primary = function() { return false; };
on_secondary = function() { notice_show(interaction_label); return true; };
