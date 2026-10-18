// Balance lab data and bounded, incremental calculations. Independent of gameplay.
function lab_defaults() {
    var cfg = {slots:"2",min_installed:"1",allow_unpowered:false,
        base:{},min:{},max:{},modules:[],start_money:"100",device_price:"25",
        order_price:"300",repair_price:"45",gift:"10",gift_seconds:"5",
        dismantle_seconds:"30",repair_seconds:"45",assembly_seconds:"30",
        batch_min:"3",batch_max:"4",loot_min:"2",loot_max:"3",
        trials:"100",device_limit:"1000",seed:"12345"};
    var goal = bal_radio_goal(), keys = bal_keys();
    for (var k=0;k<array_length(keys);++k) {
        var key=keys[k];
        struct_set(cfg.base,key,string(bal_stat(goal.base,key)));
        struct_set(cfg.min,key,struct_exists(goal.min,key)?string(struct_get(goal.min,key)):"");
        struct_set(cfg.max,key,struct_exists(goal.max,key)?string(struct_get(goal.max,key)):"");
    }
    var catalog=bal_catalog();
    for(var i=0;i<array_length(catalog);++i) {
        var item={name:catalog[i].name,qty:"0",drop_weight:"1",stats:{}};
        for(var k=0;k<array_length(keys);++k) struct_set(item.stats,keys[k],string(bal_stat(catalog[i].stats,keys[k])));
        array_push(cfg.modules,item);
    }
    return cfg;
}
function lab_number(_text) {
    var s=string_trim(string(_text));
    if(s=="") return undefined;
    var digits=0,dots=0;
    for(var i=1;i<=string_length(s);++i) {
        var ch=string_char_at(s,i);
        if(ch>="0" && ch<="9") digits++;
        else if(ch=="." && dots==0) dots++;
        else if(ch=="-" && i==1) continue;
        else return undefined;
    }
    if(digits==0) return undefined;
    var n=real(s);
    if(abs(n)>1000000) return undefined;
    return n;
}
function lab_validate(_cfg) {
    var out={ok:false,error:"",items:[],goal:{slots:0,min_installed:0,allow_unpowered:_cfg.allow_unpowered,base:{},min:{},max:{}},econ:{}};
    var specs=[
        ["slots",1,8,true],["min_installed",0,8,true],
        ["start_money",0,1000000,false],["device_price",0.01,1000000,false],
        ["order_price",0,1000000,false],["repair_price",0,1000000,false],
        ["gift",0.01,1000000,false],["gift_seconds",0.01,1000000,false],
        ["dismantle_seconds",0.01,1000000,false],["repair_seconds",0.01,1000000,false],
        ["assembly_seconds",0,1000000,false],["batch_min",1,10,true],["batch_max",1,10,true],
        ["loot_min",1,10,true],["loot_max",1,10,true],["trials",1,1000,true],
        ["device_limit",1,10000,true],["seed",0,1000000,true]];
    for(var i=0;i<array_length(specs);++i) {
        var spec=specs[i],n=lab_number(struct_get(_cfg,spec[0]));
        if(is_undefined(n) || n<spec[1] || n>spec[2] || (spec[3] && floor(n)!=n)) {
            out.error="Field "+spec[0]+": "+string(spec[1])+" .. "+string(spec[2])+(spec[3]?", integer":"");return out;
        }
        struct_set(out.econ,spec[0],n);
    }
    out.goal.slots=out.econ.slots;out.goal.min_installed=out.econ.min_installed;
    if(out.goal.min_installed>out.goal.slots || out.econ.batch_min>out.econ.batch_max || out.econ.loot_min>out.econ.loot_max) {
        out.error="Minimum cannot exceed maximum.";return out;
    }
    var keys=bal_keys();
    for(var k=0;k<array_length(keys);++k) {
        var key=keys[k],base_value=lab_number(struct_get(_cfg.base,key));
        if(is_undefined(base_value)) {out.error="Invalid base: "+key;return out;}
        struct_set(out.goal.base,key,base_value);
        var bounds=["min","max"];
        for(var b=0;b<2;++b) {
            var text_value=string_trim(string(struct_get(struct_get(_cfg,bounds[b]),key)));
            if(text_value=="") continue;
            var v=lab_number(text_value);
            if(is_undefined(v)) {out.error="Invalid bound: "+key;return out;}
            struct_set(struct_get(out.goal,bounds[b]),key,v);
        }
        if(struct_exists(out.goal.min,key) && struct_exists(out.goal.max,key)
            && struct_get(out.goal.min,key)>struct_get(out.goal.max,key)) {out.error="min > max: "+key;return out;}
    }
    if(array_length(_cfg.modules)<1 || array_length(_cfg.modules)>40) {out.error="Use 1 to 40 module types.";return out;}
    for(var i=0;i<array_length(_cfg.modules);++i) {
        var src=_cfg.modules[i];
        var item={name:string_trim(src.name),qty:lab_number(src.qty),drop_weight:lab_number(src.drop_weight),stats:{}};
        if(item.name=="") {out.error="Enter a name for module "+string(i+1);return out;}
        for(var j=0;j<i;++j) if(out.items[j].name==item.name) {out.error="Module names must be unique: "+item.name;return out;}
        if(is_undefined(item.qty) || item.qty<0 || item.qty>999 || floor(item.qty)!=item.qty || is_undefined(item.drop_weight) || item.drop_weight<0) {
            out.error="Module "+item.name+": quantity 0..999; drop weight >= 0.";return out;
        }
        for(var k=0;k<array_length(keys);++k) {
            var v=lab_number(struct_get(src.stats,keys[k]));
            if(is_undefined(v)) {out.error="Module "+item.name+": invalid "+keys[k];return out;}
            struct_set(item.stats,keys[k],v);
        }
        array_push(out.items,item);
    }
    out.ok=true;return out;
}
function lab_stats_copy(_stats) {
    var out=bal_empty_stats(),keys=bal_keys();
    for(var k=0;k<array_length(keys);++k) struct_set(out,keys[k],bal_stat(_stats,keys[k]));
    return out;
}
function lab_job(_model) {
    return {model:_model,phase:"count",nodes:0,node_limit:300000,recipe_limit:30000,
        stack:[{index:0,left:_model.goal.slots,total:0,sum:lab_stats_copy(_model.goal.base),counts:[],description:""}],
        total:0,valid:0,potential_total:0,recipes:[],examples:[],message:"",
        rng:_model.econ.seed+1,trial:undefined,runs:[],successes:0};
}
// Independent PRNG: balance experiments do not change gameplay's random sequence.
function lab_random(_job) {
    _job.rng=(_job.rng*48271) mod 2147483647;
    return (_job.rng-1)/2147483646;
}
function lab_roll(_job,_lo,_hi) {return _lo+floor(lab_random(_job)*(_hi-_lo+1));}
function lab_count_step(_job,_budget) {
    var model=_job.model,goal=model.goal,items=model.items;
    repeat(_budget) {
        if(array_length(_job.stack)==0) {
            _job.phase=array_length(_job.recipes)>0?"simulate":"impossible";
            if(_job.phase=="impossible") _job.message="This order cannot be completed with these modules and drops.";
            return;
        }
        if(_job.nodes>=_job.node_limit || array_length(_job.recipes)>=_job.recipe_limit) {
            _job.phase="limited";_job.message="Search limit reached: partial results. Reduce slots/types or disable OFF.";return;
        }
        var node=array_pop(_job.stack);_job.nodes++;
        if(node.index==array_length(items)) {
            if(node.total<goal.min_installed) continue;
            _job.potential_total++;
            var available=true;
            for(var i=0;i<array_length(items);++i) if(node.counts[i]>items[i].qty) {available=false;break;}
            if(available) _job.total++;
            if(!bal_matches(node.sum,goal)) continue;
            if(available) _job.valid++;
            array_push(_job.recipes,node.counts);
            // Optional numeric cache for gameplay order generation; the lab UI is unchanged.
            if(struct_exists(_job,"recipe_stats")) array_push(_job.recipe_stats,lab_stats_copy(node.sum));
            if(array_length(_job.examples)<6) array_push(_job.examples,node.description==""?"[no modules]":node.description);
            continue;
        }
        var item=items[node.index];
        var cap=min(node.left,item.drop_weight>0?goal.slots:item.qty);
        for(var installed=0;installed<=cap;++installed) {
            var first_powered=goal.allow_unpowered?0:installed;
            for(var powered=first_powered;powered<=installed;++powered) {
                var sum=lab_stats_copy(node.sum);bal_apply(sum,item,installed,powered,1);
                var counts=[];array_copy(counts,0,node.counts,0,array_length(node.counts));array_push(counts,installed);
                var desc=node.description;
                if(installed>0 && (!struct_exists(_job,"compact") || !_job.compact)) desc+=(desc==""?"":" + ")+item.name+" x"+string(installed)+(goal.allow_unpowered?" (ON "+string(powered)+")":"");
                array_push(_job.stack,{index:node.index+1,left:node.left-installed,total:node.total+installed,sum:sum,counts:counts,description:desc});
            }
        }
    }
}
function lab_run_start(_job) {
    var inventory=[];
    for(var i=0;i<array_length(_job.model.items);++i) array_push(inventory,_job.model.items[i].qty);
    return {inventory:inventory,money:_job.model.econ.start_money,seconds:0,devices:0,bought:0,pending:0,clicks:0,spent:0,success:false,recipe_cursor:0};
}
function lab_finish_run(_job,_success,_recipe) {
    var run=_job.trial,e=_job.model.econ;
    run.success=_success;
    if(_success) {
        for(var i=0;i<array_length(run.inventory);++i) run.inventory[i]-=_recipe[i];
        run.seconds+=e.assembly_seconds;run.money+=e.order_price;_job.successes++;
    }
    array_push(_job.runs,run);_job.trial=undefined;
    if(array_length(_job.runs)>=e.trials) _job.phase="done";
}
// Budget counts recipe comparisons, so even large catalogs remain cancellable.
function lab_sim_step(_job,_budget) {
    var items=_job.model.items,e=_job.model.econ;
    repeat(_budget) {
        if(_job.phase!="simulate") return;
        if(is_undefined(_job.trial)) _job.trial=lab_run_start(_job);
        var run=_job.trial;
        if(run.recipe_cursor<array_length(_job.recipes)) {
            var recipe=_job.recipes[run.recipe_cursor++],fits=true;
            for(var i=0;i<array_length(items);++i) if(recipe[i]>run.inventory[i]) {fits=false;break;}
            if(fits) lab_finish_run(_job,true,recipe);
            continue;
        }
        if(run.devices>=e.device_limit) {lab_finish_run(_job,false,[]);continue;}
        var total_weight=0;
        for(var i=0;i<array_length(items);++i) total_weight+=items[i].drop_weight;
        if(total_weight<=0) {lab_finish_run(_job,false,[]);continue;}
        if(run.pending==0) {
            // Buy a full random batch when affordable; otherwise earn just enough
            // for ONE device. No resale after dismantling: the shell is scrapped.
            var batch=lab_roll(_job,e.batch_min,e.batch_max);
            var buy=run.money>=batch*e.device_price?batch:1;
            if(run.money<e.device_price) {
                var clicks=ceil((e.device_price-run.money)/e.gift);
                run.clicks+=clicks;run.money+=clicks*e.gift;run.seconds+=clicks*e.gift_seconds;
            }
            run.money-=buy*e.device_price;run.spent+=buy*e.device_price;run.bought+=buy;run.pending=buy;
        }
        run.pending--;run.devices++;run.seconds+=e.dismantle_seconds;
        repeat(lab_roll(_job,e.loot_min,e.loot_max)) {
            var roll=lab_random(_job)*total_weight,chosen=array_length(items)-1;
            for(var i=0;i<array_length(items);++i) {roll-=items[i].drop_weight;if(roll<0){chosen=i;break;}}
            run.inventory[chosen]++;
        }
        run.recipe_cursor=0;
    }
}
function lab_quantile(_values,_q) {
    if(array_length(_values)==0) return 0;
    var copy=[];array_copy(copy,0,_values,0,array_length(_values));array_sort(copy,true);
    var pos=clamp(_q,0,1)*(array_length(copy)-1);
    return lerp(copy[floor(pos)],copy[ceil(pos)],frac(pos));
}
function lab_report(_job) {
    var lines=[];
    array_push(lines,"Current stock: "+string(_job.total)+" combinations; valid for order: "+string(_job.valid));
    array_push(lines,"With future drops: "+string(_job.potential_total)+" combinations; valid: "+string(array_length(_job.recipes))+".");
    if(_job.phase=="count") array_push(lines,"Searching... nodes "+string(_job.nodes)+" / "+string(_job.node_limit));
    if(_job.phase=="simulate") array_push(lines,"Simulation: "+string(array_length(_job.runs))+" / "+string(_job.model.econ.trials)+(is_undefined(_job.trial)?"":"; current run: dismantled "+string(_job.trial.devices)));
    if(_job.message!="") array_push(lines,_job.message);
    if(array_length(_job.runs)>0) {
        var times=[],sum_time=0,sum_devices=0,sum_clicks=0,sum_cash=0,sum_spent=0,sum_bought=0;
        for(var i=0;i<array_length(_job.runs);++i) {
            var run=_job.runs[i];if(!run.success) continue;
            array_push(times,run.seconds);sum_time+=run.seconds;sum_devices+=run.devices;
            sum_clicks+=run.clicks;sum_cash+=run.money;sum_spent+=run.spent;sum_bought+=run.bought;
        }
        var n=array_length(times);
        array_push(lines,"Completed: "+string(n)+" / "+string(array_length(_job.runs))+" ("+string_format(100*n/array_length(_job.runs),0,1)+"%); reached run limit: "+string(array_length(_job.runs)-n));
        if(n>0) {
            array_push(lines,"Successful runs (min): mean "+string_format(sum_time/n/60,0,2)+"; median "+string_format(lab_quantile(times,0.5)/60,0,2)+"; P90 "+string_format(lab_quantile(times,0.9)/60,0,2));
            array_push(lines,"Range (min): "+string_format(lab_quantile(times,0)/60,0,2)+" .. "+string_format(lab_quantile(times,1)/60,0,2));
            array_push(lines,"On average: bought "+string_format(sum_bought/n,0,1)+"; dismantled "+string_format(sum_devices/n,0,1)+"; income clicks "+string_format(sum_clicks/n,0,1));
            array_push(lines,"Time (min): income "+string_format(sum_clicks/n*_job.model.econ.gift_seconds/60,0,2)+"; dismantling "+string_format(sum_devices/n*_job.model.econ.dismantle_seconds/60,0,2)+"; assembly "+string_format(_job.model.econ.assembly_seconds/60,0,2));
            array_push(lines,"Spent on devices: "+string_format(sum_spent/n,0,1)+"; cash after reward: "+string_format(sum_cash/n,0,1));
            array_push(lines,"Cash change: "+string_format(sum_cash/n-_job.model.econ.start_money,0,1)+" (includes manual income).");
        }
        if(n<array_length(_job.runs)) array_push(lines,"NOTE: times above cover successful runs only, not all orders.");
    }
    var e=_job.model.econ;
    array_push(lines,"Comparison: manual income = "+string_format(e.gift/e.gift_seconds*60,0,1)+" {coin}/min.");
    array_push(lines,"Separate repair = "+string_format((e.repair_price-e.device_price)/e.repair_seconds*60,0,1)+" {coin}/min after purchase, without parts.");
    array_push(lines,"Repairs are excluded from runs. Dismantled cases are scrapped.");
    return lines;
}

// Inventory analysis reuses bal_apply / bal_matches and the lab's validated model.
function ana_defaults(_cfg) {
    if(!struct_exists(_cfg,"use_initial_state")) _cfg.use_initial_state=false;
    if(!struct_exists(_cfg,"analysis_steps")) _cfg.analysis_steps="5";
    if(!struct_exists(_cfg,"progression_mode")) _cfg.progression_mode=0;
    if(!struct_exists(_cfg,"progression_rows")) _cfg.progression_rows=[];
    if(!struct_exists(_cfg,"easy_rate")) _cfg.easy_rate="25";
    if(!struct_exists(_cfg,"rare_rate")) _cfg.rare_rate="5";
    if(!struct_exists(_cfg,"pressure_rate")) _cfg.pressure_rate="80";
}
function ana_inventory(_model) {
    var inv=[];for(var i=0;i<array_length(_model.items);++i) array_push(inv,_model.items[i].qty);return inv;
}
function ana_job(_model,_inventory) {
    var n=array_length(_model.items);
    return {model:_model,inventory:_inventory,phase:"count",nodes:0,limit:300000,record_limit:30000,
        stack:[{index:0,left:_model.goal.slots,total:0,sum:lab_stats_copy(_model.goal.base),counts:[],on:[]}],
        total:0,valid:0,near:0,min_modules:undefined,pressure:array_create(8,0),below:array_create(8,0),above:array_create(8,0),
        deviation_min:array_create(8,undefined),deviation_max:array_create(8,0),deviation_sum:array_create(8,0),near_by:array_create(8,0),
        usage:array_create(n,0),on_usage:array_create(n,0),minimal_usage:array_create(n,0),
        solutions:[],near_examples:[],minimal:[],minimal_i:0,minimal_j:0,minimal_checks:0,partial:false};
}
function ana_violations(_sum,_goal) {
    var keys=bal_keys(),out=[];
    for(var k=0;k<8;++k) {
        var key=keys[k],v=bal_stat(_sum,key);
        if(struct_exists(_goal.min,key)&&v<struct_get(_goal.min,key)) array_push(out,{key:key,index:k,side:"min",delta:struct_get(_goal.min,key)-v});
        else if(struct_exists(_goal.max,key)&&v>struct_get(_goal.max,key)) array_push(out,{key:key,index:k,side:"max",delta:v-struct_get(_goal.max,key)});
    }
    return out;
}
function ana_step(_a,_budget) {
    repeat(_budget) {
        if(_a.phase=="minimal") {ana_minimal_step(_a);continue;}
        if(_a.phase!="count") return;
        if(array_length(_a.stack)==0) {_a.phase="minimal";continue;}
        if(_a.nodes>=_a.limit || array_length(_a.solutions)>=_a.record_limit) {_a.phase="limited";_a.partial=true;return;}
        var node=array_pop(_a.stack);_a.nodes++;
        var items=_a.model.items,goal=_a.model.goal;
        if(node.index==array_length(items)) {
            if(node.total<goal.min_installed) continue;
            _a.total++;
            var violations=ana_violations(node.sum,goal);
            for(var v=0;v<array_length(violations);++v) {
                var violation=violations[v],k=violation.index;_a.pressure[k]++;
                if(violation.side=="min") _a.below[k]++;else _a.above[k]++;
            }
            if(array_length(violations)==0) {
                _a.valid++;
                if(is_undefined(_a.min_modules)||node.total<_a.min_modules) _a.min_modules=node.total;
                for(var i=0;i<array_length(items);++i) {
                    if(node.counts[i]>0) _a.usage[i]++;
                    if(node.on[i]>0) _a.on_usage[i]++;
                }
                array_push(_a.solutions,node);
            } else if(array_length(violations)==1) {
                _a.near++;var miss=violations[0],k=miss.index;
                _a.near_by[k]++;_a.deviation_sum[k]+=miss.delta;
                _a.deviation_max[k]=max(_a.deviation_max[k],miss.delta);
                if(is_undefined(_a.deviation_min[k])) _a.deviation_min[k]=miss.delta;
                else _a.deviation_min[k]=min(_a.deviation_min[k],miss.delta);
                if(array_length(_a.near_examples)<200) {node.miss=miss;array_push(_a.near_examples,node);}
            }
            continue;
        }
        var cap=min(node.left,_a.inventory[node.index]);
        for(var installed=cap;installed>=0;--installed) {
            for(var powered=installed;powered>=(goal.allow_unpowered?0:installed);--powered) {
                var sum=lab_stats_copy(node.sum);bal_apply(sum,items[node.index],installed,powered,1);
                var counts=[],on=[];
                array_copy(counts,0,node.counts,0,array_length(node.counts));array_push(counts,installed);
                array_copy(on,0,node.on,0,array_length(node.on));array_push(on,powered);
                array_push(_a.stack,{index:node.index+1,left:node.left-installed,total:node.total+installed,sum:sum,counts:counts,on:on});
            }
        }
    }
}
// Inclusion minimal, not just globally smallest. A proper subset preserves ON/OFF.
// Compare against ALL successful smaller configurations, so removable pairs are found too.
function ana_minimal_step(_a) {
    if(_a.minimal_checks++>=3000000) {_a.phase="limited";_a.partial=true;return;}
    if(_a.minimal_i>=array_length(_a.solutions)) {_a.phase="done";return;}
    var candidate=_a.solutions[_a.minimal_i];
    if(_a.minimal_j>=array_length(_a.solutions)) {
        candidate.minimal=true;array_push(_a.minimal,candidate);
        for(var i=0;i<array_length(candidate.counts);++i) if(candidate.counts[i]>0) _a.minimal_usage[i]++;
        _a.minimal_i++;_a.minimal_j=0;return;
    }
    var smaller=_a.solutions[_a.minimal_j++];
    if(smaller.total>=candidate.total) return;
    for(var i=0;i<array_length(candidate.counts);++i)
        if(smaller.on[i]>candidate.on[i] || smaller.counts[i]-smaller.on[i]>candidate.counts[i]-candidate.on[i]) return;
    candidate.minimal=false;_a.minimal_i++;_a.minimal_j=0;
}
function ana_percent(_n,_d) {return _d>0?string_format(100*_n/_d,0,1)+"%":"N/A";}
function ana_finished(_a) {return _a.phase=="done"||_a.phase=="limited"||_a.phase=="stopped";}
function ana_progress_job(_model,_cfg) {
    ana_defaults(_cfg);
    var steps=lab_number(_cfg.analysis_steps);
    if(is_undefined(steps)||floor(steps)!=steps||steps<1||steps>20) return {phase:"error",error:"Stages: integer 1..20"};
    var rows=[],mode=_cfg.progression_mode,n=array_length(_model.items);
    if(mode!=0) {
        if(array_length(_cfg.progression_rows)==0) return {phase:"error",error:"Add device / stage contents"};
        if(array_length(_cfg.progression_rows)>16) return {phase:"error",error:"At most 16 devices / stages"};
        for(var r=0;r<array_length(_cfg.progression_rows);++r) {
            var values=string_split(_cfg.progression_rows[r].counts,","),row=[];
            if(array_length(values)!=n) return {phase:"error",error:"Row "+string(r+1)+": enter "+string(n)+" comma-separated numbers"};
            for(var i=0;i<n;++i) {
                var qty=lab_number(values[i]);
                if(is_undefined(qty)||qty<0||qty>999||floor(qty)!=qty) return {phase:"error",error:"Part quantity: integer 0..999"};
                array_push(row,qty);
            }
            array_push(rows,row);
        }
        steps=array_length(rows);
    }
    var stages=[];for(var i=0;i<=steps;++i) array_push(stages,{done:0,known:0,hits:0,unknown:0,valid:0,total:0,rate_sum:0,rate_n:0});
    return {phase:"run",model:_model,mode:mode,rows:rows,steps:steps,trials:mode==0?_model.econ.trials:1,
        trial:0,stage:0,inventory:ana_inventory(_model),stages:stages,worker:undefined,rng:_model.econ.seed+1,
        min_devices:undefined,min_status:mode==1?"pending":"N/A",mask:0,mask_recipe:0,mask_inv:undefined,
        mask_count:0,device_checks:0,device_limit:3000000,last:undefined};
}
function ana_progress_step(_p,_budget) {
    if(_p.phase=="devices") {ana_devices_step(_p,_budget);return;}
    if(_p.phase!="run") return;
    if(is_undefined(_p.worker)) _p.worker=ana_job(_p.model,_p.inventory);
    // Progression needs exact counts/existence, not the more expensive minimal-set ranking.
    ana_step(_p.worker,_budget);
    if(_p.worker.phase=="minimal") _p.worker.phase="done";
    if(!ana_finished(_p.worker)) return;
    var a=_p.worker,s=_p.stages[_p.stage];s.done++;
    if(a.phase=="done") {
        s.known++;s.valid+=a.valid;s.total+=a.total;
        if(a.total>0) {s.rate_sum+=100*a.valid/a.total;s.rate_n++;}
    }
    if(a.valid>0) s.hits++;else if(a.phase!="done") s.unknown++;
    _p.last=a;_p.worker=undefined;
    if(_p.stage==_p.steps) {
        _p.trial++;
        if(_p.trial>=_p.trials) {
            if(_p.mode==1 && a.phase=="done") {_p.phase="devices";return;}
            if(_p.mode==1) _p.min_status="N/A: incomplete search";
            _p.phase="done";return;
        }
        _p.stage=0;_p.inventory=ana_inventory(_p.model);return;
    }
    if(_p.mode==2) {
        var inv=[];array_copy(inv,0,_p.rows[_p.stage],0,array_length(_p.rows[_p.stage]));_p.inventory=inv;
    } else if(_p.mode==1) {
        for(var i=0;i<array_length(_p.inventory);++i) _p.inventory[i]+=_p.rows[_p.stage][i];
    } else {
        var total_weight=0;for(var i=0;i<array_length(_p.model.items);++i) total_weight+=_p.model.items[i].drop_weight;
        if(total_weight>0) repeat(lab_roll(_p,_p.model.econ.loot_min,_p.model.econ.loot_max)) {
            var roll=lab_random(_p)*total_weight;
            for(var i=0;i<array_length(_p.model.items);++i) {roll-=_p.model.items[i].drop_weight;if(roll<0){_p.inventory[i]++;break;}}
        }
    }
    _p.stage++;
}
// Minimum number among ANY subset of the given finite source devices, not only prefixes.
function ana_devices_step(_p,_budget) {
    repeat(_budget) {
        if(_p.mask>=power(2,array_length(_p.rows))) {_p.min_status=is_undefined(_p.min_devices)?"No solution":"exact";_p.phase="done";return;}
        if(_p.device_checks++>=_p.device_limit) {_p.min_status="partial";_p.phase="done";return;}
        if(is_undefined(_p.mask_inv)) {
            _p.mask_inv=ana_inventory(_p.model);_p.mask_count=0;_p.mask_recipe=0;
            for(var r=0;r<array_length(_p.rows);++r) if((_p.mask & (1<<r))!=0) {
                _p.mask_count++;
                for(var i=0;i<array_length(_p.mask_inv);++i) _p.mask_inv[i]+=_p.rows[r][i];
            }
        }
        if((!is_undefined(_p.min_devices)&&_p.mask_count>=_p.min_devices)||_p.mask_recipe>=array_length(_p.last.solutions)) {
            _p.mask++;_p.mask_inv=undefined;continue;
        }
        var recipe=_p.last.solutions[_p.mask_recipe++],fits=true;
        for(var i=0;i<array_length(recipe.counts);++i) if(recipe.counts[i]>_p.mask_inv[i]) {fits=false;break;}
        if(fits) {
            _p.min_devices=_p.mask_count;
            if(_p.min_devices==0) {_p.min_status="exact";_p.phase="done";return;}
            _p.mask++;_p.mask_inv=undefined;
        }
    }
}

// Primary experiment follows the existing acquisition/economy loop.
function lab_workflow_model(_cfg) {
    var model=lab_validate(_cfg);
    if(!model.ok) return model;
    if(!_cfg.use_initial_state) {
        model.econ.start_money=0;
        for(var i=0;i<array_length(model.items);++i) model.items[i].qty=0;
    }
    return model;
}

// Read actual Create definitions. Probe devices skip board/loot/screw construction.
// Copy values before destroying probes; nothing in the playable room is mutated.
// Saved experiments keep their tuned numbers; only identified gameplay names refresh.
function lab_sync_names(_cfg) {
    var types=game_module_types();
    for(var t=0;t<array_length(types);++t) {
        var asset_name=object_get_name(types[t]),probe=noone;
        for(var i=0;i<array_length(_cfg.modules);++i) {
            var item=_cfg.modules[i];
            if(!struct_exists(item,"object_name")||item.object_name!=asset_name) continue;
            if(!instance_exists(probe)) probe=instance_create_depth(-10000,-10000,0,types[t],{balance_probe:true});
            item.name=probe.module_name;
        }
        if(instance_exists(probe)) instance_destroy(probe);
    }
}

// Add newly authored progression modules to older experiments without resetting tuning.
function lab_sync_adapter_bonus(_cfg) {
    var types=[obj_module_adapter,obj_module_adapter_corner];
    for(var t=0;t<array_length(types);++t) {
        var probe=instance_create_depth(-10000,-10000,0,types[t],{balance_probe:true}),asset_name=object_get_name(types[t]);
        for(var i=0;i<array_length(_cfg.modules);++i) {
            var item=_cfg.modules[i];
            if((struct_exists(item,"object_name")&&item.object_name==asset_name)||item.name==probe.module_name) {
                item.drop_weight="0";item.adapter_bonus=true;
            }
        }
        instance_destroy(probe);
    }
}
function lab_add_progression_modules(_cfg) {
    lab_sync_adapter_bonus(_cfg);
    var revision=struct_exists(_cfg,"progression_catalog_revision")?_cfg.progression_catalog_revision:
        ((struct_exists(_cfg,"tier2_catalog_added")&&_cfg.tier2_catalog_added)?1:0);
    if(revision>=2) return;
    var types=game_module_types(),keys=bal_keys();
    for(var t=0;t<array_length(types);++t) {
        var probe=instance_create_depth(-10000,-10000,0,types[t],{balance_probe:true});
        if(probe.unlock_after_orders<=0||probe.catalog_revision<=revision) {instance_destroy(probe);continue;}
        var asset_name=object_get_name(types[t]),found=false;
        for(var i=0;i<array_length(_cfg.modules);++i) {
            var item=_cfg.modules[i];
            if((struct_exists(item,"object_name")&&item.object_name==asset_name)||item.name==probe.module_name) {found=true;break;}
        }
        if(!found) {
            if(array_length(_cfg.modules)>=40) {instance_destroy(probe);continue;}
            var item={object_name:asset_name,name:probe.module_name,qty:"0",drop_weight:string(probe.drop_weight),stats:{}};
            for(var k=0;k<array_length(keys);++k) struct_set(item.stats,keys[k],string(bal_stat(probe.stats,keys[k])));
            array_push(_cfg.modules,item);
        }
        instance_destroy(probe);
    }
    _cfg.tier2_catalog_added=true; // Later intentional deletions in the experiment stay deleted.
    _cfg.progression_catalog_revision=2;
    lab_sync_adapter_bonus(_cfg);
}

function lab_sync_game(_cfg) {
    if(!struct_exists(_cfg,"game_linked")||!_cfg.game_linked) _cfg.slots="8"; // Search cap, not a game requirement.
    var types=game_module_types(),keys=bal_keys(),items=[],old=_cfg.modules;
    for(var i=0;i<array_length(types);++i) {
        var probe=instance_create_depth(-10000,-10000,0,types[i],{balance_probe:true});
        var asset_name=object_get_name(types[i]),qty="0";
        for(var j=0;j<array_length(old);++j) {
            var matches=struct_exists(old[j],"object_name")?old[j].object_name==asset_name:old[j].name==probe.module_name;
            if(matches) {qty=old[j].qty;break;}
        }
        var item={object_name:asset_name,name:probe.module_name,qty:qty,drop_weight:string(probe.drop_weight),stats:{}};
        for(var k=0;k<array_length(keys);++k) struct_set(item.stats,keys[k],string(bal_stat(probe.stats,keys[k])));
        array_push(items,item);instance_destroy(probe);
    }
    var order=instance_create_depth(-10000,-10000,0,obj_order_2,{balance_probe:true});
    _cfg.modules=items;_cfg.base={};_cfg.min={};_cfg.max={};
    for(var k=0;k<array_length(keys);++k) {
        var key=keys[k];
        struct_set(_cfg.base,key,string(bal_stat(order.stats_base,key)));
        struct_set(_cfg.min,key,struct_exists(order.stats_min,key)?string(struct_get(order.stats_min,key)):"");
        struct_set(_cfg.max,key,struct_exists(order.stats_max,key)?string(struct_get(order.stats_max,key)):"");
    }
    instance_destroy(order);
    // Gameplay has no min-installed rule; slots remains an explicit enumeration limit.
    _cfg.min_installed="0";
    _cfg.game_linked=true;
    lab_sync_adapter_bonus(_cfg);
}

function lab_leftover_metric(_values) {
    var n=array_length(_values),total=0,present=0;
    for(var i=0;i<n;++i) {total+=_values[i];if(_values[i]>0) present++;}
    return {mean:n>0?total/n:0,low:n>0?lab_quantile(_values,0):0,
        median:n>0?lab_quantile(_values,0.5):0,high:n>0?lab_quantile(_values,1):0,present:present};
}
function lab_leftovers(_job) {
    var money=[],modules=[],pending=[],items=[],samples=[];
    for(var i=0;i<array_length(_job.model.items);++i) array_push(samples,[]);
    for(var r=0;r<array_length(_job.runs);++r) {
        var run=_job.runs[r];if(!run.success) continue;
        array_push(money,run.money);array_push(pending,run.pending);
        var total=0;
        for(var i=0;i<array_length(samples);++i) {
            var values=samples[i];array_push(values,run.inventory[i]);samples[i]=values;total+=run.inventory[i];
        }
        array_push(modules,total);
    }
    for(var i=0;i<array_length(samples);++i) array_push(items,lab_leftover_metric(samples[i]));
    return {count:array_length(money),money:lab_leftover_metric(money),modules:lab_leftover_metric(modules),pending:lab_leftover_metric(pending),items:items};
}
