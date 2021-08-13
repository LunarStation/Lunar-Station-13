/obj/machinery/clonepod/autocloner
	name = "Automatic cloning pod"
	desc = "An electronically-lockable pod for growing organic tissue. This one automatically clones dead crewmembers."
	//Automatic cloner should heal fully and take around 30-45 seconds
	heal_level = 100
	speed_coeff = 15
	efficiency = 5
	//Automatic cloner should not be able to be deconstructed, nor destroyed since it can't be built otherwise.
	flags_1 = DEFAULT_RICOCHET_1 | NODECONSTRUCT_1
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	//Doesn't use any power
	active_power_usage = 0
	idle_power_usage = 0
	use_power = 0

/obj/machinery/clonepod/autocloner/RefreshParts() //This would ordinaly set healing level and speed. We want those to stay constant, though.
	return

/obj/machinery/clonepod/autocloner/is_operational() //Should always be powered and functional
	return TRUE 

/obj/machinery/clonepod/autocloner/power_change() //Do not be bothered by changes in the power
	return

/obj/machinery/clonepod/autocloner/emag_act()
	return

/obj/machinery/clonepod/autocloner/growclone(ckey, clonename, ui, mutation_index, mindref, blood_type, datum/species/mrace, list/features, factions, list/quirks, datum/bank_account/insurance, list/traumas)
	if(panel_open)
		return FALSE
	if(mess || attempting)
		return FALSE
	if(get_clone_mind == CLONEPOD_GET_MIND)
		clonemind = locate(mindref) in SSticker.minds
		if(!istype(clonemind))	//not a mind
			return FALSE
		if(!QDELETED(clonemind.current))
			if(clonemind.current.stat != DEAD)	//mind is associated with a non-dead body
				return FALSE
			//if(clonemind.current.suiciding) // Mind is associated with a body that is suiciding.
			//	return FALSE //Does not matter to us if they suicided
			if(AmBloodsucker(clonemind.current)) //If the mind is a bloodsucker
				return FALSE
		if(clonemind.active)	//somebody is using that mind
			if( ckey(clonemind.key)!=ckey )
				return FALSE
		else
			// get_ghost() will fail if they're unable to reenter their body
			var/mob/dead/observer/G = clonemind.get_ghost()
			if(!G)
				return FALSE
			//if(G.suiciding) // The ghost came from a body that is suiciding.
			//	return FALSE
		if(clonemind.damnation_type) //Can't clone the damned.
			INVOKE_ASYNC(src, .proc/horrifyingsound)
			mess = TRUE
			update_icon()
			return FALSE
	current_insurance = insurance
	attempting = TRUE //One at a time!!
	countdown.start()

	var/mob/living/carbon/human/H = new /mob/living/carbon/human(src)

	H.hardset_dna(ui, mutation_index, H.real_name, blood_type, mrace, features)

	//No more adding bad traits to people who are cloned.
	//H.easy_randmut(NEGATIVE+MINOR_NEGATIVE) //100% bad mutation. Can be cured with mutadone.

	H.silent = 20 //Prevents an extreme edge case where clones could speak if they said something at exactly the right moment.
	occupant = H

	if(!clonename)	//to prevent null names
		clonename = "clone ([rand(1,999)])"
	H.real_name = clonename

	//Get the clone body ready
	maim_clone(H)
	ADD_TRAIT(H, TRAIT_MUTATION_STASIS, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_STABLEHEART, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_STABLELIVER, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_EMOTEMUTE, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_MUTE, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_NOBREATH, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_NOCRITDAMAGE, CLONING_POD_TRAIT)
	H.Unconscious(80)

	if(clonemind)
		clonemind.transfer_to(H)

	else if(get_clone_mind == CLONEPOD_POLL_MIND)
		poll_for_mind(H, clonename)

	if(grab_ghost_when == CLONER_FRESH_CLONE)
		H.grab_ghost()
		to_chat(H, "<span class='notice'><b>Consciousness slowly creeps over you as your body regenerates.</b><br><i>So this is what cloning feels like?</i></span>")

	if(grab_ghost_when == CLONER_MATURE_CLONE)
		H.ghostize(TRUE)	//Only does anything if they were still in their old body and not already a ghost
		to_chat(H.get_ghost(TRUE), "<span class='notice'>Your body is beginning to regenerate in a cloning pod. You will become conscious when it is complete.</span>")

	if(H)
		H.faction |= factions

		for(var/V in quirks)
			var/datum/quirk/Q = new V(H)
			Q.on_clone(quirks[V])

		for(var/t in traumas)
			var/datum/brain_trauma/BT = t
			var/datum/brain_trauma/cloned_trauma = BT.on_clone()
			if(cloned_trauma)
				H.gain_trauma(cloned_trauma, BT.resilience)

		//This just sets hair (which is just annoying) and sets any underwear to Nude, which is unnecessary.
		//H.set_cloned_appearance()
		H.give_genitals(TRUE)

		H.suiciding = FALSE
	attempting = FALSE
	return TRUE
