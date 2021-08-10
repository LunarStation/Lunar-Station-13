SUBSYSTEM_DEF(autoclone)
	name = "Autoclone"
	wait = 600
	init_order = INIT_ORDER_AUTOCLONE
	runlevels = RUNLEVEL_GAME
	flags = SS_NO_INIT

	var/list/cloners = list()
	var/list/running = list()
	var/list/currentrun = list()

/datum/controller/subsystem/autoclone/fire(resumed = FALSE)
	if(!resumed)
		src.currentrun = running.Copy()
		cloners = list()
		for(var/obj/machinery/clonepod/autocloner/cloner in GLOB.machines)
			if(istype(cloner))
				cloners |= cloner

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/datum/data/record/R = currentrun[currentrun.len]
		currentrun.len--
		if(R.fields["current_wait"]==0 && !R.fields["waiting_for_response"])
			var/datum/mind/clonemind = locate(R.fields["mind"]) in SSticker.minds
			if(clonemind.current.stat != DEAD)
				running.Remove(R)
			else
				var/mob/dead/observer/G = clonemind.get_ghost()
				if(G)
					tgui_alert_async(G, "Would you like to be autocloned?","Autoclone prompt", list("Yes","No","Stop asking me"),CALLBACK(src, .proc/query_response, R))
					R.fields["waiting_for_response"] = TRUE
		else
			if(R.fields["waiting_for_response"]==2)
				clone(R)
			else if(R.fields["waiting_for_response"]==0)
				R.fields["current_wait"]-=1
		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/autoclone/proc/clone(var/datum/data/record/R)
	for(var/obj/machinery/clonepod/autocloner/cloner in cloners)
		if(cloner.growclone(R.fields["ckey"], R.fields["name"], R.fields["UI"], R.fields["SE"], R.fields["mind"], R.fields["blood_type"], R.fields["mrace"], R.fields["features"], R.fields["factions"], R.fields["quirks"], R.fields["bank_account"], R.fields["traumas"]))
			running.Remove(R)
			return

/datum/controller/subsystem/autoclone/proc/add_to_queue(var/datum/data/record/R)
	R.fields["current_wait"] = 15
	R.fields["waiting_for_response"] = FALSE
	running |= R

/datum/controller/subsystem/autoclone/proc/query_response(var/datum/data/record/R,response)
	switch(response)
		if("Yes")
			R.fields["waiting_for_response"]=2
			clone(R)
		if("No")
			R.fields["waiting_for_response"]=0
			R.fields["current_wait"] = 5
		if("Stop asking me")
			running.Remove(R)