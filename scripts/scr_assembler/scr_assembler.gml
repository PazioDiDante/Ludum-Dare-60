// Read authored Create fields once; previews are values, never hidden physical loot.
function assembler_setup(_robot) {
    var types=game_module_types();
    for(var i=0;i<array_length(types);++i) {
        var item=instance_create_depth(0,0,0,types[i]);
        array_push(_robot.recipes,{
            object_type:types[i],module_name:item.module_name,stats:item.stats,
            scrap_cost:item.scrap_cost,unlock_after_orders:item.unlock_after_orders,
            shape:item.shape,sprite_index:item.sprite_index,image_index:0,
            rotation_steps:0,image_blend:item.image_blend,module_color:item.module_color
        });
        instance_destroy(item);
    }
    _robot.board_device=campaign_create_device(obj_assembler_board);
    _robot.board_device.robot_owner=_robot;
    campaign_visible(_robot.board_device,false);
}
function assembler_available(_g,_robot) {
    var result=[];
    for(var i=0;i<array_length(_robot.recipes);++i)
        if(_g.order_index>=_robot.recipes[i].unlock_after_orders) array_push(result,i);
    return result;
}
function assembler_start(_g,_robot,_index) {
    if(!instance_exists(_robot)||_robot.product_id!="assembler_robot"||_robot.working||array_length(_robot.outputs)>0) return false;
    if(global.mode!=GameMode.Play||_g.active_device!=_robot.board_device) return false;
    if(instance_exists(_robot.board_device.selected_module)) return false;
    if(_index<0||_index>=array_length(_robot.recipes)) return false;
    var recipe=_robot.recipes[_index];
    if(_g.order_index<recipe.unlock_after_orders) return false;
    power_update(_g);
    if(!_robot.powered||_g.scrap<recipe.scrap_cost) return false;
    // Own one real output for the entire job. Its exact authored value survives
    // power loss, switching screens and delayed inventory placement.
    var item=instance_create_depth(0,0,-10,recipe.object_type);
    item.visible=false;item.interaction_enabled=false;
    _g.scrap-=recipe.scrap_cost;
    _robot.target_module=item;_robot.recipe_index=_index;
    _robot.working=true;_robot.remaining=_robot.work_seconds;_robot.work_frame=0;
    return true;
}
function assembler_layout(_g) {
    var screen_width=display_get_gui_width(),width=min(840,screen_width-96);
    var left=floor((screen_width-width)/2),right=left+width;
    return {left:left,right:right,top:180,row_height:120,page_size:max(1,floor((display_get_gui_height()-236)/120))};
}
function assembler_back_rect(_g) {
    var l=assembler_layout(_g);return [l.left,16,l.left+136,50];
}
function assembler_row_rect(_g,_slot) {
    var l=assembler_layout(_g),top=l.top+_slot*l.row_height;
    return [l.left,top,l.right,top+l.row_height-8];
}
function assembler_page_rect(_g,_next) {
    var l=assembler_layout(_g),top=l.top+l.page_size*l.row_height+4;
    return _next?[l.right-48,top,l.right,top+30]:[l.left,top,l.left+48,top+30];
}
function assembler_input(_g,_x,_y) {
    if(global.mode!=GameMode.Play||!instance_exists(_g.active_device)||!_g.active_device.is_assembler) return false;
    var robot=_g.active_device.robot_owner,l=assembler_layout(_g),available=assembler_available(_g,robot);
    var last=max(0,array_length(available)-l.page_size);
    robot.recipe_scroll=clamp(robot.recipe_scroll,0,last);
    if(_x>=l.left&&_x<l.right&&_y>=l.top&&_y<l.top+l.page_size*l.row_height)
        robot.recipe_scroll=clamp(robot.recipe_scroll+mouse_wheel_down()-mouse_wheel_up(),0,last);
    if(!_g.pointer_ready||!input_pressed(Action.Primary)||instance_exists(_g.active_device.selected_module)) return false;
    for(var next=0;next<2;++next) if(campaign_hit(_x,_y,assembler_page_rect(_g,next==1))) {
        robot.recipe_scroll=clamp(robot.recipe_scroll+(next==1?l.page_size:-l.page_size),0,last);return true;
    }
    for(var slot=0;slot<min(l.page_size,array_length(available)-robot.recipe_scroll);++slot)
        if(campaign_hit(_x,_y,assembler_row_rect(_g,slot))) {
            sfx_action(assembler_start(_g,robot,available[robot.recipe_scroll+slot]));return true;
        }
    return false;
}
function assembler_draw(_g,_d) {
    var robot=_d.robot_owner;if(!instance_exists(robot)) return;
    var l=assembler_layout(_g),available=assembler_available(_g,robot);
    robot.recipe_scroll=clamp(robot.recipe_scroll,0,max(0,array_length(available)-l.page_size));
    draw_set_alpha(1);draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_font(_g.ui_font);
    draw_set_color(make_color_rgb(20,27,38));draw_rectangle(l.left-4,56,l.right+4,display_get_gui_height()-12,false);
    draw_set_color(c_ltgray);
    ui_text_ext(l.left+12,64,"Spend scrap to craft the modules your order needs.\nRecycle unwanted modules with the Scrap master to get more scrap.",20,l.right-l.left-24);
    draw_set_color(c_white);draw_text(l.left+12,120,"Modules");
    var status=robot.working?(robot.powered?"Assembling: ":"No power: ")+string(ceil(robot.remaining))+"s":
        (array_length(robot.outputs)>0?"Output waiting for inventory space":(robot.powered?"Choose a module - 30s":"Assign 3 energy at the table"));
    draw_set_color(c_ltgray);draw_text(l.left+12,142,status);
    if(robot.working) {
        robot_module_preview(robot.target_module,[l.right-88,116,l.right-12,158]);
        draw_set_color(make_color_rgb(40,54,65));draw_rectangle(l.left+12,168,l.right-12,174,false);
        draw_set_color(robot.powered?c_aqua:c_gray);draw_rectangle(l.left+12,168,l.left+12+(l.right-l.left-24)*(1-robot.remaining/robot.work_seconds),174,false);
    }
    var keys=game_stat_keys(),icons=game_stat_icons();
    for(var slot=0;slot<min(l.page_size,array_length(available)-robot.recipe_scroll);++slot) {
        var index=available[robot.recipe_scroll+slot],recipe=robot.recipes[index],r=assembler_row_rect(_g,slot);
        var enabled=robot.powered&&!robot.working&&array_length(robot.outputs)==0&&_g.scrap>=recipe.scrap_cost&&!instance_exists(_d.selected_module);
        draw_set_color(make_color_rgb(29,42,55));draw_rectangle(r[0],r[1],r[2],r[3],false);
        draw_set_color(robot.working&&robot.recipe_index==index?c_aqua:make_color_rgb(65,85,105));draw_rectangle(r[0],r[1],r[2],r[3],true);
        robot_module_preview(recipe,[r[0]+12,r[1]+12,r[0]+116,r[3]-12]);
        draw_set_color(c_white);draw_text(r[0]+136,r[1]+6,recipe.module_name);
        // Show the six gameplay stats in two rows of three columns.
        var width=(r[2]-r[0]-160)/3;
        for(var k=0;k<array_length(keys);++k) {
            var px=r[0]+136+(k mod 3)*width,py=r[1]+30+(k div 3)*28;
            var key=keys[k],value=device_stat_value(recipe.stats,key);
            draw_set_color(c_white);
            game_stat_icon(icons[k],px,py);
            draw_set_color(value==0?c_gray:(module_stat_beneficial(key,value)?c_lime:c_red));
            draw_text(px+48,py+4,(value>0?"+":"")+string(value));
        }
        var price=[r[2]-112,r[3]-26,r[2]-8,r[3]-4];
        draw_set_alpha(enabled?1:0.4);campaign_sprite(spr_cog,[price[0],price[1],price[0]+24,price[3]]);
        draw_set_color(c_white);draw_text(price[0]+32,price[1]+2,string(recipe.scrap_cost));draw_set_alpha(1);
    }
    var previous=assembler_page_rect(_g,false),next=assembler_page_rect(_g,true);
    campaign_button(previous,"<",robot.recipe_scroll>0);
    campaign_button(next,">",robot.recipe_scroll<array_length(available)-l.page_size);
    draw_set_font(game_font_default());draw_set_color(c_white);
}
