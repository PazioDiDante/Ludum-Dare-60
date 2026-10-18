function repair_tests() {
 global.test_passes=0;global.test_failures=0;var g=obj_game;
 var spare=instance_create_depth(0,0,0,obj_module_battery);inventory_add(g,spare);
 var kinds=[obj_remote,obj_radio];
 for(var k=0;k<2;++k) {
  campaign_table(g);g.money=100;g.device_types=[kinds[k]];campaign_buy(g);var d=g.table_devices[array_length(g.table_devices)-1];campaign_open(g,d);
  base_assert(!campaign_sell(g),"closed device cannot sell");
  d.open_cover();
  base_assert(!d.user_wired&&!campaign_can_sell(g,d)&&!campaign_sell(g),"generated wiring is not a manual repair");
  base_assert(g.stats_height==100,"small device uses same two-row stat UI");
  for(var i=array_length(d.children)-1;i>=0;--i) {var ch=d.children[i];if(instance_exists(ch)&&object_is_ancestor(ch.object_index,par_module)){module_detach(ch);instance_destroy(ch);}}
  var part=instance_create_depth(0,0,0,par_module);part.device=d;part.shape=[[Cell.L,Cell.R]];part.stats={energy:4,stability:3,heat:0,weight:1};array_push(d.children,part);
  var placed=false;for(var r=0;r<d.rows&&!placed;++r)for(var c=0;c<d.cols&&!placed;++c)if(board_place(part,c,r)) placed=true;
  base_assert(placed,"repair fixture fits board");
  var a=board_port_reference(d,0),b=port_reference(part,0,0),c=port_reference(part,1,0),e=board_port_reference(d,1);
  wire_connect(d,a,b);wire_connect(d,c,e);
  base_assert(d.requirements_met&&!campaign_sell(g),"automatic connections do not qualify as user repair");
  wire_click(d,a);wire_click(d,b);
  base_assert(d.user_wired&&campaign_can_sell(g,d),"manual wiring enables valid repair");
  part.stats.energy=0;device_stats_update(d);base_assert(!campaign_sell(g),"invalid stats prevent sale after user action");
  part.stats.weight=1;part.stats.energy=4;device_stats_update(d);
  if(k==0){var surf=surface_create(1280,720);surface_set_target(surf);draw_clear(c_black);campaign_gui_draw(g);surface_reset_target();surface_save(surf,"repair-sale-preview.png");surface_free(surf);}
  // Radio has no maximum energy, so test a low energy violation as well.
  part.stats.energy=0;device_stats_update(d);base_assert(!campaign_sell(g),"energy below goal prevents sale");part.stats.energy=4;device_stats_update(d);
  var cash=g.money,count=array_length(g.table_devices);
  base_assert(campaign_sell(g)&&g.money==cash+40,"valid device pays 40");
  base_assert(!instance_exists(d)&&!instance_exists(part)&&array_length(g.table_devices)==count-1,"sold device and installed modules removed");
  base_assert(instance_exists(spare)&&spare.in_inventory&&global.mode==GameMode.Menu,"inventory preserved and returns to table");
  base_assert(!campaign_sell(g)&&g.money==cash+40,"sale cannot pay twice");
 }
 show_debug_message("REPAIR_TEST_RESULT passes="+string(global.test_passes)+" failures="+string(global.test_failures));game_end();
}
