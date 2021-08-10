/mob/living/carbon/human/proc/should_autoclone(datum/dna/dna, mob/living/mob_occupant, datum/bank_account/account)
	if(!istype(dna))
		message_admins("[key_name(mob_occupant)] died and could not be autocloned because they have no DNA")
		log_admin("[key_name(mob_occupant)] died and could not be autocloned because they have no DNA")
		return FALSE
	if(!(ckey || (istype(mind) && mind.key)))
		message_admins("[mob_occupant] died and could not be autocloned because no ckey could be associated")
		log_admin("[mob_occupant] died and could not be autocloned because no ckey could be associated")
		return FALSE
	if(!istype(bank_account)) //This is to prevent non-crew members from being autocloned
		message_admins("[key_name(mob_occupant)] died and could not be autocloned because no bank account could be associated")
		log_admin("[key_name(mob_occupant)] died and could not be autocloned because no bank account could be associated")
		return FALSE
	return TRUE

/mob/living/carbon/human/proc/get_bank_account_robust() //We are going to find that bank account one way or another, if it exists
	var/datum/bank_account/bank_acc = src.get_bank_account() //This checks their ID card to find a linked bank account
	if(istype(bank_acc) && account.account_id == src.account_id) //Make sure the bank account actually belongs to them
		return bank_acc
	else //If we can't get one from their ID, or they don't have an ID, we'll check all the bank accounts to see if they belong
		for(var/datum/bank_account/account in SSeconomy.bank_accounts)
			if(account.account_id == src.account_id) //This pretty much guaruntees they are the account owner
				return account
	

/mob/living/carbon/human/proc/attempt_autoclone()
	var/mob/living/mob_occupant = get_mob_or_brainmob(src)
	var/datum/dna/dna
	var/datum/bank_account/has_bank_account

	// Do not use unless you know what they are.
	var/mob/living/carbon/C = mob_occupant
	var/mob/living/brain/B = mob_occupant

	if(ishuman(mob_occupant))
		dna = C.has_dna()
		has_bank_account = get_bank_account_robust()
	if(isbrain(mob_occupant))
		dna = B.stored_dna

	if(should_autoclone(dna, mob_occupant, FALSE, has_bank_account))
		var/datum/data/record/R = new()
		if(dna.species)
			// We store the instance rather than the path, because some
			// species (abductors, slimepeople) store state in their
			// species datums
			dna.delete_species = FALSE
			R.fields["mrace"] = dna.species
		else
			var/datum/species/rando_race = pick(GLOB.roundstart_races)
			R.fields["mrace"] = rando_race.type

		R.fields["ckey"] = mob_occupant.ckey
		R.fields["name"] = mob_occupant.real_name
		R.fields["id"] = copytext_char(md5(mob_occupant.real_name), 2, 6)
		R.fields["UE"] = dna.unique_enzymes
		R.fields["UI"] = dna.uni_identity
		R.fields["SE"] = dna.mutation_index
		R.fields["blood_type"] = dna.blood_type
		R.fields["features"] = dna.features
		R.fields["factions"] = mob_occupant.faction
		R.fields["quirks"] = list()
		for(var/V in mob_occupant.roundstart_quirks)
			var/datum/quirk/T = V
			R.fields["quirks"][T.type] = T.clone_data()

		R.fields["traumas"] = list()
		if(ishuman(mob_occupant))
			R.fields["traumas"] = C.get_traumas()
		if(isbrain(mob_occupant))
			R.fields["traumas"] = B.get_traumas()

		R.fields["bank_account"] = has_bank_account
		if (!isnull(mob_occupant.mind)) //Save that mind so traitors can continue traitoring after cloning.
			R.fields["mind"] = "[REF(mob_occupant.mind)]"

	   //Add an implant if needed
		var/obj/item/implant/health/imp
		for(var/obj/item/implant/health/HI in mob_occupant.implants)
			imp = HI
			break
		if(!imp)
			imp = new /obj/item/implant/health(mob_occupant)
			imp.implant(mob_occupant)
		R.fields["imp"] = "[REF(imp)]"
		SSautoclone.add_to_queue(R)

/mob/living/carbon/human/death(gibbed)
	attempt_autoclone()

	. = ..()

/mob/living/carbon/human/Destroy()
	attempt_autoclone()

	. = ..()