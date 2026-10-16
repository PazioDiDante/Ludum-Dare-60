event_inherited();
blocks_motion = false;
interaction_enabled = true;
interaction_label = "Interact";
can_interact = function(_actor) { return interaction_enabled && instance_exists(_actor); };
interact = function(_actor) { return false; };
