// DEBUG: false disables free infinite parts, order skipping and laboratory shortcuts.
debug_tools = false;
active_screw = noone;
sfx_enabled = true;
screw_sound = -1;
screw_sound_paused = false;
screw_sound_interval = 0.60; // Seconds between audible screwdriver turns.
screw_sound_wait = 0;
sfx_random_state = 1+(get_timer() mod 2147483646);
solder_sound = -1;
ready_sound_device = noone;
ready_sound_state = false;
global.mode = GameMode.Menu;
global.debug_enabled = false;
global.dt = 0;
global.notice = ""; global.notice_time = 0;
global.hover_target = noone;
menu_index = 0;
pointer_ready = false;
input_init();
// Window and GUI use the same resolution: UI keeps its pixel size.
window_set_size(1280,720);
display_set_gui_size(1280,720);

randomize();
device_types = [obj_remote,obj_radio];
show_table=function(){campaign_table(id);};
table_click=function(_px,_py){return campaign_table_click(id,_px,_py);};
inventory_page=0;
sidebar_width = floor(room_width/3);
stats_height = 0; // Recalculated from the active device requirements.
inventory_size = 32;
inventory_x = 16; inventory_y = stats_height+16;
inventory_cols = max(1,floor((sidebar_width-32)/inventory_size));
inventory_rows = max(1,floor((room_height-inventory_y-56)/inventory_size));
inventory_capacity = inventory_cols*inventory_rows;
inventory_footer = inventory_y+inventory_rows*inventory_size+12;
inventory = array_create(inventory_cols*inventory_rows,noone);
active_device = noone;
active_type = obj_remote;
start_device = function(_type) {
    if (instance_exists(active_device)) instance_destroy(active_device);
    global.hover_target = noone;
    global.notice_time = 0;
    active_type = _type;
    active_device = campaign_create_device(_type);
    global.mode = GameMode.Play;
    pointer_ready = false;
};

gpu_set_texfilter(false);

depth = -1000; // Wires above world modules, below Draw GUI menus.

// Larger Edit Undo font for the circuit status label.
circuit_font = game_font_create(24);

// Set the table at runtime: the room editor may still have an empty Background.
var table_layer = layer_get_id("Background");
if (table_layer == -1) table_layer = layer_create(100,"Background");
layer_depth(table_layer,100);
layer_set_visible(table_layer,true);
var table_background = layer_background_get_id(table_layer);
if (table_background == -1) table_background = layer_background_create(table_layer,spr_table);
layer_background_sprite(table_background,spr_table);
layer_background_blend(table_background,c_white);
layer_background_alpha(table_background,1);
layer_background_stretch(table_background,true);
money=debug_tools?1000:50;earn_remaining=0;earn_duration=5;table_devices=[];finish_confirm=false;
table_plate=false; // At most one plate on the table, including manual soldering.
table_pixel_scale=3; // Shared integer pixel scale for 64px table devices and plates.
campaign_devices_created=0;
purchases={};robots=[];scrap=debug_tools?50:0;
robot_stack_front=[0,0,0,0]; // Recycler, assembler, solder, dismantler.
generator=campaign_create_device(obj_generator);
campaign_visible(generator,false);
upgrade_power={};power_capacity=0;power_used=0;power_demand=0;
recycler_robot=robot_create_recycler(id);
shop_apply(id);
shop=instance_create_depth(0,0,-2000,obj_shop);
// Shared gameplay and lab module list: game_module_types() in scr_campaign.
module_types = game_module_types();

ui_font=game_font_create(18);
draw_set_font(ui_font);
// Six authored orders; subsequent ones are created by scr_orders.
order_types=[obj_order,obj_order_2,obj_order_3,obj_order_4,obj_order_5,obj_order_6];
order_index=0;orders_finished=false;
orders_init(id);
order_device=orders_create(id);
campaign_visible(order_device,false);
// A free first donor makes the initial action visible on the table.
campaign_add_device(id);
inventory_debug_seed(id);
