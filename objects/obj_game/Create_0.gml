// One non-persistent controller in this test room. No singleton or hidden bootstrap.
global.mode = GameMode.Menu;
global.debug_enabled = false;
global.dt = 0;
global.notice = ""; global.notice_time = 0;
menu_index = 0;
input_init();
display_set_gui_size(960, 540);
// Room1 instances are placed in the Room Editor.
