enum Action { Up, Down, Confirm, Pause, Primary, Secondary, Cancel, Count }
enum GameMode { Menu, Play, Pause }

function input_init() {
    global.actions = array_create(Action.Count);
    for (var i = 0; i < Action.Count; ++i)
        global.actions[i] = { keys: [], buttons: [], down: false, pressed: false };
    input_bind(Action.Up, [ord("W"), vk_up]);
    input_bind(Action.Down, [ord("S"), vk_down]);
    input_bind(Action.Confirm, [vk_enter]);
    input_bind(Action.Pause, [vk_escape, ord("P")]);
    global.actions[Action.Primary].buttons = [mb_left];
    global.actions[Action.Secondary].buttons = [mb_right];
    input_bind(Action.Cancel, [ord("Q")]);
    global.actions[Action.Cancel].buttons = [mb_middle];
}
// Rebinding synchronizes the held state: no synthetic press on a held key.
function input_bind(_action, _keys, _read_key = keyboard_check) {
    var a = global.actions[_action];
    a.keys = _keys;
    a.down = false;
    for (var i = 0; i < array_length(_keys); ++i)
        a.down = a.down || _read_key(_keys[i]);
    a.pressed = false;
}
// Exactly once, in the controller's Begin Step, including menus and pause.
function input_update(_read_key = keyboard_check, _read_mouse = mouse_check_button) {
    for (var i = 0; i < Action.Count; ++i) {
        var a = global.actions[i];
        var held = false;
        for (var k = 0; k < array_length(a.keys); ++k)
            held = held || _read_key(a.keys[k]);
        for (var b = 0; b < array_length(a.buttons); ++b)
            held = held || _read_mouse(a.buttons[b]);
        a.pressed = held && !a.down;
        a.down = held;
    }
}
function input_down(_action) { return global.actions[_action].down; }
function input_pressed(_action) { return global.actions[_action].pressed; }

function game_running() { return global.mode == GameMode.Play; }
