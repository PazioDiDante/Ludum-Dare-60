if (!game_running()) exit;
var mx = input_axis(Action.Left, Action.Right);
var my = input_axis(Action.Up, Action.Down);
var magnitude = sqrt(mx*mx + my*my);
if (magnitude > 0) {
    actor_move(mx / magnitude * move_speed * global.dt,
               my / magnitude * move_speed * global.dt);
}
anim_tick(global.dt);
interaction_target = interaction_find(id, interaction_range);
if (input_pressed(Action.Interact) && instance_exists(interaction_target)) {
    interaction_target.interact(id);
}
