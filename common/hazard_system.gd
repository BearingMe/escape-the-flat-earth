class_name HazardSystem
extends RefCounted

var barrier_center: Vector2 = Vector2.ZERO
var initial_radius_m: float = 5000.0
var final_radius_m: float = 250.0
var total_contraction_duration_sec: float = 600.0
var elapsed_sec: float = 0.0


func configure(
	start_radius: float = 5000.0,
	end_radius: float = 250.0,
	duration_sec: float = 600.0,
	center: Vector2 = Vector2.ZERO
) -> void:
	initial_radius_m = maxf(start_radius, 100.0)
	final_radius_m = maxf(end_radius, 50.0)
	total_contraction_duration_sec = maxf(duration_sec, 10.0)
	barrier_center = center
	elapsed_sec = 0.0


func advance_time(delta: float) -> void:
	if delta > 0.0:
		elapsed_sec += delta


func get_current_barrier_radius() -> float:
	var progress: float = clampf(elapsed_sec / total_contraction_duration_sec, 0.0, 1.0)
	# Smoothstep contraction
	var smooth_p: float = progress * progress * (3.0 - 2.0 * progress)
	return lerpf(initial_radius_m, final_radius_m, smooth_p)


func evaluate_player_hazards(
	player: ObserverPlayer, weather: WeatherCondition, delta: float
) -> Dictionary:
	var result: Dictionary = {
		"damage": 0.0,
		"push_vector": Vector3.ZERO,
		"in_storm": false,
		"frostbite": false,
	}
	if player == null or not player.is_alive or delta <= 0.0:
		return result

	var current_radius: float = get_current_barrier_radius()
	var pos: Vector3 = player.global_position

	# 1. Firmament storm barrier check
	var is_safe: bool = EnvironmentalHazardModel.is_inside_safe_zone(
		pos, barrier_center, current_radius
	)
	var storm_damage: float = 0.0
	if not is_safe:
		storm_damage = EnvironmentalHazardModel.calculate_firmament_barrier_damage(
			pos, barrier_center, current_radius, delta
		)
		result["in_storm"] = true

	# 2. Frostbite check
	var has_thermal: bool = (
		player.inventory != null and player.inventory.has_item("thermal_insulation", 1)
	)
	var in_shelter: bool = player.carrier_peer_id > 0  # Inside carrier/vehicle
	var ambient_temp: float = weather.temperature_c if weather != null else 15.0
	var frostbite_damage: float = EnvironmentalHazardModel.calculate_frostbite_damage(
		ambient_temp, has_thermal, in_shelter, delta
	)
	if frostbite_damage > 0.0:
		result["frostbite"] = true

	# 3. Wind push check
	var wind_vel: Vector3 = weather.wind_velocity if weather != null else Vector3.ZERO
	var exposure: float = 0.2 if in_shelter else 1.0
	var push_f: Vector3 = EnvironmentalHazardModel.calculate_wind_push_force(wind_vel, exposure)
	result["push_vector"] = push_f

	var total_damage: float = storm_damage + frostbite_damage
	result["damage"] = total_damage

	if total_damage > 0.0:
		player.apply_damage(total_damage, 0)

	return result
