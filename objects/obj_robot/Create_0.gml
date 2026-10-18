// Configuration (product_id, energy_cost, work_seconds, reward) is supplied by shop_buy.
visible=false;
working=false;
powered=false;
power_allocated=false; // Explicit player allocation; never inferred from a running job.
remaining=0;
target_device=noone;
board_device=noone;
target_module=noone;
outputs=[];
recipes=[];recipe_index=-1;recipe_scroll=0;
recycle_value=0;
has_plate=false; // Soldering reserves one table plate until this job finishes.
work_frame=0; // Independent robot animation, advanced by powered working time.
power_hint_remaining=0;power_hint_elapsed=0;
