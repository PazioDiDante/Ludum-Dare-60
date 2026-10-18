// Manual sandbox: no predefined modules, only the four core characteristics.
function manual_keys() {return ["energy","weight","heat","stability"];}
function manual_labels() {return ["Energy","Weight","Heat","Stability"];}
function manual_defaults() {
    return {modules:[],base:{energy:"0",weight:"0",heat:"0",stability:"0"},
        min:{energy:"",weight:"",heat:"",stability:""},max:{energy:"",weight:"",heat:"",stability:""},
        slots:"4",min_installed:"1",start_money:"0",gift:"10",device_price:"25",
        batch:"3",loot_min:"2",loot_max:"3",gift_seconds:"5",dismantle_seconds:"30",seed:"12345"};
}
function manual_validate(_cfg) {
    var out={ok:false,error:"",items:[],base:{},min:{},max:{},econ:{}};
    if(array_length(_cfg.modules)==0) {out.error="Create at least one module first.";return out;}
    var specs=[["slots",1,40,true],["min_installed",1,40,true],["start_money",0,1000000,false],
        ["gift",0.01,1000000,false],["device_price",0.01,1000000,false],["batch",1,10,true],
        ["loot_min",1,10,true],["loot_max",1,10,true],["gift_seconds",0,1000000,false],
        ["dismantle_seconds",0,1000000,false],["seed",0,1000000,true]];
    for(var i=0;i<array_length(specs);++i) {
        var spec=specs[i],n=lab_number(struct_get(_cfg,spec[0]));
        if(is_undefined(n)||n<spec[1]||n>spec[2]||(spec[3]&&floor(n)!=n)) {
            out.error="Field "+spec[0]+": "+string(spec[1])+" .. "+string(spec[2])+(spec[3]?", integer":"");return out;
        }
        struct_set(out.econ,spec[0],n);
    }
    if(out.econ.min_installed>out.econ.slots || out.econ.loot_min>out.econ.loot_max) {out.error="Minimum exceeds maximum.";return out;}
    var keys=manual_keys();
    for(var k=0;k<4;++k) {
        var key=keys[k],n=lab_number(struct_get(_cfg.base,key));
        if(is_undefined(n)) {out.error="Invalid base: "+key;return out;}
        struct_set(out.base,key,n);
        var bounds=["min","max"];
        for(var b=0;b<2;++b) {
            var text_value=string_trim(string(struct_get(struct_get(_cfg,bounds[b]),key)));
            if(text_value=="") continue;
            n=lab_number(text_value);if(is_undefined(n)) {out.error="Invalid bound: "+key;return out;}
            struct_set(struct_get(out,bounds[b]),key,n);
        }
        if(struct_exists(out.min,key)&&struct_exists(out.max,key)&&struct_get(out.min,key)>struct_get(out.max,key)) {out.error="min > max: "+key;return out;}
    }
    var weight_sum=0;
    for(var i=0;i<array_length(_cfg.modules);++i) {
        var src=_cfg.modules[i],item={name:string_trim(src.name),stats:{},drop_weight:lab_number(src.drop_weight)};
        if(item.name=="") {out.error="Enter a name for module "+string(i+1);return out;}
        for(var j=0;j<i;++j) if(out.items[j].name==item.name) {out.error="Names must be unique.";return out;}
        if(is_undefined(item.drop_weight)||item.drop_weight<0) {out.error="Drop weight must be >= 0.";return out;}
        weight_sum+=item.drop_weight;
        for(var k=0;k<4;++k) {
            var n=lab_number(struct_get(src.stats,keys[k]));
            if(is_undefined(n)) {out.error="Invalid stat: "+item.name+" / "+keys[k];return out;}
            struct_set(item.stats,keys[k],n);
        }
        array_push(out.items,item);
    }
    if(weight_sum<=0) {out.error="At least one module must have a drop weight > 0.";return out;}
    out.ok=true;return out;
}
function manual_start(_model) {
    var run={model:_model,inventory:array_create(array_length(_model.items),0),combination:array_create(array_length(_model.items),0),
        money:_model.econ.start_money,seconds:0,clicks:0,devices:0,purchases:0,rng:_model.econ.seed+1,
        total:0,stats:{},complete:false};
    manual_update(run);return run;
}
function manual_update(_run) {
    var keys=manual_keys(),model=_run.model;
    _run.total=0;
    for(var k=0;k<4;++k) struct_set(_run.stats,keys[k],struct_get(model.base,keys[k]));
    for(var i=0;i<array_length(model.items);++i) {
        var qty=_run.combination[i];_run.total+=qty;
        for(var k=0;k<4;++k) {
            var key=keys[k];struct_set(_run.stats,key,struct_get(_run.stats,key)+qty*struct_get(model.items[i].stats,key));
        }
    }
    _run.complete=_run.total>=model.econ.min_installed && _run.total<=model.econ.slots;
    for(var k=0;k<4;++k) {
        var key=keys[k],value=struct_get(_run.stats,key);
        if(struct_exists(model.min,key)&&value<struct_get(model.min,key)) _run.complete=false;
        if(struct_exists(model.max,key)&&value>struct_get(model.max,key)) _run.complete=false;
    }
}
function manual_move(_run,_index,_to_combination) {
    if(_index<0||_index>=array_length(_run.inventory)) return false;
    if(_to_combination) {
        if(_run.inventory[_index]<=0||_run.total>=_run.model.econ.slots) return false;
        _run.inventory[_index]--;_run.combination[_index]++;
    } else {
        if(_run.combination[_index]<=0) return false;
        _run.combination[_index]--;_run.inventory[_index]++;
    }
    manual_update(_run);return true;
}
function manual_money(_run) {
    _run.money+=_run.model.econ.gift;_run.seconds+=_run.model.econ.gift_seconds;_run.clicks++;
}
function manual_buy(_run) {
    var e=_run.model.econ,cost=e.batch*e.device_price;
    if(_run.money<cost) return false;
    _run.money-=cost;_run.purchases++;_run.devices+=e.batch;_run.seconds+=e.batch*e.dismantle_seconds;
    var total_weight=0;for(var i=0;i<array_length(_run.model.items);++i) total_weight+=_run.model.items[i].drop_weight;
    repeat(e.batch) repeat(lab_roll(_run,e.loot_min,e.loot_max)) {
        var roll=lab_random(_run)*total_weight;
        for(var i=0;i<array_length(_run.model.items);++i) {
            roll-=_run.model.items[i].drop_weight;
            if(roll<0) {_run.inventory[i]++;break;}
        }
    }
    return true;
}
