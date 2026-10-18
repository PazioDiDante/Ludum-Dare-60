// Six authored orders, followed by the repeating Tier 2 order.
function orders_copy(_data) {
    var out={},names=struct_get_names(_data);
    for(var i=0;i<array_length(names);++i) struct_set(out,names[i],struct_get(_data,names[i]));
    return out;
}

function orders_apply(_device,_definition) {
    _device.order_tier=struct_exists(_definition,"tier")?_definition.tier:1;
    _device.device_name=_definition.name;
    _device.stats_base=orders_copy(_definition.base);
    _device.stats_min=orders_copy(_definition.min);
    _device.stats_max=orders_copy(_definition.max);
    _device.small_sprite=_definition.small_sprite;
    _device.cover_sprite=_definition.cover_sprite;
    _device.board_sprite=_definition.board_sprite;
    _device.board_mask_sprite=_definition.mask_sprite;
    _device.order_reward=_definition.reward;
}

function orders_rotate(_shape) {
    var h=array_length(_shape),w=array_length(_shape[0]),out=[];
    for(var row=0;row<w;++row) {
        var line=[];
        for(var col=0;col<h;++col) array_push(line,cell_rotate(_shape[h-1-col][row]));
        array_push(out,line);
    }
    return out;
}

function orders_create(_g) {
    if(_g.order_index<array_length(_g.order_types)) return campaign_create_device(_g.order_types[_g.order_index]);
    return instance_create_depth(floor(room_width/3)+(room_width-floor(room_width/3))/2,
        (80+room_height-48)/2,0,obj_big_order,{work_layout:true,order_definition:orders_tier2_definition()});
}

function orders_tier2_definition() {
    return {name:"Big order / Tier 2",tier:2,
        base:{energy:0,heat:0,stability:0,weight:0,speed:0,efficiency:0,accuracy:0,wear:0},
        min:{energy:3,heat:0,stability:0,speed:2},
        max:{energy:7,heat:5,stability:5,speed:5},
        small_sprite:spr_drone_small,cover_sprite:spr_drone_cover,
        board_sprite:spr_drone_board,mask_sprite:spr_drone_board,
        reward:300};
}
