function manual_rebuild(_ui) {
    _ui.fields=[];_ui.buttons=[];_ui.focus=-1;
    var tabs=["My modules","Goal and economy","Manual assembly"];
    for(var i=0;i<3;++i) lab_button(_ui,"tab"+string(i),tabs[i],24+i*225,60,210);
    lab_button(_ui,"save","Save",760,60,145);lab_button(_ui,"load","Load",920,60,145);lab_button(_ui,"exit","Game [F7]",1080,60,175);
    var cfg=_ui.cfg,keys=manual_keys(),labels=manual_labels();
    if(_ui.tab==0) {
        lab_button(_ui,"add","+ Create module",24,120,210);lab_button(_ui,"delete","Delete",244,120,130);
        lab_button(_ui,"prev","<",24,570,60);lab_button(_ui,"next",">",314,570,60);
        var first=_ui.page*9;
        for(var i=first;i<min(first+9,array_length(cfg.modules));++i)
            lab_button(_ui,"select"+string(i),string(i+1)+". "+(cfg.modules[i].name==""?"[enter name]":cfg.modules[i].name),24,170+(i-first)*42,350);
        if(array_length(cfg.modules)>0) {
            _ui.selected=clamp(_ui.selected,0,array_length(cfg.modules)-1);var item=cfg.modules[_ui.selected];
            lab_field(_ui,item,"name","Name",420,165,430);
            lab_field(_ui,item,"drop_weight","Drop weight (0 = no drops)",420,245,430);
            for(var i=0;i<4;++i) lab_field(_ui,item.stats,keys[i],labels[i],420+(i mod 2)*230,330+(i div 2)*85,200);
        }
    }
    if(_ui.tab==1) {
        lab_field(_ui,cfg,"slots","Maximum modules",24,150,200);lab_field(_ui,cfg,"min_installed","Minimum modules",250,150,200);
        for(var i=0;i<4;++i) {
            lab_field(_ui,cfg.base,keys[i],"",185,250+i*65,140);
            lab_field(_ui,cfg.min,keys[i],"",350,250+i*65,140);
            lab_field(_ui,cfg.max,keys[i],"",515,250+i*65,140);
        }
        var specs=[["start_money","Starting cash"],["gift","{coin} per click"],["device_price","Price per device"],["batch","Devices per purchase"],
            ["loot_min","Modules per device: min"],["loot_max","Modules per device: max"],["gift_seconds","Seconds per click"],["dismantle_seconds","Seconds to dismantle"],["seed","Seed"]];
        for(var i=0;i<array_length(specs);++i) lab_field(_ui,cfg,specs[i][0],specs[i][1],710+(i mod 2)*275,150+(i div 2)*83,250);
    }
    if(_ui.tab==2 && !is_undefined(_ui.run)) {
        var run=_ui.run,e=run.model.econ;
        lab_button(_ui,"money","Get {coin} +"+string(e.gift),24,120,260);
        lab_button(_ui,"buy","Buy "+string(e.batch)+" devices for "+string(e.batch*e.device_price),300,120,360);
        var lists=[run.inventory,run.combination];
        for(var side=0;side<2;++side) {
            var indices=[];
            for(var i=0;i<array_length(lists[side]);++i) if(lists[side][i]>0) array_push(indices,i);
            var page=side==0?_ui.inv_page:_ui.combo_page;page=min(page,max(0,ceil(array_length(indices)/6)-1));
            if(side==0) _ui.inv_page=page;else _ui.combo_page=page;
            for(var row=0;row<6;++row) {
                var at=page*6+row;if(at>=array_length(indices)) break;
                var idx=indices[at];
                lab_button(_ui,(side==0?"put":"take")+string(idx),string_copy(run.model.items[idx].name,1,24)+" x"+string(lists[side][idx])+"  | E:"+string(run.model.items[idx].stats.energy)+" W:"+string(run.model.items[idx].stats.weight)+" H:"+string(run.model.items[idx].stats.heat)+" S:"+string(run.model.items[idx].stats.stability),24+side*630,240+row*34,600);
            }
            lab_button(_ui,side==0?"invprev":"comboprev","<",24+side*630,452,60);
            lab_button(_ui,side==0?"invnext":"combonext",">",564+side*630,452,60);
        }
    }
    lab_button(_ui,"start",is_undefined(_ui.run)?"Start experiment":"Start over",24,660,230);
}
function manual_action(_ui,_action) {
    if(string_copy(_action,1,3)=="tab") {_ui.tab=real(string_copy(_action,4,1));manual_rebuild(_ui);return;}
    if(string_copy(_action,1,6)=="select") {_ui.selected=real(string_delete(_action,1,6));manual_rebuild(_ui);return;}
    if(string_copy(_action,1,3)=="put") {
        if(!manual_move(_ui.run,real(string_delete(_action,1,3)),true)) _ui.notice="No free slots left in this build.";
        else _ui.notice="One module added.";
        manual_rebuild(_ui);return;
    }
    if(string_copy(_action,1,4)=="take") {manual_move(_ui.run,real(string_delete(_action,1,4)),false);_ui.notice="Module returned to inventory.";manual_rebuild(_ui);return;}
    switch(_action) {
        case "add":
            if(array_length(_ui.cfg.modules)>=40) {_ui.notice="Use no more than 40 module types.";break;}
            array_push(_ui.cfg.modules,{name:"",drop_weight:"1",stats:{energy:"0",weight:"0",heat:"0",stability:"0"}});
            _ui.selected=array_length(_ui.cfg.modules)-1;_ui.page=_ui.selected div 9;_ui.dirty=true;break;
        case "delete":
            if(array_length(_ui.cfg.modules)>0) {array_delete(_ui.cfg.modules,_ui.selected,1);_ui.selected=max(0,_ui.selected-1);_ui.page=_ui.selected div 9;_ui.dirty=true;}break;
        case "prev":_ui.page=max(0,_ui.page-1);break;
        case "next":_ui.page=min(max(0,ceil(array_length(_ui.cfg.modules)/9)-1),_ui.page+1);break;
        case "invprev":_ui.inv_page=max(0,_ui.inv_page-1);break;
        case "invnext":_ui.inv_page++;break;
        case "comboprev":_ui.combo_page=max(0,_ui.combo_page-1);break;
        case "combonext":_ui.combo_page++;break;
        case "start":
            var model=manual_validate(_ui.cfg);if(!model.ok) {_ui.notice=model.error;break;}
            _ui.run=manual_start(model);_ui.tab=2;_ui.inv_page=0;_ui.combo_page=0;_ui.dirty=false;
            _ui.notice="Experiment started: earn {coin} and buy devices.";break;
        case "money":manual_money(_ui.run);_ui.notice="{coin} received.";break;
        case "buy":_ui.notice=manual_buy(_ui.run)?"Devices dismantled. Parts stored; cases scrapped.":"Not enough {coin}.";break;
        case "save":
            var handle=file_text_open_write("manual_modules.json");file_text_write_string(handle,json_stringify(_ui.cfg));file_text_close(handle);
            _ui.notice="Catalog and settings saved: manual_modules.json";break;
        case "load":
            if(!file_exists("manual_modules.json")) {_ui.notice="No saved settings.";break;}
            try {
                var handle=file_text_open_read("manual_modules.json"),text_value="";
                while(!file_text_eof(handle)) {text_value+=file_text_read_string(handle);file_text_readln(handle);}file_text_close(handle);
                var loaded=json_parse(text_value);
                // Validate structure even for a deliberately empty saved catalog.
                var probe=json_parse(json_stringify(loaded));
                if(array_length(probe.modules)==0) array_push(probe.modules,{name:"validation",drop_weight:"1",stats:{energy:"0",weight:"0",heat:"0",stability:"0"}});
                var check=manual_validate(probe);
                if(check.ok) {_ui.cfg=loaded;_ui.selected=0;_ui.page=0;_ui.dirty=true;_ui.notice="Loaded. Start over to apply these settings.";}
                else _ui.notice="File not loaded: "+check.error;
            } catch(err) {_ui.notice="Could not read file. Current catalog retained.";}break;
        case "exit":room_goto(Room1);return;
    }
    manual_rebuild(_ui);
}
function manual_step(_ui) {
    _ui.ticks++;
    if(keyboard_check_pressed(vk_f7)) {lab_commit(_ui);manual_action(_ui,"exit");return;}
    if(_ui.focus>=0) {
        if(keyboard_check_pressed(vk_escape)) _ui.focus=-1;
        else if(keyboard_check_pressed(vk_enter)) lab_commit(_ui);
        else if(keyboard_check_pressed(vk_tab)) {
            var next=(_ui.focus+1) mod array_length(_ui.fields);lab_commit(_ui);_ui.focus=next;
            var f=_ui.fields[next];keyboard_string=string(struct_get(f.owner,f.key));
        }
        if(keyboard_check(vk_control)&&keyboard_check_pressed(ord("A"))) keyboard_string="";
        if(string_length(keyboard_string)>80) keyboard_string=string_copy(keyboard_string,1,80);
    }
    if(!mouse_check_button_pressed(mb_left)) return;
    var px=device_mouse_x_to_gui(0),py=device_mouse_y_to_gui(0);lab_commit(_ui);
    for(var i=0;i<array_length(_ui.fields);++i) {
        var f=_ui.fields[i];if(px>=f.x&&px<f.x+f.w&&py>=f.y&&py<f.y+32) {
            _ui.focus=i;keyboard_string=string(struct_get(f.owner,f.key));return;
        }
    }
    for(var i=0;i<array_length(_ui.buttons);++i) {
        var b=_ui.buttons[i];if(px>=b.x&&px<b.x+b.w&&py>=b.y&&py<b.y+32) {manual_action(_ui,b.action);return;}
    }
}
function manual_draw(_ui) {
    draw_clear(make_color_rgb(18,23,32));draw_set_alpha(1);draw_set_font(_ui.font);
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(c_white);
    ui_text(24,16,"MANUAL EXPERIMENT / energy, weight, heat, stability");
    for(var i=0;i<array_length(_ui.buttons);++i) {
        var b=_ui.buttons[i];draw_set_color(b.action=="tab"+string(_ui.tab)?make_color_rgb(54,95,137):make_color_rgb(40,50,66));
        draw_rectangle(b.x,b.y,b.x+b.w,b.y+32,false);draw_set_color(c_white);
        var label=b.label;while(ui_text_width(label)>b.w-16) label=string_delete(label,string_length(label),1);
        ui_text(b.x+8,b.y+6,label);
    }
    for(var i=0;i<array_length(_ui.fields);++i) {
        var f=_ui.fields[i];draw_set_color(make_color_rgb(180,195,210));ui_text(f.x,f.y-23,f.label);
        draw_set_color(i==_ui.focus?make_color_rgb(50,72,100):make_color_rgb(29,37,50));draw_rectangle(f.x,f.y,f.x+f.w,f.y+32,false);
        var value=i==_ui.focus?keyboard_string:string(struct_get(f.owner,f.key));while(ui_text_width(value)>f.w-20) value=string_delete(value,1,1);
        draw_set_color(c_white);ui_text(f.x+8,f.y+6,value+(i==_ui.focus?"|":""));
    }
    var keys=manual_keys(),labels=manual_labels();draw_set_color(make_color_rgb(180,195,210));
    if(_ui.tab==0) {
        if(array_length(_ui.cfg.modules)==0) ui_text_ext(420,165,"The catalog is empty.\nClick Create module and enter its name and stats.\nNo preset modules are added here.",28,700);
        else ui_text_ext(900,160,"Create your own modules.\n\nDrop weight is a relative chance,\nnot the physical weight of a part.\n0 prevents the module from dropping.\n\nCtrl+A clears; Enter applies input.\nNegative and fractional values work.\n\nApply settings with\nStart experiment / Start over.",27,340);
        ui_text(120,578,"Page "+string(_ui.page+1));
    }
    if(_ui.tab==1) {
        ui_text(24,215,"Stat");ui_text(185,215,"Base");ui_text(350,215,"Minimum");ui_text(515,215,"Maximum");
        for(var i=0;i<4;++i) ui_text(24,257+i*65,labels[i]);
        ui_text_ext(24,540,"Empty bound = no limit. min = max = exact goal.\nAll installed modules are active; stats are added together.\nBuying immediately dismantles devices, adds parts and deducts {coin}.\nPurchase cost = device price x number of devices.",25,1230);
    }
    if(_ui.tab==2) {
        if(is_undefined(_ui.run)) ui_text_ext(24,150,"Create modules, set a goal and click Start experiment.\nEarn {coin}, buy devices and assemble a build yourself.",30,1150);
        else {
            var run=_ui.run;
            ui_text(24,175,"{coin}: "+string_format(run.money,0,2)+"    Time: "+string_format(run.seconds/60,0,2)+" min    Devices: "+string(run.devices)+"    Income clicks: "+string(run.clicks));
            ui_text(24,210,"INVENTORY - click to add one module");ui_text(654,210,"BUILD - click to return one module ("+string(run.total)+"/"+string(run.model.econ.slots)+")");
            ui_text(110,458,"Page "+string(_ui.inv_page+1));ui_text(740,458,"Page "+string(_ui.combo_page+1));
            for(var k=0;k<4;++k) {
                var key=keys[k],value=struct_get(run.stats,key),lo=struct_exists(run.model.min,key)?string(struct_get(run.model.min,key)):"-",hi=struct_exists(run.model.max,key)?string(struct_get(run.model.max,key)):"-";
                var fits=(!struct_exists(run.model.min,key)||value>=struct_get(run.model.min,key))&&(!struct_exists(run.model.max,key)||value<=struct_get(run.model.max,key));
                draw_set_color(fits?make_color_rgb(100,220,140):make_color_rgb(255,100,100));
                ui_text(24+(k mod 2)*630,510+(k div 2)*34,labels[k]+": "+string(value)+"    Goal: "+lo+" .. "+hi);
            }
            draw_set_color(run.complete?c_lime:c_red);ui_text(24,590,run.complete?"GOAL MET":"GOAL NOT MET");
            draw_set_color(make_color_rgb(180,195,210));ui_text(450,590,"Minimum modules: "+string(run.model.econ.min_installed)+". Checked after every click.");
            if(_ui.dirty) {draw_set_color(c_yellow);ui_text(24,620,"Settings changed. This build still uses the old values; click Start over.");}
        }
    }
    draw_set_color(c_yellow);ui_text(280,668,string_copy(_ui.notice,1,110));
    draw_set_font(game_font_default());draw_set_color(c_white);
}
