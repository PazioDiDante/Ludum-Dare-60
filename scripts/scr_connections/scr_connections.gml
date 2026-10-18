// Contact rectangle shared by drawing and clicking. Only the edge contact is a port.
function port_rect(_x,_y,_size,_direction) {
    var half = min(5,_size/3), thick = min(7,_size/2);
    switch (_direction) {
        case Cell.L: return [_x,_y+_size/2-half,_x+thick,_y+_size/2+half];
        case Cell.U: return [_x+_size/2-half,_y,_x+_size/2+half,_y+thick];
        case Cell.R: return [_x+_size-thick,_y+_size/2-half,_x+_size,_y+_size/2+half];
        case Cell.D: return [_x+_size/2-half,_y+_size-thick,_x+_size/2+half,_y+_size];
    }
    return undefined;
}

// Stable identity: store coordinates in the ORIGINAL unrotated shape.
// No port IDs need to be rewritten when rotating or cancelling a pickup.
function port_reference(_module,_col,_row,_direction = undefined) {
    var port_type=cell_port_type(_module.shape[_row][_col]);
    if(is_undefined(_direction)) {
        var directions=cell_directions(_module.shape[_row][_col]);
        if(array_length(directions)==0) return undefined;
        _direction=directions[0]; // Compatibility for existing single-port callers.
    }
    var w = array_length(_module.shape[0]), h = array_length(_module.shape);
    repeat (_module.rotation_steps) {
        repeat(3) _direction=port_rotate_direction(_direction);
        var old_col = _col;
        _col = _row; _row = w-1-old_col;
        var old_w = w; w = h; h = old_w;
    }
    return {module:_module,col:_col,row:_row,direction:_direction,port_type:port_type};
}
function port_current(_port) {
    if (is_undefined(_port) || !instance_exists(_port.module)) return undefined;
    if (variable_struct_exists(_port,"board_port")) return board_port_current(_port);
    var item = _port.module;
    if (!instance_exists(item.device)) return undefined;
    var w = array_length(item.shape[0]), h = array_length(item.shape);
    if (item.rotation_steps mod 2 == 1) { var swap = w; w = h; h = swap; }
    var col = _port.col, row = _port.row;
    repeat (item.rotation_steps) {
        var old_col = col; col = h-1-row; row = old_col;
        var old_w = w; w = h; h = old_w;
    }
    if (row < 0 || row >= array_length(item.shape)) return undefined;
    if (col < 0 || col >= array_length(item.shape[row])) return undefined;
    var port_direction = _port.direction;
    repeat(item.rotation_steps) port_direction=port_rotate_direction(port_direction);
    if(!cell_has_port(item.shape[row][col],port_direction)) return undefined;
    var port_type=cell_port_type(item.shape[row][col]);
    if(struct_exists(_port,"port_type")&&_port.port_type!=port_type) return undefined;
    var size = item.device.cell_size;
    var rect = port_rect(item.x+col*size,item.y+row*size,size,port_direction);
    if (is_undefined(rect)) return undefined;
    return {col:col,row:row,direction:port_direction,port_type:port_type,x:(rect[0]+rect[2])/2,y:(rect[1]+rect[3])/2,rect:rect};
}
function port_equal(_a,_b) {
    if (is_undefined(_a) || is_undefined(_b)) return false;
    var a_board = variable_struct_exists(_a,"board_port"), b_board = variable_struct_exists(_b,"board_port");
    if (a_board != b_board) return false;
    if (a_board) return _a.module == _b.module && _a.board_port == _b.board_port;
    var a_type=struct_exists(_a,"port_type")?_a.port_type:1,b_type=struct_exists(_b,"port_type")?_b.port_type:1;
    return _a.module == _b.module && _a.col == _b.col && _a.row == _b.row && _a.direction == _b.direction && a_type==b_type;
}
function ports_compatible(_a,_b) {
    var a=port_current(_a),b=port_current(_b);
    return !is_undefined(a)&&!is_undefined(b)&&a.port_type==b.port_type;
}
function port_type_color(_type) {
    return _type==1?c_orange:make_color_hsv((128+(_type-2)*47) mod 256,200,255);
}
function port_find(_device,_px,_py) {
    if(_device.is_recycler) return undefined;
    // Fixed contacts draw over the board and have matching click priority.
    for (var i = 0; i < array_length(_device.board_ports); ++i) {
        var ref = board_port_reference(_device,i);
        var pos = port_current(ref);
        if (is_undefined(pos)) continue;
        var r = pos.rect;
        if (_px >= r[0] && _px <= r[2] && _py >= r[1] && _py <= r[3]) return ref;
    }
    // Respect the visible topmost object, so contacts cannot be clicked through another module.
    var item = pointer_find(_px,_py);
    if (!instance_exists(item)) return undefined;
    if (item.object_index != par_module && !object_is_ancestor(item.object_index,par_module)) return undefined;
    if (item.device != _device) return undefined;
    var size = _device.cell_size;
    var col = floor((_px-item.x)/size), row = floor((_py-item.y)/size);
    var directions=cell_directions(item.shape[row][col]);
    for(var i=0;i<array_length(directions);++i) {
        var rect=port_rect(item.x+col*size,item.y+row*size,size,directions[i]);
        if(_px>=rect[0] && _px<=rect[2] && _py>=rect[1] && _py<=rect[3])
            return port_reference(item,col,row,directions[i]);
    }
    return undefined;
}

function wire_for_port(_device,_port) {
    for (var i = 0; i < array_length(_device.wires); ++i) {
        var wire = _device.wires[i];
        if (port_equal(wire.a,_port) || port_equal(wire.b,_port)) return i;
    }
    return -1;
}
// Remove exactly this connection from both modules; other port pairs are preserved.
function wire_disconnect(_device,_index,_refresh = true) {
    if (_index < 0 || _index >= array_length(_device.wires)) return false;
    var wire = _device.wires[_index];
    var endpoints = [wire.a,wire.b];
    for (var side = 0; side < 2; ++side) {
        var endpoint = endpoints[side];
        if (!instance_exists(endpoint.module)) continue;
        var peer_endpoint = endpoints[1-side];
        var item = endpoint.module;
        for (var i = array_length(item.connections)-1; i >= 0; --i) {
            var connection = item.connections[i];
            if (port_equal(connection.own_port,endpoint) && port_equal(connection.other_port,peer_endpoint))
                array_delete(item.connections,i,1);
        }
    }
    array_delete(_device.wires,_index,1);
    if (_refresh) circuit_update(_device);
    return true;
}

function wire_connect(_device,_a,_b,_replace_target = false,_draft_visual=undefined) {
    if(_device.is_recycler) return false;
    if (!ports_compatible(_a,_b)) return false;
    if (_a.module == _b.module) return false;
    if (port_device(_a) != _device || port_device(_b) != _device) return false;
    // One completed wire per contact, at either endpoint.
    if (wire_for_port(_device,_a) >= 0) return false;
    var occupied_target = wire_for_port(_device,_b);
    if (occupied_target >= 0 && !_replace_target) return false;
    // All endpoint checks passed. Only now remove the destination's old wire.
    if (occupied_target >= 0) wire_disconnect(_device,occupied_target,false); // Replacement is one graph edit.
    var a_pos=port_current(_a),b_pos=port_current(_b);
    var wire = {a:_a,b:_b,visual:wire_visual_create(a_pos.x,a_pos.y,b_pos.x,b_pos.y,is_undefined(_draft_visual)?undefined:_draft_visual.color)};
    array_push(_device.wires,wire);
    array_push(_a.module.connections,{module:_b.module,own_port:_a,other_port:_b});
    array_push(_b.module.connections,{module:_a.module,own_port:_b,other_port:_a});
    circuit_update(_device);
    return true;
}
function wire_click(_device,_port) {
    if (!game_running() || instance_exists(_device.selected_module)) return false;
    if (is_undefined(port_current(_port))) return false;
    if (port_device(_port) != _device) return false;
    if (is_undefined(_device.wire_start)) {
        // Picking up an occupied port disconnects it immediately, even if later cancelled.
        var existing = wire_for_port(_device,_port);
        if (existing >= 0) wire_disconnect(_device,existing);
        _device.wire_start = _port;
        var start = port_current(_port);
        _device.wire_draft=wire_visual_create(start.x,start.y,start.x,start.y);
        _device.wire_mouse_x = start.x; _device.wire_mouse_y = start.y;
        sfx_play(snd_modul_take_place);
        return true;
    }
    if (!wire_connect(_device,_device.wire_start,_port,true,_device.wire_draft)) return false;
    _device.user_wired=true;
    _device.wire_start = undefined;
    _device.wire_draft = undefined;
    sfx_play(snd_modul_take_place);
    return true;
}
function wire_cancel(_device) { _device.wire_start = undefined; _device.wire_draft=undefined; }

// Picking up a wire is tighter than attaching it, leaving module bodies accessible.
function port_find_snap(_device,_px,_py) {
    if(_device.is_recycler) return undefined;
    var start=_device.wire_start;
    var drawing=!is_undefined(start);
    var exact=port_find(_device,_px,_py);
    if(!is_undefined(exact)&&(!drawing||(exact.module!=start.module&&ports_compatible(start,exact)))) return exact;
    var candidates=[];
    if(!drawing||start.module!=_device) for(var i=0;i<array_length(_device.board_ports);++i)
        array_push(candidates,board_port_reference(_device,i));
    for(var i=0;i<instance_number(par_module);++i) {
        var item=instance_find(par_module,i);
        if((drawing&&item==start.module) || item.device!=_device || item.in_inventory || !item.visible || !item.interaction_enabled) continue;
        for(var row=0;row<array_length(item.shape);++row)
            for(var col=0;col<array_length(item.shape[row]);++col) {
                var directions=cell_directions(item.shape[row][col]);
                for(var side=0;side<array_length(directions);++side)
                    array_push(candidates,port_reference(item,col,row,directions[side]));
            }
    }
    var nearest=undefined,best=drawing?_device.wire_snap_radius:min(_device.wire_pick_radius,_device.cell_size*0.25);
    for(var i=0;i<array_length(candidates);++i) {
        var candidate=candidates[i],pos=port_current(candidate);
        if(is_undefined(pos)) continue;
        if(drawing&&!ports_compatible(start,candidate)) continue;
        var distance=point_distance(_px,_py,pos.x,pos.y);
        if(distance>best) continue;
        // Match visible port priority; do not snap through an overlapping module.
        if(!port_equal(port_find(_device,pos.x,pos.y),candidate)) continue;
        nearest=candidate;best=distance;
    }
    return nearest;
}

// Returns true when wiring consumes this input, including invalid second clicks.
function wire_input(_device,_px,_py,_primary,_cancel,_secondary = false) {
    if(_device.is_recycler) return false;
    if (!game_running() || instance_exists(_device.selected_module)) return false;
    if ((_cancel || _secondary) && !is_undefined(_device.wire_start)) { wire_cancel(_device); return true; }
    var target = port_find_snap(_device,_px,_py);
    _device.hover_port = target;
    if (!is_undefined(_device.wire_start)) {
        if (is_undefined(port_current(_device.wire_start))) { wire_cancel(_device); return true; }
        var snapped=port_current(target);
        _device.wire_mouse_x = is_undefined(snapped)?_px:snapped.x;
        _device.wire_mouse_y = is_undefined(snapped)?_py:snapped.y;
        if (_primary) sfx_action(wire_click(_device,target));
        return true;
    }
    if (_primary && !is_undefined(target)) {
        sfx_action(wire_click(_device,target));
        var pos=port_current(target);
        _device.wire_mouse_x = pos.x; _device.wire_mouse_y = pos.y;
        return true;
    }
    return false;
}
function wire_draw(_device) {
    draw_set_alpha(1);
    for (var i = 0; i < array_length(_device.wires); ++i) {
        var wire = _device.wires[i];
        var a = port_current(wire.a), b = port_current(wire.b);
        if (is_undefined(a) || is_undefined(b)) continue;
        wire_curve_draw(a.x,a.y,b.x,b.y,wire.visual);
        draw_circle(a.x,a.y,3,false); draw_circle(b.x,b.y,3,false);
    }
    var start = port_current(_device.wire_start);
    if (!is_undefined(start)) {
        wire_curve_draw(start.x,start.y,_device.wire_mouse_x,_device.wire_mouse_y,_device.wire_draft);
    }
    draw_set_color(c_white);
}

// Remove both ends when a module is deleted, including device switches/restarts.
function wire_remove_module(_module) {
    for (var i = 0; i < array_length(_module.connections); ++i) {
        var peer = _module.connections[i].module;
        if (!instance_exists(peer)) continue;
        for (var j = array_length(peer.connections)-1; j >= 0; --j)
            if (peer.connections[j].module == _module) array_delete(peer.connections,j,1);
    }
    _module.connections = [];
    var device = _module.device;
    if (!instance_exists(device)) return;
    var changed = false;
    for (var i = array_length(device.wires)-1; i >= 0; --i) {
        var wire = device.wires[i];
        if (wire.a.module == _module || wire.b.module == _module) {
            array_delete(device.wires,i,1);
            changed = true;
        }
    }
    if (changed) circuit_update(device);
    if (!is_undefined(device.wire_start) && device.wire_start.module == _module) wire_cancel(device);
    if (device.selected_module == _module) device.selected_module = noone;
    for (var row = 0; row < device.rows; ++row)
        for (var col = 0; col < device.cols; ++col)
            if (device.board[row][col] == _module) device.board[row][col] = noone;
}


// Board endpoints keep the owner in .module to reuse connection cleanup.
// board_port distinguishes their identity from a module's rotating shape cell.
function port_device(_port) {
    return variable_struct_exists(_port,"board_port") ? _port.module : _port.module.device;
}
function board_port_reference(_device,_index) {
    return {module:_device,board_port:_index};
}
function board_ports_generate(_device) {
    if(!_device.board_ports_enabled) {_device.board_ports=[];return;}
    var candidates = [];
    // First/last occupied cell along each scan line: always exterior edges,
    // never edges of enclosed holes. Works with sprite-derived irregular boards.
    for (var row = 0; row < _device.rows; ++row) {
        var first = -1, last = -1;
        for (var col = 0; col < _device.cols; ++col) if (_device.board_shape[row][col]) {
            if (first < 0) first = col;
            last = col;
        }
        if (first >= 0) {
            array_push(candidates,{col:first,row:row,direction:Cell.L});
            array_push(candidates,{col:last,row:row,direction:Cell.R});
        }
    }
    for (var col = 0; col < _device.cols; ++col) {
        var first = -1, last = -1;
        for (var row = 0; row < _device.rows; ++row) if (_device.board_shape[row][col]) {
            if (first < 0) first = row;
            last = row;
        }
        if (first >= 0) {
            array_push(candidates,{col:col,row:first,direction:Cell.U});
            array_push(candidates,{col:col,row:last,direction:Cell.D});
        }
    }
    _device.board_ports = [];
    repeat (min(2,array_length(candidates))) {
        var chosen = irandom(array_length(candidates)-1);
        var port=candidates[chosen],index=array_length(_device.board_ports);
        port.port_type=index<array_length(_device.board_port_types)?_device.board_port_types[index]:1;
        array_push(_device.board_ports,port);
        array_delete(candidates,chosen,1);
    }
}
function board_port_current(_ref) {
    var device = _ref.module;
    if (!device.cover_open || _ref.board_port < 0 || _ref.board_port >= array_length(device.board_ports)) return undefined;
    var port = device.board_ports[_ref.board_port];
    var size = device.cell_size;
    var px = device.board_x+port.col*size, py = device.board_y+port.row*size;
    var half = min(6,size/3), thick = min(8,size/2);
    var rect;
    // Outside the cell: modules can use the whole grid without hiding a contact.
    switch (port.direction) {
        case Cell.L: rect = [px-thick,py+size/2-half,px,py+size/2+half]; break;
        case Cell.U: rect = [px+size/2-half,py-thick,px+size/2+half,py]; break;
        case Cell.R: rect = [px+size,py+size/2-half,px+size+thick,py+size/2+half]; break;
        case Cell.D: rect = [px+size/2-half,py+size,px+size/2+half,py+size+thick]; break;
    }
    return {col:port.col,row:port.row,direction:port.direction,port_type:struct_exists(port,"port_type")?port.port_type:1,x:(rect[0]+rect[2])/2,y:(rect[1]+rect[3])/2,rect:rect};
}
function board_ports_draw(_device) {
    for (var i = 0; i < array_length(_device.board_ports); ++i) {
        var ref = board_port_reference(_device,i);
        var pos = port_current(ref);
        if (is_undefined(pos)) continue;
        draw_set_color(port_equal(_device.hover_port,ref) || port_equal(_device.wire_start,ref) ? c_yellow : port_type_color(pos.port_type));
        var r = pos.rect;
        draw_rectangle(r[0],r[1],r[2],r[3],false);
    }
    draw_set_color(c_white);
}

// Called only after completed wires change, never from Step or Draw.
// Each module conducts between all its ports. The board's two ports are
// separate endpoints: never traverse the board as if it were a module.
function circuit_update_inner(_device) {
    _device.circuit_connected = false;
    if (array_length(_device.board_ports) < 2) return false;
    var start = board_port_reference(_device,0);
    var target = board_port_reference(_device,1);
    var first_wire = wire_for_port(_device,start);
    if (first_wire < 0) return false;
    var wire = _device.wires[first_wire];
    var entry = port_equal(wire.a,start) ? wire.b : wire.a;
    if (!instance_exists(entry.module) || entry.module == _device) return false;
    var queue = [entry.module];
    // Queue also serves as the visited list, keeping cycles finite.
    for (var head = 0; head < array_length(queue); ++head) {
        var item = queue[head];
        if (!instance_exists(item) || item.device != _device) continue;
        for (var i = 0; i < array_length(item.connections); ++i) {
            var other_port = item.connections[i].other_port;
            if (port_equal(other_port,target)) {
                _device.circuit_connected = true;
                return true;
            }
            var peer = other_port.module;
            if (peer == _device || !instance_exists(peer)) continue;
            var visited = false;
            for (var j = 0; j < array_length(queue); ++j)
                if (queue[j] == peer) { visited = true; break; }
            if (!visited) array_push(queue,peer);
        }
    }
    return false;
}

function circuit_update(_device) {
    var result=circuit_update_inner(_device);
    device_stats_update(_device);
    return result;
}

// Initial donor wiring uses real ports and the same connections as manual wires.
// Higher-port modules form the trunk before single-port leaves consume sockets.
function device_wire_generated(_device) {
    if (_device.is_order || _device.is_generator || !_device.cover_open
        || array_length(_device.board_ports) == 0 || array_length(_device.wires) > 0) return;
    var nodes=[];
    for (var i=0;i<array_length(_device.children);++i) {
        var item=_device.children[i];
        if (!instance_exists(item) || (item.object_index!=par_module && !object_is_ancestor(item.object_index,par_module))
            || item.device!=_device || item.in_inventory) continue;
        var ports=[];
        for (var row=0;row<array_length(item.shape);++row)
            for (var col=0;col<array_length(item.shape[row]);++col) {
                var directions=cell_directions(item.shape[row][col]);
                for (var side=0;side<array_length(directions);++side)
                    array_push(ports,port_reference(item,col,row,directions[side]));
            }
        if (array_length(ports)>0) array_push(nodes,{ports:ports});
    }
    array_sort(nodes,function(_a,_b) {return array_length(_b.ports)-array_length(_a.ports);});
    if (array_length(nodes)==0) return;
    // Keep a socket for the return contact whenever a closed circuit is possible.
    var close_circuit=array_length(_device.board_ports)>1 && array_length(nodes[0].ports)>1;
    var available=[board_port_reference(_device,0)];
    for (var i=0;i<array_length(nodes);++i) {
        var ports=nodes[i].ports;
        if (array_length(available)==0) break;
        if (close_circuit && array_length(available)==1 && array_length(ports)==1) break;
        var best=1000000000,from_index=-1,to_index=-1;
        for (var a=0;a<array_length(available);++a) {
            var start=port_current(available[a]);
            if (is_undefined(start)) continue;
            for (var b=0;b<array_length(ports);++b) {
                if(!ports_compatible(available[a],ports[b])) continue;
                var finish=port_current(ports[b]);
                if (is_undefined(finish)) continue;
                var distance=point_distance(start.x,start.y,finish.x,finish.y);
                if (distance<best) {best=distance;from_index=a;to_index=b;}
            }
        }
        if (from_index<0 || !wire_connect(_device,available[from_index],ports[to_index])) continue;
        array_delete(available,from_index,1);
        for (var p=0;p<array_length(ports);++p) if (p!=to_index) array_push(available,ports[p]);
    }
    if (close_circuit && array_length(available)>0) {
        var target=board_port_reference(_device,1),finish=port_current(target);
        var nearest=-1,best=1000000000;
        for (var a=0;a<array_length(available);++a) {
            if(!ports_compatible(available[a],target)) continue;
            var start=port_current(available[a]);
            var distance=point_distance(start.x,start.y,finish.x,finish.y);
            if (distance<best) {best=distance;nearest=a;}
        }
        if(nearest>=0) wire_connect(_device,available[nearest],target);
    }
}
