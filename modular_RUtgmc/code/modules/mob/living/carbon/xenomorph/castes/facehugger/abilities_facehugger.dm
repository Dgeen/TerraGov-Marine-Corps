#define HUG_RANGE 1

// ***************************************
// *********** Hug
// ***************************************

/datum/action/ability/activable/xeno/pounce_hugger
	name = "Pounce"
	action_icon_state = "pounce"
	desc = "Leap at your target and knock them down, if you jump close you will hug the target."
	ability_cost = 25
	cooldown_duration = 5 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSING_XENOABILITY_HUGGER_POUNCE,
	)
	use_state_flags = ABILITY_USE_BUCKLED
	///How far can we leap.
	var/range = 6
	///For how long will we stun the victim
	var/victim_paralyze_time = 1 SECONDS
	///For how long will we freeze upon hitting our target
	var/freeze_on_hit_time = 1 SECONDS
	///How long is the windup before leap
	var/windup_time = 1 SECONDS
	///Where do we start the leap from
	var/start_turf

// TODO: merge this ability into runner pounce (can't do it right now - the runner's pounce has too many unnecessary sounds/messages)
/datum/action/ability/activable/xeno/pounce_hugger/proc/pounce_complete()
	SIGNAL_HANDLER
	var/mob/living/carbon/xenomorph/caster = owner
	caster.pass_flags = initial(caster.pass_flags)
	caster.icon_state = "[caster.xeno_caste.caste_name] Walking"
	UnregisterSignal(owner, list(COMSIG_XENO_OBJ_THROW_HIT, COMSIG_MOVABLE_POST_THROW, COMSIG_XENOMORPH_LEAP_BUMP))

/datum/action/ability/activable/xeno/pounce_hugger/proc/obj_hit(datum/source, obj/target, speed)
	SIGNAL_HANDLER
	target.hitby(owner, speed)
	pounce_complete()

/datum/action/ability/activable/xeno/pounce_hugger/proc/mob_hit(datum/source, mob/living/living_target)
	SIGNAL_HANDLER
	. = TRUE
	if(living_target.stat || isxeno(living_target)) //we leap past xenos
		return

	var/mob/living/carbon/xenomorph/facehugger/caster = owner

	caster.visible_message(span_danger("[caster] leaps on [living_target]!"),
				span_xenodanger("We leap on [living_target]!"), null, 5)
	playsound(caster.loc, 'sound/voice/alien_roar_larva3.ogg', 25, TRUE) //TODO: I NEED ACTUAL HUGGERS SOUND DAMMED

	if(ishuman(living_target) && (angle_to_dir(Get_Angle(caster.throw_source, living_target)) in reverse_nearby_direction(living_target.dir)))
		var/mob/living/carbon/human/human_target = living_target
		if(!human_target.check_shields(COMBAT_TOUCH_ATTACK, 30, "melee"))
			caster.Paralyze(XENO_POUNCE_SHIELD_STUN_DURATION)
			caster.set_throwing(FALSE)
			return

	trigger_pounce_effect(living_target)
	pounce_complete()

///Triggers the effect of a successful pounce on the target.
/datum/action/ability/activable/xeno/pounce_hugger/proc/trigger_pounce_effect(mob/living/living_target)
	var/mob/living/carbon/xenomorph/facehugger/caster = owner
	caster.forceMove(get_turf(living_target))
	if(ishuman(living_target))
		var/mob/living/carbon/human/H = living_target
		if(get_dist(start_turf, H) <= HUG_RANGE) //Check whether we hugged the target or just knocked it down
			caster.try_attach(H)
		else
			H.Paralyze(victim_paralyze_time)
			caster.Immobilize(freeze_on_hit_time)

/datum/action/ability/activable/xeno/pounce_hugger/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE

	if(!A || A.layer >= FLY_LAYER)
		return FALSE

/datum/action/ability/activable/xeno/pounce_hugger/proc/prepare_to_pounce()
	if(owner.layer == XENO_HIDING_LAYER) //Xeno is currently hiding, unhide him
		owner.layer = MOB_LAYER
		var/datum/action/ability/xeno_action/xenohide/hide_action = owner.actions_by_path[/datum/action/ability/xeno_action/xenohide]
		hide_action?.button?.cut_overlay(mutable_appearance('modular_RUtgmc/icons/Xeno/actions.dmi', "selected_purple_frame", ACTION_LAYER_ACTION_ICON_STATE, FLOAT_PLANE)) // Removes Hide action icon border
	if(owner.buckled)
		owner.buckled.unbuckle_mob(owner)

/datum/action/ability/activable/xeno/pounce_hugger/use_ability(atom/A)
	var/mob/living/carbon/xenomorph/caster = owner

	prepare_to_pounce()
	if(!do_after(caster, windup_time, FALSE, caster, BUSY_ICON_DANGER, extra_checks = CALLBACK(src, PROC_REF(can_use_ability), A, FALSE, ABILITY_USE_BUSY)))
		return fail_activate()

	caster.icon_state = "[caster.xeno_caste.caste_name] Thrown"

	caster.visible_message(span_xenowarning("\The [caster] leaps at [A]!"), \
	span_xenowarning("We leap at [A]!"))

	RegisterSignal(caster, COMSIG_XENO_OBJ_THROW_HIT, PROC_REF(obj_hit))
	RegisterSignal(caster, COMSIG_XENOMORPH_LEAP_BUMP, PROC_REF(mob_hit))
	RegisterSignal(caster, COMSIG_MOVABLE_POST_THROW, PROC_REF(pounce_complete))

	succeed_activate()
	add_cooldown()
	caster.xeno_flags |= XENO_LEAPING
	caster.pass_flags |= PASS_LOW_STRUCTURE|PASS_FIRE
	caster.pass_flags ^= PASS_MOB

	start_turf = get_turf(caster)
	if(ishuman(A) && get_turf(A) == start_turf)
		mob_hit(caster, A)
	caster.throw_at(A, range, 2, caster)

	return TRUE

	//AI stuff
/datum/action/ability/activable/xeno/pounce_hugger/ai_should_start_consider()
	return TRUE

/datum/action/ability/activable/xeno/pounce_hugger/ai_should_use(atom/target)
	if(!ishuman(target))
		return FALSE
	if(!line_of_sight(owner, target, HUG_RANGE))
		return FALSE
	if(!can_use_action(override_flags = ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	if(target.get_xeno_hivenumber() == owner.get_xeno_hivenumber())
		return FALSE
	action_activate()
	LAZYINCREMENT(owner.do_actions, target)
	addtimer(CALLBACK(src, PROC_REF(decrease_do_action), target), windup_time)
	return TRUE

///Decrease the do_actions of the owner
/datum/action/ability/activable/xeno/pounce_hugger/proc/decrease_do_action(atom/target)
	LAZYDECREMENT(owner.do_actions, target)

#undef HUG_RANGE
