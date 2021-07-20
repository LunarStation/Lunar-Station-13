/datum/species/teshari
	name = "Teshari"
	id = SPECIES_TESHARI
	attack_verb = "slash"
	attack_sound = 'sound/weapons/slash.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'
	mutantlungs = /obj/item/organ/lungs/teshari
	species_traits = list(MUTCOLORS,EYECOLOR,HAIR,FACEHAIR,LIPS,HORNCOLOR,WINGCOLOR,CAN_SCAR,HAS_FLESH,HAS_BONE)
	mutant_bodyparts = list("mcolor" = "FFFFFF","mcolor2" = "FFFFFF","mcolor3" = "FFFFFF", "mam_tail" = "Teshari", "mam_ears" = "Teshari", "mam_body_markings" = list())

	brutemod = 1.35
	burnmod =  1.35
	speedmod = -1
	max_health = 50
	eye_type = "teshari"

	custom_prosthetics = list("DSI", "unbranded", "cenilimi")

/datum/species/teshari/before_equip_job(datum/job/J, mob/living/carbon/human/H, visualsOnly = FALSE)
	var/datum/outfit/teshari/O = new /datum/outfit/teshari
	if(J)
		if(J.tesh_outfit)
			O = new J.tesh_outfit

	H.equipOutfit(O, visualsOnly)
	return 0
