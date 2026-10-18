// Only one manual screw action may run, independently of robot jobs.
function screw_start(_screw) {
    if(!game_running()||!instance_exists(_screw)) return false;
    var g=instance_find(obj_game,0);
    if(!instance_exists(g)||instance_exists(g.active_screw)||!instance_exists(_screw.device)) return false;
    if(g.active_device!=_screw.device||!_screw.visible||!_screw.interaction_enabled||_screw.device.cover_open) return false;
    _screw.unscrew_seconds=_screw.unscrew_base_seconds*(shop_owned(g,"fast_unscrew")?0.5:1);
    _screw.unscrewing=true;_screw.unscrew_remaining=_screw.unscrew_seconds;
    g.active_screw=_screw;return true;
}
function screw_cancel(_g) {
    sfx_screw_stop(_g);
    var screw=_g.active_screw;
    _g.active_screw=noone;
    if(instance_exists(screw)) {screw.unscrewing=false;screw.unscrew_remaining=0;}
}
function screw_tick(_g,_seconds) {
    var screw=_g.active_screw;
    if(!instance_exists(screw)) {_g.active_screw=noone;sfx_screw_stop(_g);return;}
    if(!instance_exists(screw.device)||_g.active_device!=screw.device||!screw.visible) {screw_cancel(_g);return;}
    if(!game_running()) return;
    screw.unscrew_remaining=max(0,screw.unscrew_remaining-_seconds);
    if(screw.unscrew_remaining>0) return;
    var device=screw.device;
    sfx_screw_stop(_g);
    _g.active_screw=noone;screw.unscrewing=false;screw.interaction_enabled=false;
    device.remaining=max(0,device.remaining-1);
    instance_destroy(screw);
    sfx_play(snd_remove_cover);
    if(device.remaining==0) device.open_cover();
}

// Called in the child device's Create, AFTER its configuration.
function device_build() {
    if(variable_instance_exists(id,"balance_probe") && balance_probe) return;
    if (built) return;
    built = true;
    if (sprite_exists(board_mask_sprite)) board_shape = board_shape_from_sprite(board_mask_sprite,source_cell_size);
    rows = array_length(board_shape);
    cols = array_length(board_shape[0]);
    // Keep the full board in the room, with space for the menu and margins.
    var fit_x = max(1,2*min(x+board_offset[0]-40,room_width-256-x-board_offset[0]));
    var fit_y = max(1,2*min(y+board_offset[1]-80,room_height-40-y-board_offset[1]));
    if(work_layout) {
        var left=floor(room_width/3)+24,right=room_width-24;
        fit_x=max(1,2*min(x+board_offset[0]-left,right-x-board_offset[0]));
        fit_y=max(1,2*min(y+board_offset[1]-80,room_height-48-y-board_offset[1]));
    }
    var fit = min(fit_x/(cols*source_cell_size),fit_y/(rows*source_cell_size));
    // Prefer whole-pixel scaling. Extremely large boards may require downscaling.
    draw_scale = min(max(1,board_scale), fit >= 1 ? floor(fit) : fit);
    cell_size = source_cell_size * draw_scale;
    half_w = max(half_w,cols*cell_size/2+abs(board_offset[0])+16);
    half_h = max(half_h,rows*cell_size/2+abs(board_offset[1])+16);
    board_x = x-cols*cell_size/2+board_offset[0];
    board_y = y-rows*cell_size/2+board_offset[1];
    board = array_create(rows);
    for (var row = 0; row < rows; ++row) board[row] = array_create(cols,noone);
    remaining = array_length(screw_positions);
    interaction_label = device_name;
    for (var i = 0; i < remaining; ++i) {
        var screw = instance_create_depth(x+screw_positions[i][0],y+screw_positions[i][1],depth-10,obj_screw);
        screw.device = id;
        array_push(children,screw);
    }
    if (remaining == 0) open_cover();
    device_stats_update(id);
}

// A cell is usable if its CENTRE is inside the sprite's precise collision mask.
// Use a single-frame sprite, full cell-sized canvas, and Collision Mask = Precise.
// The temporary hidden instance exists only while the grid is sampled.
function board_shape_from_sprite(_sprite,_size) {
    var cols = max(1,ceil(sprite_get_width(_sprite)/_size));
    var rows = max(1,ceil(sprite_get_height(_sprite)/_size));
    var shape = array_create(rows);
    var probe = instance_create_depth(0,0,0,obj_board_mask);
    probe.sprite_index = _sprite;
    probe.image_speed = 0;
    probe.x = sprite_get_xoffset(_sprite);
    probe.y = sprite_get_yoffset(_sprite);
    for (var row = 0; row < rows; ++row) {
        shape[row] = array_create(cols,0);
        for (var col = 0; col < cols; ++col) {
            // Do not admit partial cells at the right/bottom of the sprite canvas.
            if ((col+1)*_size > sprite_get_width(_sprite) || (row+1)*_size > sprite_get_height(_sprite)) continue;
            shape[row][col] = collision_point((col+0.5)*_size,(row+0.5)*_size,probe,true,false) != noone;
        }
    }
    instance_destroy(probe);
    return shape;
}

// Bounded greedy generator: find every legal position for each type, then pick
// a random feasible type and one of its legal positions. Never overlap or hang.
function device_generate_modules() {
    if(is_order) return;
    if(campaign) {campaign_loot(id);return;}
    if (layout_seed >= 0) random_set_seed(layout_seed);
    requested_modules = irandom_range(module_min,module_max);
    placed_modules = 0;
    repeat (requested_modules) {
        var candidates = [];
        for (var t = 0; t < array_length(module_pool); ++t) {
            var item = instance_create_depth(0,0,depth-10,module_pool[t]);
            item.device = id;
            var positions = [];
            for (var row = 0; row < rows; ++row)
                for (var col = 0; col < cols; ++col)
                    if (board_can_place(item,col,row)) array_push(positions,[col,row]);
            if (array_length(positions) == 0) instance_destroy(item);
            else array_push(candidates,{item:item, positions:positions});
        }
        if (array_length(candidates) == 0) break;
        var chosen = irandom(array_length(candidates)-1);
        for (var i = 0; i < array_length(candidates); ++i) {
            var candidate = candidates[i];
            if (i != chosen) { instance_destroy(candidate.item); continue; }
            var pos = candidate.positions[irandom(array_length(candidate.positions)-1)];
            board_place(candidate.item,pos[0],pos[1]);
            array_push(children,candidate.item);
            placed_modules++;
        }
    }
}
