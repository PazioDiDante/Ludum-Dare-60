// Shapes use 0 = empty, 1 = body, "LRD_1" = directions plus port type.
// Keep the old enum for existing fixtures; new types never need enum entries.
enum Cell { Empty, Solid, L, U, R, D, LU, LR, LD, UR, UD, RD, LUR, LUD, LRD, URD, LURD }

function cell_port_info(_cell) {
    static parsed={};
    var invalid={letters:"",port_type:0,typed:false};
    if(is_string(_cell)) {
        var value=string_upper(string_trim(_cell)),separator=string_pos("_",value);
        if(struct_exists(parsed,value)) return struct_get(parsed,value);
        var letters=value,port_type=1;
        if(separator>0) {
            letters=string_copy(value,1,separator-1);
            var suffix=string_delete(value,1,separator);
            if(suffix==""||string_digits(suffix)!=suffix) return invalid;
            port_type=real(suffix);
            if(port_type<1||floor(port_type)!=port_type) return invalid;
        }
        if(letters=="") return invalid;
        for(var i=1;i<=string_length(letters);++i)
            if(string_pos(string_char_at(letters,i),"LURD")==0) return invalid;
        var canonical="";
        for(var i=1;i<=4;++i) {
            var letter=string_char_at("LURD",i);
            if(string_pos(letter,letters)>0) canonical+=letter;
        }
        var info={letters:canonical,port_type:port_type,typed:separator>0};
        struct_set(parsed,value,info);return info;
    }
    static names=["","","L","U","R","D","LU","LR","LD","UR","UD","RD","LUR","LUD","LRD","URD","LURD"];
    if(!is_numeric(_cell)||_cell<Cell.L||_cell>=array_length(names)||floor(_cell)!=_cell) return invalid;
    return {letters:names[_cell],port_type:1,typed:false};
}
function cell_port_letters(_cell) {
    return cell_port_info(_cell).letters;
}
function cell_port_type(_cell) {
    return cell_port_info(_cell).port_type;
}
function cell_directions(_cell) {
    var letters=cell_port_letters(_cell),result=[];
    if(string_pos("L",letters)>0) array_push(result,Cell.L);
    if(string_pos("U",letters)>0) array_push(result,Cell.U);
    if(string_pos("R",letters)>0) array_push(result,Cell.R);
    if(string_pos("D",letters)>0) array_push(result,Cell.D);
    return result;
}
function cell_has_port(_cell,_direction) {
    var letter=cell_port_letters(_direction);
    return string_length(letter)==1&&string_pos(letter,cell_port_letters(_cell))>0;
}
function port_rotate_direction(_direction) {
    switch(_direction) {
        case Cell.L: return Cell.U;
        case Cell.U: return Cell.R;
        case Cell.R: return Cell.D;
        case Cell.D: return Cell.L;
    }
    return _direction;
}
function cell_rotate(_cell) {
    var info=cell_port_info(_cell),letters=info.letters,result="";
    if(letters=="") return _cell;
    if(string_pos("D",letters)>0) result+="L";
    if(string_pos("L",letters)>0) result+="U";
    if(string_pos("U",letters)>0) result+="R";
    if(string_pos("R",letters)>0) result+="D";
    if(is_string(_cell)) return result+(info.typed?"_"+string(info.port_type):"");
    for(var i=Cell.L;i<=Cell.LURD;++i) if(cell_port_letters(i)==result) return i;
    return _cell;
}

// Read only. Allow a module to overlap its own old cells when moving.
function board_can_place(_module,_col,_row) {
    var device = _module.device;
    if (!instance_exists(device)) return false;
    if(device.completed) return false;
    for (var sy = 0; sy < array_length(_module.shape); ++sy) {
        for (var sx = 0; sx < array_length(_module.shape[sy]); ++sx) {
            if (_module.shape[sy][sx] == Cell.Empty) continue;
            var bx = _col+sx, by = _row+sy;
            if (bx < 0 || by < 0 || bx >= device.cols || by >= device.rows) return false;
            if (!device.board_shape[by][bx]) return false;
            var occupant = device.board[by][bx];
            if (occupant != noone && occupant != _module) return false;
        }
    }
    return true;
}

// Validate BEFORE clearing the old position. Failed moves change nothing.
function board_place(_module,_col,_row) {
    var device = _module.device;
    if (!board_can_place(_module,_col,_row)) return false;
    for (var by = 0; by < device.rows; ++by)
        for (var bx = 0; bx < device.cols; ++bx)
            if (device.board[by][bx] == _module) device.board[by][bx] = noone;
    for (var sy = 0; sy < array_length(_module.shape); ++sy)
        for (var sx = 0; sx < array_length(_module.shape[sy]); ++sx)
            if (_module.shape[sy][sx] != Cell.Empty) device.board[_row+sy][_col+sx] = _module;
    _module.grid_col = _col;
    _module.grid_row = _row;
    _module.x = device.board_x + _col * device.cell_size;
    _module.y = device.board_y + _row * device.cell_size;
    device_stats_update(device);
    return true;
}


// Pick up the actual cell under the cursor, not the shape's upper-left corner.
// Old board cells stay reserved until drop, so cancellation is always possible.
function board_pick(_module,_px,_py) {
    if (!game_running() || !instance_exists(_module)) return false;
    var device = _module.device;
    if (!instance_exists(device) || instance_exists(device.selected_module)) return false;
    if (!is_undefined(device.wire_start)) return false;
    if (!_module.hit_test(_px,_py)) return false;
    _module.grab_col = floor((_px-_module.x)/device.cell_size);
    _module.grab_row = floor((_py-_module.y)/device.cell_size);
    _module.preview_col = _module.grid_col;
    _module.preview_row = _module.grid_row;
    _module.drop_valid = true;
    _module.rest_depth = _module.depth;
    // Rotations allocate a new array, so this original shape remains unchanged.
    _module.rest_shape = _module.shape;
    _module.rest_rotation = _module.rotation_steps;
    _module.depth = -100; // Held item draws above other modules.
    device.selected_module = _module;
    sfx_play(snd_modul_take_place);
    return true;
}

// Preview only: x/y follow the grid; committed grid_col/grid_row and board do not change.
function board_drag_update(_device,_px,_py) {
    if (!game_running() || !instance_exists(_device.selected_module)) return false;
    var item = _device.selected_module;
    item.storage_preview=false;
    item.preview_col = floor((_px-_device.board_x)/_device.cell_size)-item.grab_col;
    item.preview_row = floor((_py-_device.board_y)/_device.cell_size)-item.grab_row;
    item.x = _device.board_x+item.preview_col*_device.cell_size;
    item.y = _device.board_y+item.preview_row*_device.cell_size;
    item.drop_valid = _device.cover_open && board_can_place(item,item.preview_col,item.preview_row);
    if (instance_exists(obj_game) && obj_game.active_device == _device) {
        var slot = inventory_slot(obj_game,_px,_py);
        if(slot>=0) {
            item.storage_preview=true;
            var c=floor((_px-obj_game.inventory_x)/obj_game.inventory_size)-item.grab_col;
            var r=floor((_py-obj_game.inventory_y)/obj_game.inventory_size)-item.grab_row;
            item.x=obj_game.inventory_x+c*obj_game.inventory_size;item.y=obj_game.inventory_y+r*obj_game.inventory_size;
            item.drop_valid=instance_exists(item.debug_inventory_source)||inventory_can_place(obj_game,item,c,r,obj_game.inventory_page);
        }
    }
    return item.drop_valid;
}

function board_drop(_device) {
    if (!game_running() || !instance_exists(_device.selected_module)) return false;
    var item = _device.selected_module;
    if (!_device.cover_open || !board_place(item,item.preview_col,item.preview_row)) return false;
    if (item.inventory_origin >= 0) {
        array_push(_device.children,item);
        item.inventory_origin = -1;
    }
    item.depth = item.rest_depth;
    _device.selected_module = noone;
    device_stats_update(_device);
    sfx_play(snd_modul_take_place);
    return true;
}

function board_cancel(_device) {
    if (inventory_return(_device)) return true;
    if (!instance_exists(_device.selected_module)) return false;
    var item = _device.selected_module;
    item.shape = item.rest_shape;
    item.rotation_steps = item.rest_rotation;
    item.x = _device.board_x+item.grid_col*_device.cell_size;
    item.y = _device.board_y+item.grid_row*_device.cell_size;
    item.preview_col = item.grid_col;
    item.preview_row = item.grid_row;
    item.drop_valid = true;
    item.depth = item.rest_depth;
    _device.selected_module = noone;
    device_stats_update(_device);
    return true;
}


// Clockwise: local (col,row) becomes (old_height-1-row,col).
// Ports are occupied cells and rotate their direction as well.
function board_rotate(_device) {
    if (!instance_exists(_device)) return false;
    if (!game_running() || !instance_exists(_device.selected_module)) return false;
    var item = _device.selected_module;
    var old_height = array_length(item.shape);
    var old_width = array_length(item.shape[0]);
    var rotated = array_create(old_width);
    for (var row = 0; row < old_width; ++row) rotated[row] = array_create(old_height,Cell.Empty);
    for (var row = 0; row < old_height; ++row) {
        for (var col = 0; col < old_width; ++col) {
            var cell = item.shape[row][col];
            cell = cell_rotate(cell);
            rotated[col][old_height-1-row] = cell;
        }
    }
    // Keep the grabbed cell under the same board cell after rotation.
    var anchor_col = item.preview_col+item.grab_col;
    var anchor_row = item.preview_row+item.grab_row;
    var old_grab_col = item.grab_col;
    item.grab_col = old_height-1-item.grab_row;
    item.grab_row = old_grab_col;
    item.shape = rotated;
    item.rotation_steps = (item.rotation_steps+1) mod 4;
    item.preview_col = anchor_col-item.grab_col;
    item.preview_row = anchor_row-item.grab_row;
    item.x = _device.board_x+item.preview_col*_device.cell_size;
    item.y = _device.board_y+item.preview_row*_device.cell_size;
    item.drop_valid = _device.cover_open && board_can_place(item,item.preview_col,item.preview_row);
    sfx_play(snd_modul_take_place);
    return true; // An invalid preview can still be moved; only dropping is forbidden.
}

// Offset of a rotated sprite's origin from the shape's top-left corner.
// GameMaker sprite angles are counter-clockwise, hence -90 per clockwise turn.
function module_sprite_offset(_sprite,_turn,_scale) {
    var ox = sprite_get_xoffset(_sprite), oy = sprite_get_yoffset(_sprite);
    var w = sprite_get_width(_sprite), h = sprite_get_height(_sprite);
    switch (_turn) {
        case 1: return [(h-oy)*_scale,ox*_scale];
        case 2: return [(w-ox)*_scale,(h-oy)*_scale];
        case 3: return [oy*_scale,(w-ox)*_scale];
    }
    return [ox*_scale,oy*_scale];
}
