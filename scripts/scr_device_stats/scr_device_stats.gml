// All supported device characteristics. Missing values count as zero.
function device_stat_keys() {
    return ["energy", "heat", "stability", "weight",
            "speed", "efficiency", "accuracy", "wear"];
}

// Missing stat = 0, so modules can contain only the fields they affect.

function device_stat_value(_data, _key) {
    if (struct_exists(_data, _key)) return struct_get(_data, _key);
    return 0;
}
