// Select before measuring as well as drawing; Cyrillic must not be clipped as empty glyphs.
function lab_text_font(_ui,_text) {
    var value=string(_text);
    for(var i=1;i<=string_length(value);++i) {
        var code=string_ord_at(value,i);
        if(code>=1024&&code<=1279) return _ui.cyrillic_font;
    }
    return _ui.font;
}
function lab_field(_ui,_owner,_key,_label,_x,_y,_w=180) {
    array_push(_ui.fields,{owner:_owner,key:_key,label:_label,x:_x,y:_y,w:_w});
}
function lab_button(_ui,_action,_label,_x,_y,_w=160) {
    array_push(_ui.buttons,{action:_action,label:_label,x:_x,y:_y,w:_w});
}
function lab_commit(_ui) {
    if(_ui.focus<0 || _ui.focus>=array_length(_ui.fields)) return;
    var field=_ui.fields[_ui.focus];
    if(struct_exists(field,"read_only")&&field.read_only) {_ui.focus=-1;return;}
    struct_set(field.owner,field.key,keyboard_string);
    _ui.focus=-1;_ui.dirty=true;_ui.analysis_delay=20;
}
function lab_rebuild(_ui) {
    ana_defaults(_ui.cfg);
    _ui.fields=[];_ui.buttons=[];_ui.focus=-1;
    var names=["Order","Modules","Economy","Analysis","Progression"];
    for(var i=0;i<5;++i) lab_button(_ui,"tab"+string(i),names[i],24+i*145,60,137);
    lab_button(_ui,"save","Save",780,60,130);
    lab_button(_ui,"load","Load",920,60,130);
    lab_button(_ui,"exit","Game [F6]",1060,60,190);
    var cfg=_ui.cfg,keys=game_stat_keys();
    if(_ui.tab==0) {
        lab_field(_ui,cfg,"slots","Module search limit",24,140,200);
        lab_field(_ui,cfg,"min_installed","Minimum modules",250,140,200);
        lab_button(_ui,"power",cfg.allow_unpowered?"OFF states: enabled":"OFF states: disabled",490,140,270);
        for(var i=0;i<array_length(keys);++i) {
            var yy=224+i*48;
            lab_field(_ui,cfg.base,keys[i],"",220,yy,160);
            lab_field(_ui,cfg.min,keys[i],"",410,yy,160);
            lab_field(_ui,cfg.max,keys[i],"",600,yy,160);
        }
    }
    if(_ui.tab==1) {
        lab_button(_ui,"add","+ Module",24,112,145);
        lab_button(_ui,"delete","Delete",179,112,145);
        lab_button(_ui,"prev","<",24,592,65);lab_button(_ui,"next",">",260,592,65);
        var first=_ui.module_page*10;
        for(var i=first;i<min(first+10,array_length(cfg.modules));++i)
            lab_button(_ui,"module"+string(i),string(i+1)+". "+cfg.modules[i].name,24,160+(i-first)*40,300);
        if(array_length(cfg.modules)>0) {
            _ui.selected=clamp(_ui.selected,0,array_length(cfg.modules)-1);
            var item=cfg.modules[_ui.selected];
            lab_field(_ui,item,"name","Name",360,145,440);
            lab_field(_ui,item,"qty","In stock (units)",360,218,200);
            var bonus=struct_exists(item,"adapter_bonus")&&item.adapter_bonus;
            lab_field(_ui,item,"drop_weight",bonus?"Weight (bonus only)":"Drop weight",590,218,210);
            for(var i=0;i<array_length(keys);++i) lab_field(_ui,item.stats,keys[i],keys[i],360+(i mod 2)*235,300+(i div 2)*75,205);
        }
    }
    if(_ui.tab==2) {
        var econ_fields=[
            ["start_money","Starting cash"],["device_price","Device price"],
            ["order_price","Order reward"],["repair_price","Repaired device price"],
            ["gift","{coin} per click"],["gift_seconds","Seconds per click"],
            ["dismantle_seconds","Seconds to dismantle"],["repair_seconds","Seconds per repair"],
            ["assembly_seconds","Order assembly seconds"],["batch_min","Devices per batch: min"],
            ["batch_max","Devices per batch: max"],["loot_min","Modules per device: min"],
            ["loot_max","Modules per device: max"],["trials","Number of runs"],
            ["device_limit","Dismantling limit per run"],["seed","Seed (repeatable runs)"]];
        for(var i=0;i<array_length(econ_fields);++i)
            lab_field(_ui,cfg,econ_fields[i][0],econ_fields[i][1],24+(i mod 4)*310,150+(i div 4)*100,275);
    }
    ana_ui_controls(_ui);
    lab_button(_ui,"run",_ui.cfg.use_initial_state?"Run with stock":"Run from zero",24,660,180);
    lab_button(_ui,"stop","Stop",216,660,180);
    lab_button(_ui,"defaults","Reset settings",408,660,200);
}
function lab_save(_ui,_filename = "balance_settings.json") {
    var handle=file_text_open_write(_filename);
    file_text_write_string(handle,json_stringify(_ui.cfg));file_text_close(handle);
    _ui.notice="Settings saved: balance_settings.json in the game save folder.";
}
function lab_load(_ui,_filename = "balance_settings.json") {
    if(!file_exists(_filename)) {_ui.notice="No saved settings yet.";return;}
    try {
        var handle=file_text_open_read(_filename),text_value="";
        while(!file_text_eof(handle)) {text_value+=file_text_read_string(handle);file_text_readln(handle);}
        file_text_close(handle);
        var loaded=json_parse(text_value),check=lab_validate(loaded);
        if(!check.ok) {_ui.notice="File not loaded: "+check.error;return;}
        lab_sync_names(loaded);
        lab_add_progression_modules(loaded);
        _ui.cfg=loaded;_ui.selected=0;_ui.module_page=0;_ui.dirty=true;
        _ui.notice="Settings loaded.";
    } catch(err) {_ui.notice="Could not read settings. Current values retained.";}
}
function lab_action(_ui,_action) {
    if(ana_ui_action(_ui,_action)) return;
    if(string_copy(_action,1,3)=="tab") {_ui.tab=real(string_copy(_action,4,1));lab_rebuild(_ui);return;}
    if(string_copy(_action,1,6)=="module") {_ui.selected=real(string_delete(_action,1,6));lab_rebuild(_ui);return;}
    switch(_action) {
        case "power":_ui.cfg.allow_unpowered=!_ui.cfg.allow_unpowered;_ui.dirty=true;break;
        case "prev":_ui.module_page=max(0,_ui.module_page-1);break;
        case "next":_ui.module_page=min(max(0,ceil(array_length(_ui.cfg.modules)/10)-1),_ui.module_page+1);break;
        case "add":
            if(array_length(_ui.cfg.modules)>=40) {_ui.notice="At most 40 types.";break;}
            var item={name:"Module "+string(current_time),qty:"0",drop_weight:"1",stats:{}};
            var keys=bal_keys();for(var k=0;k<array_length(keys);++k) struct_set(item.stats,keys[k],"0");
            array_push(_ui.cfg.modules,item);_ui.selected=array_length(_ui.cfg.modules)-1;
            _ui.module_page=_ui.selected div 10;_ui.dirty=true;break;
        case "delete":
            if(array_length(_ui.cfg.modules)>1) {array_delete(_ui.cfg.modules,_ui.selected,1);_ui.selected=max(0,_ui.selected-1);_ui.module_page=_ui.selected div 10;_ui.dirty=true;}
            else _ui.notice="Keep at least one type.";
            break;
        case "save":lab_save(_ui);break;
        case "load":lab_load(_ui);break;
        case "defaults":
            if(!_ui.confirm_reset) {_ui.confirm_reset=true;_ui.notice="Click Reset settings again to confirm.";return;}
            _ui.cfg=lab_defaults();lab_sync_game(_ui.cfg);_ui.selected=0;_ui.module_page=0;_ui.dirty=true;_ui.confirm_reset=false;break;
        case "economy_run":
            var checked=lab_validate(_ui.cfg);
            if(!checked.ok) {_ui.notice=checked.error;break;}
            _ui.job=lab_job(checked);_ui.tab=3;_ui.analysis_view=2;_ui.dirty=false;_ui.notice="Calculation started using the current settings.";
            _ui.report=lab_report(_ui.job);break;
        case "stop":
            if(!is_undefined(_ui.job) && (_ui.job.phase=="count" || _ui.job.phase=="simulate")) {
                _ui.job.phase="stopped";_ui.job.message="Stopped by user. Results are partial.";_ui.report=lab_report(_ui.job);
            }break;
        case "exit":
            global.balance_config=_ui.cfg;
            room_goto(Room1);return;
    }
    if(_ui.dirty) _ui.analysis_delay=20;
    lab_rebuild(_ui);
}
function lab_ui_step(_ui) {
    if(keyboard_check_pressed(vk_f7)) {lab_commit(_ui);room_goto(rm_manual);return;}
    _ui.ticks++;
    if(keyboard_check_pressed(vk_f6)) {lab_commit(_ui);lab_action(_ui,"exit");return;}
    if(_ui.focus>=0) {
        if(keyboard_check_pressed(vk_escape)) {_ui.focus=-1;}
        else if(keyboard_check_pressed(vk_enter)) lab_commit(_ui);
        else if(keyboard_check_pressed(vk_tab)) {
            var next=(_ui.focus+1) mod array_length(_ui.fields);lab_commit(_ui);
            repeat(array_length(_ui.fields)) {
                var candidate=_ui.fields[next];
                if(!struct_exists(candidate,"read_only")||!candidate.read_only) break;
                next=(next+1) mod array_length(_ui.fields);
            }
            _ui.focus=next;var f=_ui.fields[next];keyboard_string=string(struct_get(f.owner,f.key));
        }
        if(keyboard_check(vk_control) && keyboard_check_pressed(ord("A"))) keyboard_string="";
        if(string_length(keyboard_string)>100) keyboard_string=string_copy(keyboard_string,1,100);
    }
    if(mouse_check_button_pressed(mb_left)) {
        var px=device_mouse_x_to_gui(0),py=device_mouse_y_to_gui(0);
        lab_commit(_ui);
        for(var i=0;i<array_length(_ui.fields);++i) {
            var f=_ui.fields[i];
            if(px>=f.x && px<f.x+f.w && py>=f.y && py<f.y+32) {
                if(struct_exists(f,"read_only")&&f.read_only) {_ui.notice="This value comes from the game object's Create event. Edit it and restart.";return;}
                _ui.focus=i;keyboard_string=string(struct_get(f.owner,f.key));return;
            }
        }
        for(var i=0;i<array_length(_ui.buttons);++i) {
            var b=_ui.buttons[i];
            if(px>=b.x && px<b.x+b.w && py>=b.y && py<b.y+32) {lab_action(_ui,b.action);break;}
        }
    }
    if(!is_undefined(_ui.job)) {
        var old_phase=_ui.job.phase;
        if(old_phase=="count") lab_count_step(_ui.job,1000);
        else if(old_phase=="simulate") lab_sim_step(_ui.job,2000);
        if(_ui.ticks mod 15==0 || old_phase!=_ui.job.phase) _ui.report=lab_report(_ui.job);
        if(old_phase!=_ui.job.phase && _ui.job.phase=="done") _ui.notice="Calculation complete.";
    }
    ana_ui_step(_ui);
}
function lab_ui_draw(_ui) {
    draw_clear(make_color_rgb(18,23,32));draw_set_alpha(1);
    draw_set_font(_ui.font);draw_set_halign(fa_left);draw_set_valign(fa_top);
    draw_set_color(c_white);ui_text(24,16,"BALANCE LAB / calculations separate from gameplay");
    for(var i=0;i<array_length(_ui.buttons);++i) {
        var b=_ui.buttons[i];
        var selected=b.action=="tab"+string(_ui.tab) || b.action=="module"+string(_ui.selected);
        draw_set_color(selected?make_color_rgb(54,95,137):make_color_rgb(40,50,66));
        draw_rectangle(b.x,b.y,b.x+b.w,b.y+32,false);
        draw_set_color(c_white);
        draw_set_font(lab_text_font(_ui,b.label));
        var label=b.label;while(ui_text_width(label)>b.w-16&&string_length(label)>0) label=string_delete(label,string_length(label),1);
        ui_text(b.x+8,b.y+6,label);
        draw_set_font(_ui.font);
    }
    for(var i=0;i<array_length(_ui.fields);++i) {
        var f=_ui.fields[i];
        draw_set_color(make_color_rgb(170,185,205));ui_text(f.x,f.y-23,f.label);
        draw_set_color(i==_ui.focus?make_color_rgb(50,72,100):make_color_rgb(29,37,50));
        draw_rectangle(f.x,f.y,f.x+f.w,f.y+32,false);
        draw_set_color(c_white);
        var text_value=i==_ui.focus?keyboard_string:string(struct_get(f.owner,f.key));
        draw_set_font(lab_text_font(_ui,text_value));
        while(ui_text_width(text_value)>f.w-16) text_value=string_delete(text_value,1,1);
        ui_text(f.x+8,f.y+6,text_value+(i==_ui.focus && (_ui.ticks div 25) mod 2==0?"|":""));
        draw_set_font(_ui.font);
    }
    draw_set_color(make_color_rgb(180,195,212));
    if(_ui.tab==0) {
        ui_text(24,198,"Stat");ui_text(220,198,"Device base");ui_text(410,198,"Minimum");ui_text(600,198,"Maximum");
        var keys=game_stat_keys();for(var i=0;i<array_length(keys);++i) ui_text(24,230+i*48,keys[i]);
        ui_text_ext(810,200,"Source: obj_order > Create.\nstats_base / stats_min / stats_max.\nThese are starting values.\nEdit fields to experiment.\nEmpty bound = no limit.\n\nStats are added together.\nOFF modules still add weight.\n\nModule order does not matter.\nGeometry and wiring are not simulated.\n\nCtrl+A clears the selected field.\nEnter applies; Esc cancels input.\nUse a dot for decimals.",25,420);
    }
    if(_ui.tab==1) {
        ui_text(110,598,"Page "+string(_ui.module_page+1));
        var selected=_ui.cfg.modules[_ui.selected];
        var bonus=struct_exists(selected,"adapter_bonus")&&selected.adapter_bonus;
        var help=bonus?"ADAPTER BONUS\n33% chance per opened device.\nOne random adapter, on top of\nthe ordinary modules.\nAvailable after three orders.\nRequires free space on the board.\n\nNormal drop weight is zero.\nAdapters do not replace ordinary\nparts in the weighted pool.\n\nThe numerical lab does not simulate\nbonus adapters or typed wiring.\nExisting adapter stock is usable.":"Source: module Create events.\nList: game_module_types().\nStarting values come from gameplay.\nEdit names, stats and drop weights.\nNew modules exist only in this lab.\n\nQuantity = starting stock.\nDrop weight = relative chance.\n1 and 1: equal probability.\n2 and 1: first drops twice as often.\n0: no drops; existing stock is usable.\n\nOne device may contain multiple\nmodules of the same type.\n\nStarting stock is empty by default.\nAnalysis updates after confirming\nyour changes.";
        ui_text_ext(850,145,help,25,395);
    }
    if(_ui.tab==2) {
        ui_text_ext(24,545,"Buying: take a batch of 3-4 (or the configured range) if affordable; otherwise buy one.\nIf funds are low, earn {coin} until one device is affordable. Dismantled cases are scrapped.\nCheck the order after each dismantling and at the start. Pay the order reward once.\nRepair price is used only to compare income; runs do not automatically repair devices.",24,1230);
    }
    if(_ui.tab==3) ana_dashboard(_ui);
    if(_ui.tab==4) ana_progress_draw(_ui);
    draw_set_color(c_yellow);ana_text(24,698,_ui.notice,1230);
    draw_set_font(game_font_default());draw_set_color(c_white);
}

function ana_ui_init(_ui) {
    if(!struct_exists(_ui.cfg,"game_linked")||!_ui.cfg.game_linked) lab_sync_game(_ui.cfg);
    else lab_sync_names(_ui.cfg);
    lab_add_progression_modules(_ui.cfg);
    ana_defaults(_ui.cfg);_ui.analysis=undefined;_ui.progression=undefined;_ui.analysis_error="";
    _ui.analysis_delay=20;_ui.dirty=true;_ui.analysis_view=0;_ui.build_kind=0;
    _ui.build_index=0;_ui.usage_page=0;_ui.progress_row=0;_ui.progress_list_page=0;
    _ui.analysis_thresholds={easy:25,rare:5,pressure:80};_ui.leftover_page=0;
}
function ana_ui_controls(_ui) {
    ana_defaults(_ui.cfg);
    if(_ui.tab==2) lab_button(_ui,"initial_state",_ui.cfg.use_initial_state?"Use starting stock: yes":"Use starting stock: no",640,660,340);
    if(_ui.tab==3) lab_button(_ui,"inventory_run","Check inventory",640,660,220);
    if(_ui.tab==3) {
        lab_button(_ui,"overview","Overview",24,103,140);lab_button(_ui,"builds","Builds",176,103,140);
        lab_button(_ui,"economy_view","Gameplay loop",328,103,180);
        lab_button(_ui,"leftovers","After order",520,103,180);
        if(_ui.analysis_view==3) {lab_button(_ui,"left_prev","<",1100,103,48);lab_button(_ui,"left_next",">",1160,103,48);}
        if(_ui.analysis_view==0) {lab_button(_ui,"usage_prev","<",1100,198,48);lab_button(_ui,"usage_next",">",1160,198,48);}
        if(_ui.analysis_view==1) {
            lab_button(_ui,"build_kind","All / minimal / near",550,103,250);
            lab_button(_ui,"build_prev","<",820,103,48);lab_button(_ui,"build_next",">",880,103,48);
        }
    }
    if(_ui.tab==4) {
        var modes=["Random loot","Device contents","Inventory snapshots"];
        lab_button(_ui,"progress_mode",modes[_ui.cfg.progression_mode],24,124,250);
        lab_button(_ui,"progress_run","Analyze Progression",288,124,230);
        lab_field(_ui,_ui.cfg,"analysis_steps","Stages (random)",540,124,160);
        lab_field(_ui,_ui.cfg,"trials","Runs (random)",720,124,160);
        lab_field(_ui,_ui.cfg,"seed","Seed",900,124,150);
        lab_field(_ui,_ui.cfg,"easy_rate","TOO EASY, % >=",24,190,170);
        lab_field(_ui,_ui.cfg,"rare_rate","RARELY USED, % <",214,190,180);
        lab_field(_ui,_ui.cfg,"pressure_rate","BOTTLENECK, % >=",414,190,190);
        if(_ui.cfg.progression_mode!=0) {
            lab_button(_ui,"progress_add","+ Row",640,190,130);lab_button(_ui,"progress_delete","Delete",780,190,130);
            lab_button(_ui,"progress_prev","<",920,190,48);lab_button(_ui,"progress_next",">",980,190,48);
            var rows=_ui.cfg.progression_rows;
            if(array_length(rows)>0) {
                _ui.progress_row=clamp(_ui.progress_row,0,array_length(rows)-1);
                lab_field(_ui,rows[_ui.progress_row],"name","Row name "+string(_ui.progress_row+1),24,264,220);
                lab_field(_ui,rows[_ui.progress_row],"counts","Count of each module type, comma-separated (Modules tab order)",264,264,970);
            }
        }
        lab_button(_ui,"progress_page_prev","< Previous",1020,332,100);lab_button(_ui,"progress_page_next","Next >",1130,332,110);
    }
}
function ana_ui_start(_ui,_progress) {
    _ui.analysis_error="";
    var checked=lab_validate(_ui.cfg);
    if(!checked.ok) {_ui.analysis_error=checked.error;_ui.notice=checked.error;return;}
    var easy=lab_number(_ui.cfg.easy_rate),rare=lab_number(_ui.cfg.rare_rate),pressure=lab_number(_ui.cfg.pressure_rate);
    if(is_undefined(easy)||is_undefined(rare)||is_undefined(pressure)||min(easy,rare,pressure)<0||max(easy,rare,pressure)>100) {
        _ui.analysis_error="Warning thresholds must be between 0 and 100%.";_ui.notice=_ui.analysis_error;return;
    }
    _ui.analysis_thresholds={easy:easy,rare:rare,pressure:pressure};
    _ui.dirty=false;
    if(_progress) {
        var job=ana_progress_job(checked,_ui.cfg);
        if(job.phase=="error") {_ui.notice=job.error;return;}
        _ui.progression=job;_ui.tab=4;_ui.progress_list_page=0;
        _ui.notice="Progression: stage 0 is starting stock; orders do not consume parts between stages.";
    } else {
        _ui.analysis=ana_job(checked,ana_inventory(checked));_ui.build_index=0;_ui.usage_page=0;
        _ui.notice="Analyze current stock. Permutations excluded; ON/OFF are distinct states.";
    }
}
function ana_ui_action(_ui,_action) {
    switch(_action) {
        case "run":
            var checked=lab_workflow_model(_ui.cfg);
            if(!checked.ok) {_ui.analysis_error=checked.error;_ui.notice=checked.error;_ui.tab=3;_ui.analysis_view=0;lab_rebuild(_ui);return true;}
            _ui.job=lab_job(checked);_ui.analysis_view=2;_ui.tab=3;_ui.dirty=false;
            _ui.report=lab_report(_ui.job);
            _ui.notice=_ui.cfg.use_initial_state?"Simulation with the configured stock and cash.":"From zero: 0 {coin}, 0 parts. Earn > buy > dismantle > check order.";
            lab_rebuild(_ui);return true;
        case "inventory_run":ana_ui_start(_ui,false);_ui.tab=3;_ui.analysis_view=0;lab_rebuild(_ui);return true;
        case "initial_state":_ui.cfg.use_initial_state=!_ui.cfg.use_initial_state;_ui.dirty=true;break;
        case "progress_run":ana_ui_start(_ui,true);lab_rebuild(_ui);return true;
        case "refresh_game":lab_sync_game(_ui.cfg);_ui.dirty=true;_ui.notice="Modules and requirements refreshed from game objects.";break;
        case "leftovers":_ui.analysis_view=3;break;
        case "left_prev":_ui.leftover_page=max(0,_ui.leftover_page-1);break;
        case "left_next":_ui.leftover_page++;break;
        case "overview":_ui.analysis_view=0;break;
        case "builds":_ui.analysis_view=1;break;
        case "economy_view":_ui.analysis_view=2;break;
        case "build_kind":_ui.build_kind=(_ui.build_kind+1) mod 3;_ui.build_index=0;break;
        case "build_prev":_ui.build_index=max(0,_ui.build_index-1);break;
        case "build_next":_ui.build_index++;break;
        case "usage_prev":_ui.usage_page=max(0,_ui.usage_page-1);break;
        case "usage_next":_ui.usage_page++;break;
        case "progress_page_prev":_ui.progress_list_page=max(0,_ui.progress_list_page-1);break;
        case "progress_page_next":_ui.progress_list_page++;break;
        case "progress_mode":_ui.cfg.progression_mode=(_ui.cfg.progression_mode+1) mod 3;_ui.dirty=true;break;
        case "progress_add":
            if(array_length(_ui.cfg.progression_rows)>=16) {_ui.notice="Limit: 16 custom rows.";return true;}
            var zeros="";for(var i=0;i<array_length(_ui.cfg.modules);++i) zeros+=(i>0?",":"")+"0";
            array_push(_ui.cfg.progression_rows,{name:"Stage "+string(array_length(_ui.cfg.progression_rows)+1),counts:zeros});
            _ui.progress_row=array_length(_ui.cfg.progression_rows)-1;_ui.dirty=true;break;
        case "progress_delete":
            if(array_length(_ui.cfg.progression_rows)>0) array_delete(_ui.cfg.progression_rows,_ui.progress_row,1);
            _ui.progress_row=max(0,_ui.progress_row-1);_ui.dirty=true;break;
        case "progress_prev":_ui.progress_row=max(0,_ui.progress_row-1);break;
        case "progress_next":_ui.progress_row=min(max(0,array_length(_ui.cfg.progression_rows)-1),_ui.progress_row+1);break;
        case "stop":
            _ui.dirty=false;
            if(!is_undefined(_ui.analysis)&&!ana_finished(_ui.analysis)) {_ui.analysis.phase="stopped";_ui.analysis.partial=true;}
            if(!is_undefined(_ui.progression)&&_ui.progression.phase!="done") {_ui.progression.phase="stopped";_ui.progression.min_status="N/A: stopped";}
            return false; // Existing economy cancellation still runs.
        default:return false;
    }
    if(_ui.dirty) _ui.analysis_delay=20;
    lab_rebuild(_ui);return true;
}
function ana_ui_step(_ui) {
    if(_ui.dirty&&_ui.focus<0) {
        _ui.analysis_delay--;
        if(_ui.analysis_delay<=0) {
            // Changed configs invalidate results. Never silently mix old progression with new inputs.
            _ui.progression=undefined;_ui.analysis=undefined;_ui.dirty=false;ana_ui_start(_ui,false);
        }
    }
    if(!_ui.dirty && !is_undefined(_ui.analysis)) ana_step(_ui.analysis,700);
    if(!_ui.dirty && !is_undefined(_ui.progression)) ana_progress_step(_ui.progression,700);
}
function ana_text(_x,_y,_text,_width=1200) {
    var text_value=string(_text);
    var old_font=draw_get_font();
    if(instance_exists(obj_balance_lab)) draw_set_font(lab_text_font(obj_balance_lab,text_value));
    while(ui_text_width(text_value)>_width&&string_length(text_value)>0) text_value=string_delete(text_value,string_length(text_value),1);
    ui_text(_x,_y,text_value);
    draw_set_font(old_font);
}
function ana_box(_x,_y,_w,_h) {
    draw_set_color(make_color_rgb(28,37,50));draw_rectangle(_x,_y,_x+_w,_y+_h,false);draw_set_color(c_white);
}
function ana_bar(_x,_y,_w,_fraction,_colour) {
    draw_set_color(make_color_rgb(44,54,68));draw_rectangle(_x,_y,_x+_w,_y+12,false);
    if(_fraction>0) {draw_set_color(_colour);draw_rectangle(_x,_y,_x+_w*clamp(_fraction,0,1),_y+12,false);}
    draw_set_color(c_white);
}
function ana_dashboard(_ui) {
    if(_ui.analysis_view==3) {lab_leftovers_draw(_ui);return;}
    if(_ui.analysis_view==2) {
        lab_workflow_draw(_ui);return;
    }
    if(_ui.analysis_error!="") {
        ana_box(24,148,1220,112);draw_set_color(c_red);ui_text(40,160,"ANALYSIS NOT STARTED");
        draw_set_color(c_white);ana_text(40,190,_ui.analysis_error,1180);
        ui_text(40,222,"Fix the field. Module stats and base must be numbers; only bounds may be empty.");return;
    }
    var a=_ui.analysis;
    if(is_undefined(a)) {ui_text(24,160,"Set inventory and order requirements.");return;}
    if(_ui.analysis_view==1) {ana_build_draw(_ui,a);return;}
    var values=[string(a.total),string(a.valid),ana_percent(a.valid,a.total),is_undefined(a.min_modules)?"N/A":string(a.min_modules)];
    var titles=["Total Combinations","Valid Combinations","Success Rate","Minimum Modules"];
    for(var i=0;i<4;++i) {ana_box(24+i*310,148,290,48);ui_text(34+i*310,151,titles[i]);ui_text(34+i*310,173,values[i]);}
    draw_set_color(c_white);ui_text(24,205,"Constraint pressure (all combinations)");
    ui_text(650,205,"Module Usage / ON / minimal");
    var keys=bal_keys(),visible_keys=game_stat_keys(),visible_row=0,goal=a.model.goal;
    for(var k=0;k<array_length(keys);++k) {
        if(!array_contains(visible_keys,keys[k])) continue;
        // Keep the model index for pressure data while compacting visible rows.
        var yy=244+visible_row++*30,active=struct_exists(goal.min,keys[k])||struct_exists(goal.max,keys[k]);
        draw_set_color(active?c_white:c_gray);ui_text(24,yy,keys[k]);
        ana_bar(150,yy+3,240,a.total>0?a.pressure[k]/a.total:0,c_red);
        draw_set_color(active?c_white:c_gray);
        ui_text(404,yy,active?ana_percent(a.pressure[k],a.total):"-");
        ui_text(478,yy,"v"+string(a.below[k])+" ^"+string(a.above[k]));
    }
    var ranking=[];for(var i=0;i<array_length(a.model.items);++i) array_push(ranking,{index:i,used:a.usage[i]});
    array_sort(ranking,function(_a,_b){return _b.used-_a.used;});
    _ui.usage_page=clamp(_ui.usage_page,0,max(0,ceil(array_length(ranking)/8)-1));
    for(var r=0;r<8;++r) {
        var at=_ui.usage_page*8+r;if(at>=array_length(ranking)) break;
        var i=ranking[at].index,yy=244+r*30;
        draw_set_color(a.valid>0&&a.usage[i]==a.valid?c_yellow:c_white);
        ana_text(650,yy,a.model.items[i].name,180);
        ana_bar(835,yy+3,130,a.valid>0?a.usage[i]/a.valid:0,make_color_rgb(60,180,130));
        ana_text(976,yy,ana_percent(a.usage[i],a.valid)+" / "+ana_percent(a.on_usage[i],a.valid)+" / "+(a.phase=="done"?ana_percent(a.minimal_usage[i],array_length(a.minimal)):"..."),270);
    }
    draw_set_color(c_white);
    ui_text(24,496,"Near Misses: "+string(a.near)+"   Minimal builds: "+(a.phase=="done"?string(array_length(a.minimal)):"..."));
    ui_text(24,520,"Minimum Devices: "+ana_min_devices_label(_ui.progression));
    var warnings=[];
    if(a.phase=="done") {
        if(a.valid==0) array_push(warnings,"NO SOLUTIONS");
        if(a.total>0&&100*a.valid/a.total>=_ui.analysis_thresholds.easy) array_push(warnings,"TOO EASY");
        var rare=false,bottleneck=false;
        for(var i=0;i<array_length(a.usage);++i) if(a.inventory[i]>0&&a.valid>0&&100*a.usage[i]/a.valid<_ui.analysis_thresholds.rare) rare=true;
        for(var k=0;k<8;++k) if(a.total>0&&100*a.pressure[k]/a.total>=_ui.analysis_thresholds.pressure) bottleneck=true;
        for(var i=0;i<array_length(a.usage);++i) if(a.valid>0&&a.usage[i]==a.valid) bottleneck=true;
        if(rare) array_push(warnings,"RARELY USED MODULE");if(bottleneck) array_push(warnings,"POSSIBLE BOTTLENECK");
    }
    var warning_text="";for(var i=0;i<array_length(warnings);++i) warning_text+=(i>0?" | ":"")+warnings[i];
    draw_set_color(c_yellow);ana_text(24,548,warning_text);
    draw_set_color(a.phase=="done"?c_lime:c_yellow);
    ui_text(24,576,"Status: "+a.phase+"   Nodes: "+string(a.nodes)+" / "+string(a.limit)+(a.phase!="done"?"   Partial result":""));
    var inventory_total=0;for(var i=0;i<array_length(a.inventory);++i) inventory_total+=a.inventory[i];
    if(inventory_total==0) {
        draw_set_color(c_yellow);ui_text(24,604,"EMPTY INVENTORY: set In stock (units) in Modules. Drop weights do not add parts.");
    } else {
        draw_set_color(c_gray);ui_text(24,604,"Minimal build: no strict subset with the same ON/OFF states completes the order.");
    }
    ui_text(24,626,"Edit warning thresholds in Progression. Yellow names appear in every solution.");
}
function ana_min_devices_label(_p) {
    if(is_undefined(_p)||_p.mode!=1) return "N/A - specify device contents";
    if(_p.min_status=="exact") return string(_p.min_devices)+" (any subset of the specified devices)";
    if(_p.min_status=="partial") return is_undefined(_p.min_devices)?"N/A - search limit":"<= "+string(_p.min_devices)+" - incomplete search";
    return _p.min_status;
}
function ana_build_draw(_ui,_a) {
    var list=_ui.build_kind==0?_a.solutions:(_ui.build_kind==1?_a.minimal:_a.near_examples);
    var titles=["Valid","Minimal valid","Near misses (first 200)"];
    draw_set_color(c_white);ui_text(24,155,titles[_ui.build_kind]+": "+string(array_length(list)));
    if(array_length(list)==0) {ui_text(24,194,"No entries / calculation still running.");return;}
    _ui.build_index=clamp(_ui.build_index,0,array_length(list)-1);var recipe=list[_ui.build_index];
    ui_text(24,184,"Build "+string(_ui.build_index+1)+" / "+string(array_length(list))+"    Installed: "+string(recipe.total));
    ui_text(24,216,"Contents: quantity / ON / OFF");
    var row=0;
    for(var i=0;i<array_length(recipe.counts);++i) if(recipe.counts[i]>0) {
        ana_text(24,249+row*32,_a.model.items[i].name+": "+string(recipe.counts[i])+" / "+string(recipe.on[i])+" / "+string(recipe.counts[i]-recipe.on[i]),580);row++;
    }
    var keys=game_stat_keys(),goal=_a.model.goal;
    for(var k=0;k<array_length(keys);++k) {
        var key=keys[k],value=bal_stat(recipe.sum,key),lo=struct_exists(goal.min,key)?struct_get(goal.min,key):undefined,hi=struct_exists(goal.max,key)?struct_get(goal.max,key):undefined;
        var fits=(is_undefined(lo)||value>=lo)&&(is_undefined(hi)||value<=hi);
        draw_set_color(fits?c_lime:c_red);
        ui_text(650,218+k*34,key+": "+string(value)+"    ["+(is_undefined(lo)?"-":string(lo))+" .. "+(is_undefined(hi)?"-":string(hi))+"]");
    }
    if(struct_exists(recipe,"miss")&&array_contains(keys,recipe.miss.key)) {
        var miss=recipe.miss;draw_set_color(c_yellow);
        ui_text(24,538,"Deviation: "+miss.key+" / "+miss.side+" / "+string(miss.delta));
        ui_text(24,566,"For this constraint: min delta="+string(_a.deviation_min[miss.index])+"; mean delta="+string_format(_a.deviation_sum[miss.index]/_a.near_by[miss.index],0,2)+"; max delta="+string(_a.deviation_max[miss.index]));
    }
    draw_set_color(c_gray);ui_text(24,606,"Near miss = exactly one stat violates its bound; deviation uses that stat's units.");
}
function ana_progress_draw(_ui) {
    draw_set_color(c_gray);
    if(_ui.cfg.progression_mode==0) ui_text(24,250,"Random parts use type weights and loot min/max from Modules and Economy.");
    else {
        var mapping="";for(var i=0;i<array_length(_ui.cfg.modules);++i) mapping+=string(i+1)+"="+_ui.cfg.modules[i].name+"; ";
        ana_text(24,306,mapping,1220);
    }
    var p=_ui.progression;
    if(is_undefined(p)) {draw_set_color(c_white);ui_text(24,370,"Click Analyze Progression. Stage 0 = starting stock.");return;}
    if(p.phase=="error") {draw_set_color(c_red);ui_text(24,370,p.error);return;}
    draw_set_color(c_white);ui_text(24,336,"Status: "+p.phase+"   Run "+string(min(p.trials,p.trial+1))+" / "+string(p.trials));
    var max_valid=1;
    for(var i=0;i<array_length(p.stages);++i) if(p.stages[i].known>0) max_valid=max(max_valid,p.stages[i].valid/p.stages[i].known);
    var gx=48,gy=390,gw=550,gh=190;
    draw_set_color(c_gray);draw_line(gx,gy,gx,gy+gh);draw_line(gx,gy+gh,gx+gw,gy+gh);
    ui_text(24,365,"Availability 0-100% / solutions (own scale, max "+string_format(max_valid,0,1)+")");
    var prev_available=undefined,prev_solutions=undefined;
    for(var i=0;i<array_length(p.stages);++i) {
        var stage=p.stages[i],px=gx+gw*i/max(1,p.steps);
        draw_set_color(c_gray);ui_text(px-4,gy+gh+4,string(i));
        if(stage.done==0) continue;
        var py=gy+gh-gh*stage.hits/stage.done;
        draw_set_color(c_lime);draw_circle(px,py,3,false);
        if(!is_undefined(prev_available)) draw_line_width(prev_available[0],prev_available[1],px,py,2);
        prev_available=[px,py];
        if(stage.known>0) {
            var sy=gy+gh-gh*(stage.valid/stage.known)/max_valid;
            draw_set_color(c_aqua);draw_circle(px,sy,3,false);
            if(!is_undefined(prev_solutions)) draw_line_width(prev_solutions[0],prev_solutions[1],px,sy,2);
            prev_solutions=[px,sy];
        }
    }
    draw_set_color(c_lime);ui_text(24,608,"Green: solution availability");draw_set_color(c_aqua);ui_text(320,608,"Blue: number of solutions");
    // Availability rings remain visible when both curves coincide.
    for(var i=0;i<array_length(p.stages);++i) if(p.stages[i].done>0) {
        draw_set_color(c_lime);draw_circle(gx+gw*i/max(1,p.steps),gy+gh-gh*p.stages[i].hits/p.stages[i].done,5,true);
    }
    draw_set_color(c_white);ui_text(650,370,"Stage | mean solutions | mean success % | availability | n");
    _ui.progress_list_page=clamp(_ui.progress_list_page,0,max(0,ceil(array_length(p.stages)/7)-1));
    for(var row=0;row<7;++row) {
        var i=_ui.progress_list_page*7+row;if(i>=array_length(p.stages)) break;
        var st=p.stages[i],available=ana_percent(st.hits,st.done);
        if(st.unknown>0) available+=".."+ana_percent(st.hits+st.unknown,st.done);
        draw_set_color(st.done==0?c_gray:(st.hits>0?c_lime:(st.unknown>0?c_yellow:c_red)));
        var solutions=st.known>0?string_format(st.valid/st.known,0,1):"N/A";
        var success=st.rate_n>0?string_format(st.rate_sum/st.rate_n,0,1)+"%":"N/A";
        ana_text(650,400+row*28,string(i)+" | "+solutions+" | "+success+" | "+available+" | "+string(st.done),590);
    }
    draw_set_color(c_white);ana_text(650,608,"Minimum Devices: "+ana_min_devices_label(p),590);
    draw_set_color(c_gray);ana_text(24,632,"Means use completed exact searches. Availability intervals include unfinished checks; random = estimate from runs.",1230);
}

function lab_workflow_draw(_ui) {
    var job=_ui.job;
    if(is_undefined(job)) {draw_set_color(c_white);ui_text(24,160,"Click Run from zero to check part drops and order completion time.");return;}
    var times=[],devices=[],clicks=[],spent=0;
    for(var i=0;i<array_length(job.runs);++i) if(job.runs[i].success) {
        array_push(times,job.runs[i].seconds);array_push(devices,job.runs[i].devices);array_push(clicks,job.runs[i].clicks);spent+=job.runs[i].spent;
    }
    var n=array_length(times),done=array_length(job.runs),sum_t=0,sum_d=0,sum_c=0;
    for(var i=0;i<n;++i) {sum_t+=times[i];sum_d+=devices[i];sum_c+=clicks[i];}
    var titles=["Successful runs","Mean dismantlings","Mean income clicks","Time to order, min"];
    var values=[string(n)+" / "+string(done),n>0?string_format(sum_d/n,0,1):"N/A",n>0?string_format(sum_c/n,0,1):"N/A",n>0?string_format(sum_t/n/60,0,2):"N/A"];
    for(var i=0;i<4;++i) {ana_box(24+i*310,148,290,58);ui_text(34+i*310,153,titles[i]);ui_text(34+i*310,180,values[i]);}
    draw_set_color(c_white);
    var initial=0;for(var i=0;i<array_length(job.model.items);++i) initial+=job.model.items[i].qty;
    ui_text(24,220,"At start: "+string(job.model.econ.start_money)+" {coin}, "+string(initial)+" parts. Runs: "+string(done)+" / "+string(job.model.econ.trials));
    ui_text(24,248,"Loop: earn > buy > dismantle > check build > repeat. One dismantling = one iteration.");
    draw_set_color(c_yellow);
    ui_text(24,280,"Status: "+job.phase+(job.phase=="count"?" - finding valid recipes, nodes "+string(job.nodes):""));
    if(job.message!="") ana_text(24,308,job.message);
    if(!is_undefined(job.trial)) {draw_set_color(c_white);ui_text(24,336,"Current run: dismantled "+string(job.trial.devices)+", income clicks "+string(job.trial.clicks));}
    if(n>0) {
        var rest=lab_leftovers(job);
        draw_set_color(c_lime);ui_text(24,308,"After order, on average: "+string_format(rest.money.mean,0,1)+" {coin}; "+string_format(rest.modules.mean,0,1)+" parts; "+string_format(rest.pending.mean,0,1)+" unopened devices. See After order.");
        draw_set_color(c_white);
        ui_text(24,366,"Dismantlings: minimum "+string(lab_quantile(devices,0))+"; median "+string_format(lab_quantile(devices,0.5),0,1)+"; P90 "+string_format(lab_quantile(devices,0.9),0,1));
        ui_text(24,394,"Time: median "+string_format(lab_quantile(times,0.5)/60,0,2)+" min; P90 "+string_format(lab_quantile(times,0.9)/60,0,2)+" min");
        ui_text(24,422,"Mean time: income "+string_format(sum_c/n*job.model.econ.gift_seconds/60,0,2)+" min; dismantling "+string_format(sum_d/n*job.model.econ.dismantle_seconds/60,0,2)+" min; assembly "+string_format(job.model.econ.assembly_seconds/60,0,2)+" min");
        ui_text(24,450,"Mean purchase cost: "+string_format(spent/n,0,1)+" {coin}. Success rate: "+ana_percent(n,done));
        ui_text(24,484,"Share of completed runs requiring no more than this many dismantlings:");
        var max_d=max(1,lab_quantile(devices,1)),bin_size=max(1,ceil(max_d/10));
        for(var bin=0;bin<10;++bin) {
            var threshold=(bin+1)*bin_size,hits=0;
            for(var i=0;i<n;++i) if(devices[i]<=threshold) hits++;
            var xx=24+bin*122,bar_h=100*hits/max(1,done);
            draw_set_color(make_color_rgb(55,170,120));draw_rectangle(xx,612-bar_h,xx+90,612,false);
            draw_set_color(c_white);ui_text(xx,616,"<="+string(threshold)+": "+ana_percent(hits,done));
        }
    }
    if(done>n) {draw_set_color(c_yellow);ui_text(24,644,"Some runs failed. Means and P90 above cover successful runs only.");}
}

// Distributions are conditional on completed orders, using the frozen run model.
function lab_leftovers_draw(_ui) {
    draw_set_color(c_white);
    var job=_ui.job;
    if(is_undefined(job)) {ui_text(24,160,"Run the gameplay loop first.");return;}
    var rest=lab_leftovers(job);
    ui_text(24,150,"Left after order: successful runs "+string(rest.count)+" / "+string(array_length(job.runs)));
    ui_text(24,180,"Order parts have been subtracted; cash includes the reward. Unopened purchases are counted separately.");
    ui_text(24,210,"Means and ranges cover successful runs. This is possible stock, not a guaranteed set.");
    if(rest.count==0) {draw_set_color(c_yellow);ui_text(24,260,"No successful runs: post-order stock N/A.");return;}
    var labels=["{coin}","Total parts","Unopened devices"],values=[rest.money,rest.modules,rest.pending];
    for(var i=0;i<3;++i) {
        var v=values[i];ana_box(24+i*410,250,390,70);
        ui_text(34+i*410,255,labels[i]+": mean "+string_format(v.mean,0,2));
        ui_text(34+i*410,282,"Min "+string(v.low)+" / median "+string_format(v.median,0,1)+" / max "+string(v.high));
    }
    draw_set_color(c_white);ui_text(24,340,"Module                              Mean           Min          Median          Max          At least one");
    var pages=max(1,ceil(array_length(job.model.items)/8));_ui.leftover_page=clamp(_ui.leftover_page,0,pages-1);
    for(var row=0;row<8;++row) {
        var i=_ui.leftover_page*8+row;if(i>=array_length(job.model.items)) break;
        var v=rest.items[i],yy=374+row*30;
        ana_text(24,yy,job.model.items[i].name,320);
        ui_text(360,yy,string_format(v.mean,0,2));ui_text(490,yy,string(v.low));
        ui_text(620,yy,string_format(v.median,0,1));ui_text(760,yy,string(v.high));
        ui_text(900,yy,ana_percent(v.present,rest.count));
    }
    ui_text(24,624,"Page "+string(_ui.leftover_page+1)+" / "+string(pages)+". Fractional means are averages across runs.");
}
