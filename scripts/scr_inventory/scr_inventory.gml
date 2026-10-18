// Inventory is a list of instances; storage coordinates describe their occupied cells.
function inventory_debug_seed(_g) {
    if(!_g.debug_tools) return;
    var types=game_module_types();
    for(var t=0;t<array_length(types);++t) {
        var found=false;
        for(var i=0;i<array_length(_g.inventory);++i) {
            var item=_g.inventory[i];
            if(instance_exists(item)&&item.debug_infinite_source&&item.object_index==types[t]) {found=true;break;}
        }
        if(found) continue;
        var source=instance_create_depth(0,0,-10,types[t]);source.debug_infinite_source=true;
        if(!inventory_add(_g,source)) instance_destroy(source);
    }
}
function inventory_debug_discard(_device) {
    var item=_device.selected_module;
    if(!instance_exists(item)||!instance_exists(item.debug_inventory_source)) return false;
    _device.selected_module=noone;module_detach(item);instance_destroy(item);return true;
}
function inventory_inside(_g,_x,_y) {
    return _x>=_g.inventory_x && _y>=_g.inventory_y && _x<_g.inventory_x+_g.inventory_cols*_g.inventory_size && _y<_g.inventory_y+_g.inventory_rows*_g.inventory_size;
}
function inventory_slot(_g,_x,_y) {
    if(!inventory_inside(_g,_x,_y)) return -1;
    var c=floor((_x-_g.inventory_x)/_g.inventory_size),r=floor((_y-_g.inventory_y)/_g.inventory_size);
    for(var i=0;i<array_length(_g.inventory);++i) {
        var m=_g.inventory[i];if(!instance_exists(m)||!variable_instance_exists(m,"storage_page")||m.storage_page!=_g.inventory_page) continue;
        var sx=c-m.storage_col,sy=r-m.storage_row;
        if(sy>=0&&sy<array_length(m.shape)&&sx>=0&&sx<array_length(m.shape[sy])&&m.shape[sy][sx]!=Cell.Empty) return i;
    }
    return array_length(_g.inventory); // Empty board cell; still consumes the click.
}
function inventory_can_place(_g,_item,_c,_r,_page) {
    for(var sy=0;sy<array_length(_item.shape);++sy) for(var sx=0;sx<array_length(_item.shape[sy]);++sx) {
        if(_item.shape[sy][sx]==Cell.Empty) continue;
        var c=_c+sx,r=_r+sy;
        if(c<0||r<0||c>=_g.inventory_cols||r>=_g.inventory_rows) return false;
        for(var i=0;i<array_length(_g.inventory);++i) {
            var occupant=_g.inventory[i];if(!instance_exists(occupant)||occupant==_item||!variable_instance_exists(occupant,"storage_page")||occupant.storage_page!=_page) continue;
            var ox=c-occupant.storage_col,oy=r-occupant.storage_row;
            if(oy>=0&&oy<array_length(occupant.shape)&&ox>=0&&ox<array_length(occupant.shape[oy])&&occupant.shape[oy][ox]!=Cell.Empty) return false;
        }
    }
    return true;
}
function inventory_auto_place(_g,_item) {
    // Add pages as needed. Oversized shapes fail rather than looping forever.
    if(array_length(_item.shape)>_g.inventory_rows||array_length(_item.shape[0])>_g.inventory_cols) return false;
    for(var page=0;page<=array_length(_g.inventory);++page)
        for(var r=0;r<_g.inventory_rows;++r) for(var c=0;c<_g.inventory_cols;++c)
            if(inventory_can_place(_g,_item,c,r,page)) {_item.storage_col=c;_item.storage_row=r;_item.storage_page=page;return true;}
    return false;
}
function inventory_add(_g,_item) {
    if(!inventory_auto_place(_g,_item)) return false;
    var slot=0;while(slot<array_length(_g.inventory)&&instance_exists(_g.inventory[slot])) slot++;
    _g.inventory[slot]=_item;_item.device=noone;_item.in_inventory=true;_item.visible=false;_item.inventory_origin=-1;return true;
}
function inventory_reflow(_g) {
    // A different device can change the available height. Repack only when necessary.
    for(var i=0;i<array_length(_g.inventory);++i) {
        var m=_g.inventory[i];if(!instance_exists(m)) continue;
        if(!variable_instance_exists(m,"storage_page")||!inventory_can_place(_g,m,m.storage_col,m.storage_row,m.storage_page)) inventory_auto_place(_g,m);
    }
}
function module_detach(_item) {
    var device = _item.device;
    wire_remove_module(_item); // Also clears board cells and both ends of every wire.
    if (instance_exists(device)) {
        for (var i = array_length(device.children)-1; i >= 0; --i)
            if (device.children[i] == _item) array_delete(device.children,i,1);
    }
    _item.device = noone;
    _item.circuit_powered = false;
    device_stats_update(device);
}

function inventory_pick(_game,_slot,_px,_py) {
    if(!game_running()||_slot<0||_slot>=array_length(_game.inventory)) return false;
    var device=_game.active_device,item=_game.inventory[_slot];
    if(!instance_exists(device)||device.completed||!device.cover_open||instance_exists(device.selected_module)||!is_undefined(device.wire_start)||!instance_exists(item)) return false;
    var grab_col=floor((_px-_game.inventory_x)/_game.inventory_size)-item.storage_col;
    var grab_row=floor((_py-_game.inventory_y)/_game.inventory_size)-item.storage_row;
    if(_game.debug_tools&&item.debug_infinite_source) {
        var source=item;item=instance_create_depth(0,0,-10,source.object_index);
        item.debug_inventory_source=source;
    } else _game.inventory[_slot]=noone;
    item.grab_col=grab_col;item.grab_row=grab_row;item.inventory_origin=_slot;
    item.in_inventory=false;item.visible=true;item.device=device;
    item.rest_shape=item.shape;item.rest_rotation=item.rotation_steps;item.rest_depth=-10;item.depth=-100;
    device.selected_module=item;board_drag_update(device,_px,_py);
    sfx_play(snd_modul_take_place);return true;
}
function inventory_return(_device) {
    var item=_device.selected_module;if(!instance_exists(item)||item.inventory_origin<0) return false;
    if(inventory_debug_discard(_device)) return true;
    item.shape=item.rest_shape;item.rotation_steps=item.rest_rotation;
    obj_game.inventory[item.inventory_origin]=item;
    item.inventory_origin=-1;item.in_inventory=true;item.visible=false;item.storage_preview=false;
    item.device=noone;item.depth=item.rest_depth;_device.selected_module=noone;return true;
}
function storage_drop(_game,_px,_py) {
    if(!game_running()||!instance_exists(_game.active_device)||!inventory_inside(_game,_px,_py)) return false;
    var d=_game.active_device,item=d.selected_module;if(!instance_exists(item)) return false;
    if(inventory_debug_discard(d)) return true;
    var c=floor((_px-_game.inventory_x)/_game.inventory_size)-item.grab_col;
    var r=floor((_py-_game.inventory_y)/_game.inventory_size)-item.grab_row;
    if(!inventory_can_place(_game,item,c,r,_game.inventory_page)) return false;
    var slot=item.inventory_origin;
    if(slot<0) {slot=0;while(slot<array_length(_game.inventory)&&instance_exists(_game.inventory[slot])) slot++;}
    module_detach(item);d.selected_module=noone;
    item.storage_col=c;item.storage_row=r;item.storage_page=_game.inventory_page;item.storage_preview=false;
    item.inventory_origin=-1;item.in_inventory=true;item.visible=false;item.depth=item.rest_depth;
    _game.inventory[slot]=item;sfx_play(snd_modul_take_place);return true;
}
function storage_draw(_g) {
    var size=_g.inventory_size;
    draw_set_alpha(1);
    for(var r=0;r<_g.inventory_rows;++r) for(var c=0;c<_g.inventory_cols;++c) {
        var px=_g.inventory_x+c*size,py=_g.inventory_y+r*size;
        draw_set_color(make_color_rgb(25,42,38));draw_rectangle(px,py,px+size,py+size,false);
        draw_set_color(make_color_rgb(55,76,65));draw_rectangle(px,py,px+size,py+size,true);
    }
    for(var i=0;i<array_length(_g.inventory);++i) {
        var item=_g.inventory[i];if(!instance_exists(item)||!variable_instance_exists(item,"storage_page")||item.storage_page!=_g.inventory_page) continue;
        var left=_g.inventory_x+item.storage_col*size,top=_g.inventory_y+item.storage_row*size;
        if(sprite_exists(item.sprite_index)) {
            var scale=size/16,off=module_sprite_offset(item.sprite_index,item.rotation_steps,scale);
            draw_sprite_ext(item.sprite_index,item.image_index,left+off[0],top+off[1],scale,scale,-90*item.rotation_steps,item.image_blend,1);
        } else for(var sy=0;sy<array_length(item.shape);++sy) for(var sx=0;sx<array_length(item.shape[sy]);++sx) {
            if(item.shape[sy][sx]==Cell.Empty) continue;
            draw_set_color(item.module_color);draw_rectangle(left+sx*size+2,top+sy*size+2,left+(sx+1)*size-2,top+(sy+1)*size-2,false);
        }
    }
    draw_set_color(c_white);
}
function module_draw_held(_item) {
    with (_item) {
if (!instance_exists(device)) exit;
var size = device.cell_size;
if(device.selected_module==id && variable_instance_exists(id,"storage_preview") && storage_preview) size=obj_game.inventory_size;
var held = device.selected_module == id;
var muted = !held && !circuit_powered;
var preview_color = drop_valid ? c_lime : c_red;
draw_set_alpha(held ? 0.8 : 1);
// Module artwork also uses source_cell_size pixels per cell, then the board scale.
if (sprite_exists(sprite_index)) {
    var scale = size/device.source_cell_size;
    var offset = module_sprite_offset(sprite_index,rotation_steps,scale);
    if(muted) shader_set(shd_module_unpowered);
    draw_sprite_ext(sprite_index,image_index,x+offset[0],y+offset[1],scale,scale,-90*rotation_steps,held ? preview_color : image_blend,held ? 0.8 : image_alpha);
    if(muted) shader_reset();
}
for (var sy = 0; sy < array_length(shape); ++sy) {
    for (var sx = 0; sx < array_length(shape[sy]); ++sx) {
        var cell = shape[sy][sx];
        if (cell == Cell.Empty) continue;
        var px = x+sx*size, py = y+sy*size;
        draw_set_color(module_color);
        if (!sprite_exists(sprite_index)) {
            if(muted) shader_set(shd_module_unpowered);
            draw_rectangle(px+2,py+2,px+size-2,py+size-2,false);
            if(muted) shader_reset();
        }
        if (device.selected_module == id || global.hover_target == id) {
            draw_set_color(held ? preview_color : c_yellow);
            draw_rectangle(px+2,py+2,px+size-2,py+size-2,true);
        }

        var directions=device.is_recycler?[]:cell_directions(cell);
        for(var di=0;di<array_length(directions);++di) {
            var contact = port_rect(px,py,size,directions[di]);
            var port = port_reference(id,sx,sy,directions[di]);
            draw_set_color(port_equal(device.hover_port,port) || port_equal(device.wire_start,port) ? c_yellow : port_type_color(cell_port_type(cell)));
            draw_rectangle(contact[0],contact[1],contact[2],contact[3],false);
        }
    }
}
draw_set_color(c_white);
draw_set_alpha(1);

    }
}
