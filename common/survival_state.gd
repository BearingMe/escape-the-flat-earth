class_name SurvivalState
extends RefCounted

const NORMAL_BODY_TEMP_C: float = 37.0
const HYPOTHERMIA_TEMP_C: float = 33.0
const HEATSTROKE_TEMP_C: float = 40.0
const MAX_STAT_VALUE: float = 100.0
const DEFAULT_BLEEDOUT_SEC: float = 30.0

var health: float = 100.0
var stamina: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var core_temperature_c: float = NORMAL_BODY_TEMP_C
var is_incapacitated: bool = false
var bleedout_timer_sec: float = DEFAULT_BLEEDOUT_SEC
var is_dead: bool = false

var hunger_rate: float = 0.04
var thirst_rate: float = 0.07
var stamina_drain_sprint: float = 15.0
var stamina_drain_climb: float = 20.0
var stamina_regen: float = 22.0
var thermal_transfer_rate: float = 0.015


func tick(
	delta: float,
	ambient_temp_c: float,
	is_sprinting: bool,
	is_climbing: bool,
	is_underside: bool = false
) -> Dictionary:
	var events: Dictionary = {
		"health_lost": 0.0,
		"knocked_down": false,
		"died": false,
	}

	if is_dead:
		return events

	if is_incapacitated:
		bleedout_timer_sec -= delta
		if bleedout_timer_sec <= 0.0:
			is_dead = true
			events["died"] = true
		return events

	# 1. Stamina Drain / Regeneration
	if is_climbing:
		stamina = maxf(stamina - stamina_drain_climb * delta, 0.0)
	elif is_sprinting:
		stamina = maxf(stamina - stamina_drain_sprint * delta, 0.0)
	else:
		stamina = minf(stamina + stamina_regen * delta, MAX_STAT_VALUE)

	# 2. Metabolic Drain (Hunger & Thirst)
	var sprint_multiplier: float = 1.5 if is_sprinting else 1.0
	hunger = maxf(hunger - hunger_rate * sprint_multiplier * delta, 0.0)
	thirst = maxf(thirst - thirst_rate * sprint_multiplier * delta, 0.0)

	# 3. Thermal Transfer with Ambient Weather (Underside is freezing)
	var target_ambient: float = -20.0 if is_underside else ambient_temp_c
	var temp_diff: float = target_ambient - core_temperature_c
	core_temperature_c += temp_diff * thermal_transfer_rate * delta
	core_temperature_c = clampf(core_temperature_c, 24.0, 44.0)

	# 4. Attrition Damage
	var attrition_damage: float = 0.0
	if hunger <= 0.0:
		attrition_damage += 2.0 * delta  # Starvation
	if thirst <= 0.0:
		attrition_damage += 4.0 * delta  # Dehydration
	if core_temperature_c <= HYPOTHERMIA_TEMP_C:
		attrition_damage += 5.0 * delta  # Hypothermia
	elif core_temperature_c >= HEATSTROKE_TEMP_C:
		attrition_damage += 3.5 * delta  # Heat stroke

	if attrition_damage > 0.0:
		apply_damage(attrition_damage)
		events["health_lost"] = attrition_damage
		if is_incapacitated:
			events["knocked_down"] = true

	return events


func apply_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	if health <= 0.0 and not is_incapacitated:
		is_incapacitated = true
		bleedout_timer_sec = DEFAULT_BLEEDOUT_SEC


func revive(heal_amount: float = 35.0) -> bool:
	if not is_incapacitated or is_dead:
		return false
	is_incapacitated = false
	bleedout_timer_sec = DEFAULT_BLEEDOUT_SEC
	health = clampf(heal_amount, 10.0, MAX_STAT_VALUE)
	return true


func consume(food_val: float, water_val: float, heal_val: float, temp_mod: float = 0.0) -> void:
	if is_dead:
		return
	hunger = minf(hunger + food_val, MAX_STAT_VALUE)
	thirst = minf(thirst + water_val, MAX_STAT_VALUE)
	if not is_incapacitated and heal_val > 0.0:
		health = minf(health + heal_val, MAX_STAT_VALUE)
	if temp_mod != 0.0:
		core_temperature_c = clampf(core_temperature_c + temp_mod, 28.0, 42.0)


func can_sprint() -> bool:
	return stamina > 5.0 and not is_incapacitated and not is_dead


func to_dictionary() -> Dictionary:
	return {
		"health": health,
		"stamina": stamina,
		"hunger": hunger,
		"thirst": thirst,
		"core_temp_c": core_temperature_c,
		"is_incapacitated": is_incapacitated,
		"bleedout_sec": bleedout_timer_sec,
		"is_dead": is_dead,
	}


func apply_dictionary(dict: Dictionary) -> void:
	if dict.has("health"):
		health = float(dict["health"])
	if dict.has("stamina"):
		stamina = float(dict["stamina"])
	if dict.has("hunger"):
		hunger = float(dict["hunger"])
	if dict.has("thirst"):
		thirst = float(dict["thirst"])
	if dict.has("core_temp_c"):
		core_temperature_c = float(dict["core_temp_c"])
	if dict.has("is_incapacitated"):
		is_incapacitated = bool(dict["is_incapacitated"])
	if dict.has("bleedout_sec"):
		bleedout_timer_sec = float(dict["bleedout_sec"])
	if dict.has("is_dead"):
		is_dead = bool(dict["is_dead"])
