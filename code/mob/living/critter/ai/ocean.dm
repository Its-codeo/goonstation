
/datum/aiHolder/trilobite
	exclude_from_mobs_list = 1

/datum/aiHolder/trilobite/New()
	..()
	var/datum/aiTask/timed/targeted/trilobite/D = get_instance(/datum/aiTask/timed/targeted/trilobite, list(src))
	var/datum/aiTask/timed/B = get_instance(/datum/aiTask/timed/bury_ability, list(src))
	D.escape = get_instance(/datum/aiTask/timed/targeted/escape_vehicles, list(src))
	D.escape.transition_task = B
	D.transition_task = B
	B.transition_task = D
	default_task = D

/datum/aiTask/timed/bury_ability
	name = "bury"
	minimum_task_ticks = 1
	maximum_task_ticks = 1

	tick()
		..()
		if (holder.owner.abilityHolder)
			var/datum/targetable/critter/bury_hide/BH = holder.owner.abilityHolder.getAbility(/datum/targetable/critter/bury_hide)
			BH.cast(get_turf(holder.owner))

/datum/aiTask/timed/targeted/trilobite
	name = "attack"
	minimum_task_ticks = 7
	maximum_task_ticks = 20
	var/weight = 15
	target_range = 8
	frustration_threshold = 3
	var/last_seek = 0

	var/datum/aiTask/timed/escape = null


/datum/aiTask/timed/targeted/trilobite/proc/precondition()
	. = 1

/datum/aiTask/timed/targeted/trilobite/frustration_check()
	.= 0
	var/dist = get_dist(holder.owner, holder.target)
	if (dist > target_range)
		return 1

	if (ismob(holder.target))
		var/mob/M = holder.target
		. = !(holder.target && isalive(M))
	else
		. = !(holder.target)

/datum/aiTask/timed/targeted/trilobite/evaluate()
	return precondition() * weight * score_target(get_best_target(get_targets()))

/datum/aiTask/timed/targeted/trilobite/on_tick()
	if (HAS_MOB_PROPERTY(holder.owner, PROP_CANTMOVE))
		return

	if(!holder.target)
		if (world.time > last_seek + 4 SECONDS)
			last_seek = world.time
			var/list/possible = get_targets()
			if (possible.len)
				holder.target = pick(possible)
	if(holder.target)
		var/mob/living/M = holder.target
		if(!isalive(M))
			holder.target = null
			holder.target = get_best_target(get_targets())
			if(!holder.target)
				return ..() // try again next tick
		var/dist = get_dist(holder.owner, M)
		if (dist > 2)
			holder.move_to(M)
		else
			holder.move_away(M,1)

		if (dist < 4)
			if (M.equipped())
				holder.owner.a_intent = prob(66) ? INTENT_DISARM : INTENT_HARM
			else
				holder.owner.a_intent = INTENT_HARM

			holder.owner.hud.update_intent()
			holder.owner.dir = get_dir(holder.owner, M)

			var/list/params = list()
			params["left"] = 1
			params["ai"] = 1
			holder.owner.hand_range_attack(M, params)

	..()

/datum/aiTask/timed/targeted/trilobite/get_targets()
	var/list/targets = list()
	if(holder.owner)
		for (var/atom in pods_and_cruisers)
			var/atom/A = atom
			if (A && holder.owner.z == A.z && get_dist(holder.owner,A) <= 6)
				holder.current_task = src.escape
				src.escape.reset()

		for(var/mob/living/M in view(target_range, holder.owner))
			if(isalive(M) && !ismobcritter(M))
				targets += M
	return targets





/datum/aiTask/timed/targeted/escape_vehicles
	name = "attack"
	minimum_task_ticks = 1
	maximum_task_ticks = 4
	target_range = 7
	frustration_threshold = 10
	var/last_seek = 0

	var/datum/aiTask/escape = null

/datum/aiTask/timed/targeted/escape_vehicles/frustration_check()
	.= 0
	var/dist = get_dist(holder.owner, holder.target)
	if (dist <= target_range/2)
		return 1

/datum/aiTask/timed/targeted/escape_vehicles/on_tick()
	if (HAS_MOB_PROPERTY(holder.owner, PROP_CANTMOVE))
		return

	if(!holder.target)
		if (world.time > last_seek + 4 SECONDS)
			last_seek = world.time
			var/list/possible = get_targets()
			if (possible.len)
				holder.target = pick(possible)
	if(holder.target)
		holder.move_away(holder.target,target_range)

	..()

/datum/aiTask/timed/targeted/escape_vehicles/get_targets()
	var/list/targets = list()
	if(holder.owner)
		for (var/atom in pods_and_cruisers)
			var/atom/A = atom
			if (A && holder.owner.z == A.z && get_dist(holder.owner,A) < target_range)
				targets += A
	return targets



/datum/aiHolder/spike
	exclude_from_mobs_list = 1

/datum/aiHolder/spike/New()
	..()
	default_task = get_instance(/datum/aiTask/timed/targeted/flee_and_shoot, list(src))

/datum/aiHolder/spike/was_harmed(obj/item/W, mob/M)
	current_task = get_instance(/datum/aiTask/timed/targeted/flee_and_shoot, list(src))
	current_task.reset()

/datum/aiTask/timed/targeted/flee_and_shoot
	name = "attack"
	minimum_task_ticks = 7
	maximum_task_ticks = 20
	var/weight = 15
	target_range = 7
	frustration_threshold = 3

/datum/aiTask/timed/targeted/flee_and_shoot/frustration_check()
	.= 0
	var/dist = get_dist(holder.owner, holder.target)
	if (dist >= target_range)
		return 1

	if (ismob(holder.target))
		var/mob/M = holder.target
		. = !(holder.target && isalive(M))
	else
		. = !(holder.target)

/datum/aiTask/timed/targeted/flee_and_shoot/on_tick()
	if (HAS_MOB_PROPERTY(holder.owner, PROP_CANTMOVE))
		return

	if(!holder.target)
		var/list/possible = get_targets()
		if (possible.len)
			holder.target = pick(possible)
		if (!holder.target)
			holder.wait()

	if(holder.target)
		if (ismob(holder.target))
			var/mob/living/M = holder.target
			if(!isalive(M))
				holder.target = null
				holder.target = get_best_target(get_targets())
				if(!holder.target)
					return ..() // try again next tick

		var/dist = get_dist(holder.owner, holder.target)
		if (dist > target_range)
			holder.target = null
			return ..()

		holder.move_away(holder.target,target_range)

		holder.owner.a_intent = INTENT_HARM

		holder.owner.hud.update_intent()
		holder.owner.dir = get_dir(holder.owner, holder.target)

		var/list/params = list()
		params["left"] = 1
		params["ai"] = 1
		holder.owner.hand_range_attack(holder.target, params)

	..()

/datum/aiTask/timed/targeted/flee_and_shoot/get_targets()
	var/list/targets = list()
	if(holder.owner)
		for (var/atom in pods_and_cruisers)
			var/atom/A = atom
			if (A && holder.owner.z == A.z && get_dist(holder.owner,A) <= 6)
				targets += A
		for(var/mob/living/M in view(target_range, holder.owner))
			if(isalive(M) && !ismobcritter(M))
				targets += M

	return targets