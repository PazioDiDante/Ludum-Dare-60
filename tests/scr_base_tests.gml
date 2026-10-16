
function base_assert(_ok, _label) {
    if (!_ok) { global.test_failures++; show_debug_message("FAIL: " + _label); }
    else { global.test_passes++; show_debug_message("PASS: " + _label); }
}
function base_tests() {
    global.test_keys = array_create(256, false); global.test_failures = 0; global.test_passes = 0;
    base_test_release(ord("E")); base_test_release(vk_space);
    input_init(); input_update(base_test_key);
    base_assert(!input_down(Action.Interact), "input initially idle");
    base_test_press(ord("E")); input_update(base_test_key);
    base_assert(input_down(Action.Interact) && input_pressed(Action.Interact), "first key press");
    base_test_press(vk_space); input_update(base_test_key);
    base_assert(input_down(Action.Interact) && !input_pressed(Action.Interact), "second key no duplicate press");
    base_test_release(ord("E")); input_update(base_test_key);
    base_assert(input_down(Action.Interact) && !input_released(Action.Interact), "one key released keeps action down");
    base_test_release(vk_space); input_update(base_test_key);
    base_assert(!input_down(Action.Interact) && input_released(Action.Interact), "last key releases action");
    input_update(base_test_key); base_assert(!input_released(Action.Interact), "release pulse lasts one update");
    base_test_press(ord("Q")); input_bind(Action.Interact, [ord("Q")], base_test_key); input_update(base_test_key);
    base_assert(input_down(Action.Interact) && !input_pressed(Action.Interact), "rebind held key no phantom press");
    base_test_release(ord("Q")); input_init();
    var player = instance_find(obj_player, 0);
    with (player) {
        x = 200; y = 200; actor_move(1000,0);
        base_assert(abs(x-398)<0.001, "sweep stops at wall without tunneling");
        actor_move(20,20);
        base_assert(abs(x-398)<0.001 && abs(y-220)<0.001, "slide along wall");
        x = 500; y = 200; actor_move(-1000,0);
        base_assert(abs(x-442)<0.001, "negative horizontal sweep");
        x = 600; y = 200; actor_move(0,1000);
        base_assert(abs(y-378)<0.001, "vertical sweep");
        x = 200; y = 200; actor_move(0,-1000);
        base_assert(abs(y-122)<0.001, "negative vertical sweep");
        x = 380; y = 260;
        base_assert(interaction_find(id,75)==noone, "interaction blocked by wall");
        x = 270; y = 280;
        var target = interaction_find(id,64);
        base_assert(instance_exists(target), "nearest interaction found");
        target.interact(id);
        base_assert(target.is_on, "method bound to target");
        target.interaction_enabled = false;
        base_assert(interaction_find(id,64)==noone, "disabled interaction excluded");
        target.interaction_enabled = true;
        global.mode = GameMode.Pause;
        base_test_press(ord("D")); input_update(base_test_key);
        var old_x = x;
        event_perform(ev_step,ev_step_normal);
        base_assert(x==old_x, "paused player does not move");
        global.mode = GameMode.Play;
        global.dt = 1/60;
        x=200; y=200;
        base_test_press(ord("S")); input_update(base_test_key);
        event_perform(ev_step,ev_step_normal);
        base_assert(abs(point_distance(200,200,x,y)-3)<0.001, "normalized diagonal speed");
        base_test_release(ord("D")); base_test_release(ord("S")); input_update(base_test_key);
        var surf = surface_create(8,8);
        surface_set_target(surf); draw_clear(c_white); surface_reset_target();
        var spr = sprite_create_from_surface(surf,0,0,8,8,false,false,4,4);
        repeat (3) sprite_add_from_surface(spr,surf,0,0,8,8,false,false);
        surface_free(surf);
        anim_set(spr,4,false,true);
        repeat (7) anim_tick(0.125);
        base_assert(anim_last() && !anim_done, "last frame retains full duration");
        anim_tick(0.125);
        base_assert(anim_done && anim_ended, "one shot completes");
        anim_tick(0.125);
        base_assert(anim_done && !anim_ended, "end signal is one tick");
        anim_set(spr,4,true,true); anim_tick(0.6);
        base_assert(anim_entered(1) && anim_entered(2), "skipped frame crossing detected");
        anim_tick(0.5);
        base_assert(anim_entered(0) && anim_ended && anim_frame()==0, "loop crossing detected");
        anim_set(spr,4,true,false);
        base_assert(image_index>0, "same animation does not reset");
        anim_tick(2);
        base_assert(anim_entered(3), "multiple loops remain detectable");
        sprite_index=-1; sprite_delete(spr);
    }
    show_debug_message("BASE_TEST_RESULT passes="+string(global.test_passes)+" failures="+string(global.test_failures));
    game_end();
}

function base_test_key(_key) { return global.test_keys[_key]; }
function base_test_press(_key) { global.test_keys[_key] = true; }
function base_test_release(_key) { global.test_keys[_key] = false; }
