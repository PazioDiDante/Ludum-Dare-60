// WebGL cannot load TTFs with font_add. HTML5 uses baked texture-font assets.
function game_font_create(_pixels) {
    if(os_browser!=browser_not_a_browser) {
        switch(_pixels) {
            case 16:return fnt_editundo_16;
            case 24:return fnt_editundo_24;
            default:return fnt_editundo_18;
        }
    }
    var antialias=font_add_get_enable_aa();
    font_add_enable_aa(false);
    var result=font_add("fonts/edit-undo/editundo.ttf",_pixels,false,false,32,255);
    font_add_enable_aa(antialias);
    return result;
}
function game_font_delete(_font) {
    // Baked resources are shared; only runtime font instances are disposable.
    if(_font==fnt_editundo_16||_font==fnt_editundo_18||_font==fnt_editundo_24) return;
    if(font_exists(_font)) font_delete(_font);
}

// Restore the game's font after drawing, instead of GameMaker's built-in font.
function game_font_default() {
    if(instance_exists(obj_game)) return obj_game.ui_font;
    return -1;
}

// Inline currency markers keep icons inside labels, wrapped help and reports.
function ui_text_runs(_text) {
    var runs=[],word="",length=string_length(_text);
    for(var i=1;i<=length;++i) {
        var ch=string_char_at(_text,i),icon=-1,skip=0;
        if(string_copy(_text,i,6)=="{coin}") {icon=spr_coin;skip=5;}
        else if(string_copy(_text,i,7)=="{scrap}") {icon=spr_cog;skip=6;}
        if(icon>=0||ch==" "||ch=="\n"||ch=="\r") {
            if(word!="") {array_push(runs,{text:word,sprite:-1});word="";}
            if(icon>=0) {array_push(runs,{text:"",sprite:icon});i+=skip;}
            else if(ch!="\r") array_push(runs,{text:ch,sprite:-1});
        } else word+=ch;
    }
    if(word!="") array_push(runs,{text:word,sprite:-1});
    return runs;
}
function ui_text(_x,_y,_text) {ui_text_ext(_x,_y,_text,-1,-1);}
function ui_text_ext(_x,_y,_text,_sep,_width) {
    if(string_pos("{coin}",_text)==0&&string_pos("{scrap}",_text)==0) {
        if(_width<0) draw_text(_x,_y,_text);else draw_text_ext(_x,_y,_text,_sep,_width);
        return;
    }
    var runs=ui_text_runs(_text),size=max(16,string_height("M"));
    var line={runs:[],width:0},lines=[line];
    for(var i=0;i<array_length(runs);++i) {
        var run=runs[i];
        if(run.text=="\n") {line={runs:[],width:0};array_push(lines,line);continue;}
        var width=run.sprite>=0?size:string_width(run.text);
        if(_width>0&&line.width>0&&line.width+width>_width) {
            if(run.text==" ") continue;
            line={runs:[],width:0};array_push(lines,line);
        }
        array_push(line.runs,run);line.width+=width;
    }
    var halign=draw_get_halign(),valign=draw_get_valign();
    var step=_sep<0?size:_sep,height=size+(array_length(lines)-1)*step;
    var top=_y-(valign==fa_middle?height/2:(valign==fa_bottom?height:0));
    draw_set_halign(fa_left);draw_set_valign(fa_top);
    for(var row=0;row<array_length(lines);++row) {
        line=lines[row];
        var px=_x-(halign==fa_center?line.width/2:(halign==fa_right?line.width:0)),py=top+row*step;
        for(var i=0;i<array_length(line.runs);++i) {
            var run=line.runs[i];
            if(run.sprite>=0) {campaign_sprite(run.sprite,[px,py,px+size,py+size],draw_get_alpha());px+=size;}
            else {draw_text(px,py,run.text);px+=string_width(run.text);}
        }
    }
    draw_set_halign(halign);draw_set_valign(valign);
}
