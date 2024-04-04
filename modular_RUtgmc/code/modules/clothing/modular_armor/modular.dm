#define HAIR_NOT_HIDDEN HIDEEARS
#define HAIR_ONLY_BEARD HIDEEARS|HIDETOPHAIR
#define HAIR_SEMI_HIDDEN HIDEEARS|HIDE_EXCESS_HAIR
#define HAIR_FULLY_HIDDEN HIDEEARS|HIDEALLHAIR

/obj/item/clothing/head/modular/attack_self(mob/user)
	. = ..()
	if(!ishuman(user))
		return

	switch(inv_hide_flags)
		if(HAIR_SEMI_HIDDEN)
			inv_hide_flags = HAIR_FULLY_HIDDEN
			user.balloon_alert(user, "Fully hiding hair")
		if(HAIR_FULLY_HIDDEN)
			inv_hide_flags = HAIR_NOT_HIDDEN
			user.balloon_alert(user, "Revealing hair entirely")
		if(HAIR_NOT_HIDDEN)
			inv_hide_flags = HAIR_ONLY_BEARD
			user.balloon_alert(user, "Hiding only upper hair")
		if(HAIR_ONLY_BEARD)
			inv_hide_flags = HAIR_SEMI_HIDDEN
			user.balloon_alert(user, "Partially hiding hair")

/obj/item/clothing/head/modular/examine(mob/user)
	. = ..()
	. += span_notice("You can make it completely hide or reveal your hair by <b>using it in-hand</b> few times.")

#undef HAIR_NOT_HIDDEN
#undef HAIR_ONLY_BEARD
#undef HAIR_SEMI_HIDDEN
#undef HAIR_FULLY_HIDDEN
