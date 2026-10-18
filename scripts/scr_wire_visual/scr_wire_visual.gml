// Cosmetic randomness has its own clock/state and never changes gameplay loot RNG.
function wire_visual_random() {
    static state=0;
    if(state==0) state=1+(get_timer() mod 2147483646);
    state=(state*48271) mod 2147483647;
    return state/2147483647;
}
function wire_visual_color() {
    static last=-1;
    var index=floor(wire_visual_random()*3);
    if(index==last) index=(index+1+floor(wire_visual_random()*2)) mod 3;
    last=index;
    var colors=[make_color_rgb(65,135,255),make_color_rgb(55,205,100),make_color_rgb(240,70,75)];
    return colors[index];
}
function wire_visual_create(_ax,_ay,_bx,_by,_color=undefined) {
    return {
        color:is_undefined(_color)?wire_visual_color():_color,
        phase:wire_visual_random()*pi*2,time:0,quiet_time:0,
        ax:_ax,ay:_ay,bx:_bx,by:_by
    };
}
function wire_visual_tick(_visual,_ax,_ay,_bx,_by,_dt) {
    var moved=abs(_ax-_visual.ax)+abs(_ay-_visual.ay)+abs(_bx-_visual.bx)+abs(_by-_visual.by)>0.1;
    _visual.time+=_dt;
    _visual.quiet_time=moved?0:min(2,_visual.quiet_time+_dt);
    _visual.ax=_ax;_visual.ay=_ay;_visual.bx=_bx;_visual.by=_by;
}
function wire_visual_update(_device,_dt) {
    if(!game_running()) return;
    for(var i=0;i<array_length(_device.wires);++i) {
        var wire=_device.wires[i],a=port_current(wire.a),b=port_current(wire.b);
        if(is_undefined(a)||is_undefined(b)) continue;
        wire_visual_tick(wire.visual,a.x,a.y,b.x,b.y,_dt);
    }
    var start=port_current(_device.wire_start);
    if(!is_undefined(start)) {
        if(is_undefined(_device.wire_draft)) _device.wire_draft=wire_visual_create(start.x,start.y,_device.wire_mouse_x,_device.wire_mouse_y);
        wire_visual_tick(_device.wire_draft,start.x,start.y,_device.wire_mouse_x,_device.wire_mouse_y,_dt);
    }
}
// A quadratic curve: anchored endpoints plus a parabolic 4*t*(1-t) bow.
function wire_curve_point(_ax,_ay,_bx,_by,_t,_visual=undefined) {
    var dx=_bx-_ax,dy=_by-_ay,length=point_distance(_ax,_ay,_bx,_by);
    if(length<0.001) return {x:_ax,y:_ay};
    var sag=min(70,length*0.2),bend_x=-dy/length*sag*0.4,bend_y=sag+dx/length*sag*0.25;
    if(!is_undefined(_visual)) {
        var envelope=sqr(max(0,1-_visual.quiet_time/2));
        bend_x+=sin(_visual.time*14+_visual.phase)*9*envelope;
        bend_y+=sin(_visual.time*11+_visual.phase)*6*envelope;
    }
    var bow=4*_t*(1-_t);
    return {x:lerp(_ax,_bx,_t)+bow*bend_x,y:lerp(_ay,_by,_t)+bow*bend_y};
}
function wire_curve_draw(_ax,_ay,_bx,_by,_visual=undefined) {
    draw_set_color(is_undefined(_visual)?make_color_rgb(65,135,255):_visual.color);
    var segments=clamp(ceil(point_distance(_ax,_ay,_bx,_by)/12),12,48);
    var previous={x:_ax,y:_ay};
    for(var i=1;i<=segments;++i) {
        var point=wire_curve_point(_ax,_ay,_bx,_by,i/segments,_visual);
        draw_line_width(previous.x,previous.y,point.x,point.y,3);
        previous=point;
    }
}
