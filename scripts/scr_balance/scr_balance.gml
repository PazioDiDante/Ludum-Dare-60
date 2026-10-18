/// scr_balance.gml
/// GameMaker GML 2.3+ / modern GameMaker
/// Numerical balance checker: inventory + device + constraints + exhaustive enumeration.
/// Count unique combinations of module types and powered/unpowered states.
/// Module placement order is deliberately ignored.

function bal_keys() {
    return ["energy", "heat", "stability", "weight",
            "speed", "efficiency", "accuracy", "wear"];
}

// Missing stat = 0, so modules can contain only the fields they affect.
function bal_stat(_data, _key) {
    if (struct_exists(_data, _key)) return struct_get(_data, _key);
    return 0;
}

function bal_empty_stats() {
    return {
        energy: 0, heat: 0, stability: 0, weight: 0,
        speed: 0, efficiency: 0, accuracy: 0, wear: 0
    };
}

// Applies one type of module to cumulative stats.
// Weight is added for ALL installed modules, including disconnected ones.
// Other properties apply only to powered modules.
// _sign is +1 when descending recursion and -1 on backtracking.
function bal_apply(_sum, _module, _installed, _powered, _sign) {
    var _keys = bal_keys();
    for (var k = 0; k < array_length(_keys); k++) {
        var _key = _keys[k];
        var _pieces = (_key == "weight") ? _installed : _powered;
        var _new_value = struct_get(_sum, _key)
                       + _sign * _pieces * bal_stat(_module.stats, _key);
        struct_set(_sum, _key, _new_value);
    }
}

// Both min and max bounds are INCLUSIVE. Unmentioned stats are unrestricted.
function bal_matches(_sum, _goal) {
    var _keys = bal_keys();
    for (var k = 0; k < array_length(_keys); k++) {
        var _key = _keys[k];
        var _value = struct_get(_sum, _key);
        if (struct_exists(_goal.min, _key)
            && _value < struct_get(_goal.min, _key)) return false;
        if (struct_exists(_goal.max, _key)
            && _value > struct_get(_goal.max, _key)) return false;
    }
    return true;
}

function bal_scan(_items, _goal, _index, _remaining, _installed_total,
                  _sum, _description, _result) {
    if (_index >= array_length(_items)) {
        if (_installed_total < _goal.min_installed) return;
        if (!bal_matches(_sum, _goal)) return;
        _result.count++;
        if (array_length(_result.examples) < _result.example_limit) {
            var _example = _description;
            if (_example == "") _example = "[empty configuration]";
            array_push(_result.examples, {
                combination: _example,
                stats: {
                    energy: _sum.energy, heat: _sum.heat,
                    stability: _sum.stability, weight: _sum.weight,
                    speed: _sum.speed, efficiency: _sum.efficiency,
                    accuracy: _sum.accuracy, wear: _sum.wear
                }
            });
        }
        return;
    }

    var _module = _items[_index];
    var _max_install = min(_remaining, max(0, floor(_module.qty)));

    // Count each number of installed units once; order of slots is irrelevant.
    for (var _installed = 0; _installed <= _max_install; _installed++) {
        // Optional: enumerate OFF units separately (but still count their weight).
        var _min_powered = _goal.allow_unpowered ? 0 : _installed;
        for (var _powered = _min_powered; _powered <= _installed; _powered++) {
            bal_apply(_sum, _module, _installed, _powered, +1);

            var _text = _description;
            if (_installed > 0) {
                if (_text != "") _text += " + ";
                _text += _module.name + " x" + string(_installed);
                if (_goal.allow_unpowered) {
                    _text += " (on: " + string(_powered) + ")";
                }
            }

            bal_scan(_items, _goal, _index + 1,
                     _remaining - _installed,
                     _installed_total + _installed,
                     _sum, _text, _result);

            bal_apply(_sum, _module, _installed, _powered, -1);
        }
    }
}

/// @function bal_count(inventory, goal, example_limit)
/// @return { count: number, examples: [{ combination: string, stats: struct }] }
function bal_count(_inventory, _goal, _example_limit) {
    var _sum = bal_empty_stats();
    var _keys = bal_keys();
    for (var k = 0; k < array_length(_keys); k++) {
        var _key = _keys[k];
        struct_set(_sum, _key, bal_stat(_goal.base, _key));
    }
    var _result = { count: 0, examples: [], example_limit: max(0, _example_limit) };
    bal_scan(_inventory, _goal, 0, _goal.slots, 0, _sum, "", _result);
    return _result;
}

// This editable catalog contains 20 module TYPES.
// qty = how many of this type the player currently has.
// Modules with qty=0 are part of the catalog, but unavailable for this check.
function bal_catalog() {
    return [
        {name:"Eco coil",         qty:1, stats:{energy:-2, heat: 1, weight:2}},
        {name:"Lite saver",       qty:1, stats:{energy:-1, stability:-1, weight:1}},
        {name:"Power saver",      qty:1, stats:{energy:-3, heat: 2, stability:-1, weight:3}},
        {name:"Pulse converter",  qty:1, stats:{energy:-2, stability:-2, weight:2}},
        {name:"Fan",              qty:1, stats:{energy: 1, heat:-3, weight:2}},
        {name:"Passive radiator", qty:1, stats:{heat:-2, stability:-1, weight:3}},
        {name:"Turbo fan",        qty:1, stats:{energy: 2, heat:-5, stability:-1, weight:2}},
        {name:"Cryo cooler",      qty:1, stats:{energy: 3, heat:-6, stability: 1, weight:4}},
        {name:"Regulator",        qty:1, stats:{energy: 1, stability: 2, weight:1}},
        {name:"Capacitor",        qty:1, stats:{heat: 2, stability: 3, weight:2}},
        {name:"Filter",           qty:1, stats:{energy: 2, heat:-1, stability: 4, weight:3}},
        {name:"Heavy stabilizer", qty:1, stats:{energy: 1, heat: 2, stability: 5, weight:4}},
        {name:"Overclock drive",  qty:0, stats:{energy: 2, heat: 2, stability:-1, speed:3, weight:2}},
        {name:"Eco servo",        qty:0, stats:{energy: 1, heat: 1, efficiency:-1, speed:2, weight:2}},
        {name:"Recycler",         qty:0, stats:{energy: 1, heat: 1, efficiency: 3, speed:-1, weight:2}},
        {name:"Optimizer",        qty:0, stats:{energy:-1, heat: 1, stability:-1, efficiency:2, weight:1}},
        {name:"Calibrator",       qty:0, stats:{energy: 1, speed:-1, accuracy:3, weight:2}},
        {name:"Precision lens",   qty:0, stats:{energy: 2, heat: 1, stability:-1, accuracy:4, weight:1}},
        {name:"Reinforced bearing", qty:0, stats:{energy: 1, heat:1, wear:-3, weight:2}},
        {name:"Lubrication unit", qty:0, stats:{energy: 1, heat:-1, stability:-1, wear:-2, weight:1}}
    ];
}

// EDIT THE GOAL HERE. A property can be constrained only by min, max, or both.
function bal_radio_goal() {
    return {
        slots: 2,                // UP TO two installed modules
        min_installed: 0,        // 0 = empty/partially filled slots are allowed
        allow_unpowered: false,  // true = count connected/disconnected combinations
        base: {energy:5, heat:5, stability:4, weight:2},
        min:  {stability:6},
        max:  {energy:7, heat:4, weight:7}
    };
}

// Call once in the Create event, or on button press (not every Step).
function bal_demo() {
    var _items = bal_catalog();
    var _goal = bal_radio_goal();
    var _result = bal_count(_items, _goal, 30);
    show_debug_message("VALID COMBINATIONS: " + string(_result.count));
    for (var i = 0; i < array_length(_result.examples); i++) {
        var _e = _result.examples[i];
        show_debug_message(string(i + 1) + ". " + _e.combination
            + "  | E=" + string(_e.stats.energy)
            + " H=" + string(_e.stats.heat)
            + " S=" + string(_e.stats.stability)
            + " W=" + string(_e.stats.weight));
    }
    return _result;
}
