// Catalog is immutable configuration; purchases belong to the game session.
function shop_catalog() {
    return [
        {id:"fast_manual_income",kind:"upgrade",title:"Faster income",description:"Manual income: 2.5s.\nTwice as fast. Buy once.",price:50},
        {id:"fast_unscrew",kind:"upgrade",title:"Fast screwdriver",description:"Unscrew manually: 1s.\nTwice as fast. Buy once.",price:50},
        {id:"solder_robot",kind:"robot",title:"Soldering robot",description:"Plate -> +20 {coin} / 10s.\nNeeds 1 energy.",price:100,energy:1,seconds:10,reward:20},
        {id:"dismantle_robot",kind:"robot",title:"Dismantling robot",description:"Device -> modules / 30s.\nNeeds 1 energy.",price:100,energy:1,seconds:30,reward:0},
        {id:"assembler_robot",kind:"robot",title:"Assembler robot",description:"{scrap} -> module / 30s.\nNeeds 3 energy.",price:100,energy:3,seconds:30,reward:0},
        {id:"recycle_robot",kind:"robot",title:"Scrap master",description:"Module -> {scrap} / 30s.\nNeeds 2 energy.",price:100,energy:2,seconds:30,reward:1}
    ];
}
function shop_owned(_g,_id) {
    return shop_count(_g,_id)>0;
}
// Drawing, clicks and scrolling share the same filtered row order.
function shop_items(_shop) {
    _shop.page_size=shop_layout().page_size;
    var catalog=shop_catalog(),items=[];
    for(var i=0;i<array_length(catalog);++i) {
        var item=catalog[i];
        if(item.kind=="upgrade"&&shop_owned(_shop.game,item.id)) continue;
        array_push(items,item);
    }
    _shop.scroll=clamp(_shop.scroll,0,max(0,array_length(items)-_shop.page_size));
    return items;
}
function shop_count(_g,_id) {
    var catalog=shop_catalog();
    for(var i=0;i<array_length(catalog);++i)
        if(catalog[i].id==_id&&catalog[i].kind=="upgrade")
            return struct_exists(_g.purchases,_id)&&struct_get(_g.purchases,_id)==true?1:0;
    var count=0;
    for(var i=0;i<array_length(_g.robots);++i) {
        var robot=_g.robots[i];
        if(instance_exists(robot)&&robot.product_id==_id) count++;
    }
    return count;
}
// Safe to call again after restoring purchases: no payouts or duplicate instances.
function shop_apply(_g) {
    power_update(_g);
}
function shop_buy(_g,_id) {
    if(global.mode!=GameMode.Menu) return false;
    var catalog=shop_catalog();
    for(var i=0;i<array_length(catalog);++i) {
        var item=catalog[i];
        if(item.id!=_id) continue;
        if(_g.money<item.price) return false;
        if(item.kind=="upgrade") {
            if(shop_owned(_g,item.id)) return false;
            _g.money-=item.price;struct_set(_g.purchases,item.id,true);
            shop_apply(_g);return true;
        }
        var robot=instance_create_depth(0,0,0,obj_robot,{product_id:item.id,energy_cost:item.energy,work_seconds:item.seconds,reward:item.reward});
        array_push(_g.robots,robot);
        if(item.id=="assembler_robot") assembler_setup(robot);
        if(item.id=="recycle_robot") recycler_setup(robot);
        var stack_index=robot_table_group_index(robot),stacks=robots_table_stacks(_g);
        if(stack_index>=0) _g.robot_stack_front[stack_index]=array_length(stacks[stack_index])-1;
        _g.money-=item.price;
        struct_set(_g.purchases,item.id,shop_count(_g,item.id));
        shop_apply(_g);
        return true;
    }
    return false;
}
function shop_button_rect() {
    var w=display_get_gui_width();return [w-168,20,w-24,58];
}
function shop_panel_rect() {
    var w=display_get_gui_width();return [w-floor(w/4),72,w,display_get_gui_height()];
}
function shop_layout() {
    var top=134,row_height=168,footer=display_get_gui_height()-48;
    return {top:top,row_height:row_height,footer:footer,page_size:max(1,floor((footer-top)/row_height))};
}
function shop_scroll(_shop,_delta) {
    var items=shop_items(_shop);
    _shop.scroll=clamp(_shop.scroll+_delta,0,max(0,array_length(items)-_shop.page_size));
}
function shop_scroll_button(_next) {
    var r=shop_panel_rect(),top=shop_layout().footer;
    return _next?[r[2]-64,top,r[2]-16,top+34]:[r[0]+16,top,r[0]+64,top+34];
}
function shop_row_button(_index,_scroll) {
    var r=shop_panel_rect(),l=shop_layout(),top=l.top+(_index-_scroll)*l.row_height;
    return [r[0]+16,top+110,r[2]-16,top+148];
}
// Called by the game before table input, so panel clicks cannot open workpieces.
function shop_click(_shop,_x,_y) {
    if(global.mode!=GameMode.Menu) return false;
    if(campaign_hit(_x,_y,shop_button_rect())) {_shop.open=!_shop.open;sfx_play(snd_click);return true;}
    if(!_shop.open) return false;
    var panel=shop_panel_rect();
    if(!campaign_hit(_x,_y,panel)) {_shop.open=false;sfx_play(snd_click);return true;}
    var catalog=shop_items(_shop);
    for(var next=0;next<2;++next) {
        if(campaign_hit(_x,_y,shop_scroll_button(next==1))) {
            shop_scroll(_shop,next==1?1:-1);sfx_play(snd_click);return true;
        }
    }
    for(var i=_shop.scroll;i<min(array_length(catalog),_shop.scroll+_shop.page_size);++i)
        if(campaign_hit(_x,_y,shop_row_button(i,_shop.scroll))) {
            var bought=shop_buy(_shop.game,catalog[i].id);shop_items(_shop);
            if(sfx_action(bought)) sfx_play(snd_click);return true;
        }
    return true;
}
function shop_draw(_shop) {
    if(global.mode!=GameMode.Menu) return;
    var g=_shop.game;
    draw_set_font(g.ui_font);draw_set_alpha(1);draw_set_halign(fa_left);draw_set_valign(fa_top);
    campaign_button(shop_button_rect(),_shop.open?"Close shop":"Shop");
    if(_shop.open) {
        var r=shop_panel_rect();
        draw_set_color(make_color_rgb(20,27,38));draw_rectangle(r[0],r[1],r[2],r[3],false);
        draw_set_color(make_color_rgb(100,125,150));draw_rectangle(r[0],r[1],r[2]-1,r[3]-1,true);
        draw_set_color(c_white);ui_text(r[0]+16,88,"Shop - {coin} "+string(g.money));
        var catalog=shop_items(_shop),l=shop_layout();
        for(var i=_shop.scroll;i<min(array_length(catalog),_shop.scroll+_shop.page_size);++i) {
            var item=catalog[i],top=l.top+(i-_shop.scroll)*l.row_height;
            draw_set_color(c_white);ui_text_ext(r[0]+16,top,item.title,20,r[2]-r[0]-32);
            draw_set_color(c_ltgray);ui_text_ext(r[0]+16,top+42,item.description,18,r[2]-r[0]-32);
            var count=shop_count(g,item.id),affordable=g.money>=item.price;
            draw_set_color(c_ltgray);ui_text(r[0]+16,top+86,"Owned: "+string(count));
            campaign_button(shop_row_button(i,_shop.scroll),affordable?"Buy {coin} "+string(item.price):"Need {coin} "+string(item.price),affordable);
        }
        if(array_length(catalog)>_shop.page_size) {
            campaign_button(shop_scroll_button(false),"<",_shop.scroll>0);
            campaign_button(shop_scroll_button(true),">",_shop.scroll<array_length(catalog)-_shop.page_size);
            draw_set_color(c_ltgray);draw_set_halign(fa_center);
            ui_text((r[0]+r[2])/2,l.footer+8,string(_shop.scroll+1)+"-"+string(min(array_length(catalog),_shop.scroll+_shop.page_size))+" / "+string(array_length(catalog)));
            draw_set_halign(fa_left);
        }
    }
    draw_set_font(game_font_default());draw_set_color(c_white);
}
