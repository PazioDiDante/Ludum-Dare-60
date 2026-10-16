enum Action { Left, Right, Up, Down, Interact, Confirm, Pause, Debug, Restart, Count }
enum GameMode { Menu, Play, Pause }

function input_init() {
    global.actions = array_create(Action.Count);
    for (var i = 0; i < Action.Count; ++i)
        global.actions[i] = { keys: [], down: false, pressed: false, released: false };
    input_bind(Action.Left, [ord("A"), vk_left]);
    input_bind(Action.Right, [ord("D"), vk_right]);
    input_bind(Action.Up, [ord("W"), vk_up]);
    input_bind(Action.Down, [ord("S"), vk_down]);
    input_bind(Action.Interact, [ord("E"), vk_space]);
    input_bind(Action.Confirm, [vk_enter]);
    input_bind(Action.Pause, [vk_escape, ord("P")]);
    input_bind(Action.Debug, [vk_f1]);
    input_bind(Action.Restart, [vk_f5]);
}
// Rebinding synchronizes the held state: no synthetic press on a held key.
function input_bind(_action, _keys, _read_key = keyboard_check) {
    var a = global.actions[_action];
    a.keys = _keys;
    a.down = false;
    for (var i = 0; i < array_length(_keys); ++i)
        a.down = a.down || _read_key(_keys[i]);
    a.pressed = false;
    a.released = false;
}
// Exactly once, in the controller's Begin Step, including menus and pause.
function input_update(_read_key = keyboard_check) {
    for (var i = 0; i < Action.Count; ++i) {
        var a = global.actions[i];
        var held = false;
        for (var k = 0; k < array_length(a.keys); ++k)
            held = held || _read_key(a.keys[k]);
        a.pressed = held && !a.down;
        a.released = !held && a.down;
        a.down = held;
    }
}
function input_down(_action) { return global.actions[_action].down; }
function input_pressed(_action) { return global.actions[_action].pressed; }
function input_released(_action) { return global.actions[_action].released; }
function input_axis(_negative, _positive) {
    return input_down(_positive) - input_down(_negative);
}
function game_running() { return global.mode == GameMode.Play; }
