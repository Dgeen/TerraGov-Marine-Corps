// ***************************************
// *********** Blink
// ***************************************
/datum/action/ability/activable/xeno/blink
	ability_cost = 15


// ***************************************
// *********** Timestop
// ***************************************
/datum/action/ability/xeno_action/timestop
	ability_cost = 50
	cooldown_duration = 30 SECONDS

// ***************************************
// *********** Portal
// ***************************************
/datum/action/ability/xeno_action/portal
	ability_cost = 30

/obj/effect/wraith_portal/Initialize(mapload, _hivenumber)
	. = ..()
	SSminimaps.add_marker(src, MINIMAP_FLAG_XENO, image('modular_RUtgmc/icons/UI_icons/map_blips.dmi', null, "[icon_state]"))

// ***************************************
// *********** Rewind
// ***************************************
/// Move the target two tiles per tick
/datum/action/ability/activable/xeno/rewind/rewind()
	var/turf/loc_a = pop(last_target_locs_list)
	if(loc_a)
		new /obj/effect/temp_visual/xenomorph/afterimage(targeted.loc, targeted)

	var/turf/loc_b = pop(last_target_locs_list)
	if(!loc_b)
		targeted.status_flags &= ~(INCORPOREAL|GODMODE)
		REMOVE_TRAIT(owner, TRAIT_IMMOBILE, TIMESHIFT_TRAIT)
		if(target_initial_on_fire && target_initial_fire_stacks >= 0)
			targeted.fire_stacks = target_initial_fire_stacks
			targeted.IgniteMob()
		else
			targeted.ExtinguishMob()
		if(isxeno(targeted))
			targeted.heal_overall_damage(targeted.getBruteLoss() - target_initial_brute_damage, targeted.getFireLoss() - target_initial_burn_damage, updating_health = TRUE)
			var/mob/living/carbon/xenomorph/xeno_target = targeted
			xeno_target.sunder = target_initial_sunder
		targeted.remove_filter("rewind_blur")
		REMOVE_TRAIT(targeted, TRAIT_TIME_SHIFTED, XENO_TRAIT)
		targeted = null
		return

	targeted.Move(loc_b, get_dir(loc_b, loc_a))
	new /obj/effect/temp_visual/xenomorph/afterimage(loc_a, targeted)
	INVOKE_NEXT_TICK(src, PROC_REF(rewind))
