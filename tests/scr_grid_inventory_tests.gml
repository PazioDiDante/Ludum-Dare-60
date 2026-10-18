function grid_tests() {
 global.test_passes=0;global.test_failures=0;global.mode=GameMode.Play;
 var g=obj_game,d=g.order_device;campaign_open(g,d);d.cover_open=true;var size=g.inventory_size;
 var a=instance_create_depth(0,0,0,obj_module_battery);
 var b=instance_create_depth(0,0,0,obj_module_coil);
 base_assert(inventory_add(g,a)&&inventory_add(g,b),"auto storage places both shapes");
 base_assert(!inventory_can_place(g,b,a.storage_col,a.storage_row,0),"occupied cells block placement");
 var ax=g.inventory_x+(a.storage_col+1)*size+1,ay=g.inventory_y+a.storage_row*size+1;
 var slot=inventory_slot(g,ax,ay);
 base_assert(g.inventory[slot]==a,"click second cell finds same module");
 base_assert(inventory_pick(g,slot,ax,ay)&&a.grab_col==1&&a.grab_row==0,"pickup preserves actual cell offset");
 base_assert(a.storage_preview&&a.x==g.inventory_x+a.storage_col*size,"held preview snaps to storage grid");
 base_assert(board_rotate(d)&&array_length(a.shape)==2,"held module rotates");
 base_assert(board_cancel(d)&&g.inventory[slot]==a&&array_length(a.shape)==1,"cancel restores shape and storage slot");
 base_assert(inventory_pick(g,slot,ax,ay),"repick stored module");
 var tx=g.inventory_x+6*size+1,ty=g.inventory_y+3*size+1;
 base_assert(storage_drop(g,tx,ty)&&a.storage_col==5&&a.storage_row==3&&a.device==noone,"move within inventory using offset");
 base_assert(!instance_exists(d.selected_module)&&array_length(a.connections)==0,"storage has no wires or selection");
 base_assert(inventory_pick(g,slot,tx,ty),"pick for board transfer");
 var placed=false;
 for(var r=0;r<d.rows&&!placed;++r)for(var c=0;c<d.cols&&!placed;++c)if(board_can_place(a,c,r)){a.preview_col=c;a.preview_row=r;placed=board_drop(d);}
 base_assert(placed&&!a.in_inventory&&a.inventory_origin<0,"inventory to device board");
 base_assert(board_pick(a,a.x+1,a.y+1),"pick from device board");
 base_assert(storage_drop(g,tx,ty)&&a.in_inventory&&a.device==noone,"device back to inventory");
 base_assert(!instance_exists(d.selected_module),"storage drop clears device selection");
 var page=g.inventory_page;campaign_inventory_page(g,1);base_assert(g.inventory_page==1,"extra storage page available");
 base_assert(inventory_can_place(g,a,0,0,1),"new page is empty");
 g.inventory_page=page;campaign_device_layout(g,d);
 base_assert(a.storage_col==6&&a.storage_row==3,"layout preserves fitting arrangement");
 var surface=surface_create(1280,720);surface_set_target(surface);draw_clear(c_black);storage_draw(g);surface_reset_target();surface_save(surface,"grid-inventory-preview.png");surface_free(surface);
 show_debug_message("GRID_TEST_RESULT passes="+string(global.test_passes)+" failures="+string(global.test_failures));game_end();
}
