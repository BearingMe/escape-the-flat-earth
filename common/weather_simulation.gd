class_name WeatherSimulation
extends RefCounted

const SEA_LEVEL_PRESSURE_KPA: float = 101.325
const SCALE_HEIGHT_M: float = 8400.0
const LAPSE_RATE_C_PER_M: float = 0.0065
const CYCLONIC_SWIRL_RATE: float = 0.003
const FRONT_SPEED: float = 0.012

var _config: WorldConfig
var _seed_value: int = 0
var _sim_time_sec: float = 0.0
var _front_noise: FastNoiseLite
var _gust_noise: FastNoiseLite
var _override_active: bool = false
var _override_type: int = WeatherCondition.PrecipitationType.NONE
var _override_intensity: float = 0.0


func configure(config: WorldConfig, seed_value: int) -> Error:
	if config == null or config.validate() != OK:
		return ERR_INVALID_PARAMETER
	_config = config.duplicate(true) as WorldConfig
	_seed_value = seed_value
	_sim_time_sec = 0.0

	_front_noise = FastNoiseLite.new()
	_front_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_front_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_front_noise.fractal_octaves = 3
	_front_noise.frequency = 0.0003
	_front_noise.seed = seed_value ^ 0x3F89B214

	_gust_noise = FastNoiseLite.new()
	_gust_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_gust_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_gust_noise.fractal_octaves = 2
	_gust_noise.frequency = 0.001
	_gust_noise.seed = seed_value ^ 0x7E12D567

	return OK


func advance_time(delta_sec: float) -> void:
	if delta_sec > 0.0:
		_sim_time_sec += delta_sec


func set_sim_time(time_sec: float) -> void:
	_sim_time_sec = maxf(time_sec, 0.0)


func get_sim_time() -> float:
	return _sim_time_sec


func force_weather(type: int, intensity: float) -> void:
	_override_active = true
	_override_type = clampi(
		type, WeatherCondition.PrecipitationType.NONE, WeatherCondition.PrecipitationType.FOG
	)
	_override_intensity = clampf(intensity, 0.0, 1.0)


func clear_override() -> void:
	_override_active = false
	_override_type = WeatherCondition.PrecipitationType.NONE
	_override_intensity = 0.0


func is_override_active() -> bool:
	return _override_active


func get_sync_state() -> Dictionary:
	return {
		"sim_time_sec": _sim_time_sec,
		"override_active": _override_active,
		"override_type": _override_type,
		"override_intensity": _override_intensity,
	}


func apply_sync_state(dict: Dictionary) -> void:
	if dict.has("sim_time_sec"):
		_sim_time_sec = float(dict["sim_time_sec"])
	if dict.has("override_active"):
		_override_active = bool(dict["override_active"])
	if dict.has("override_type"):
		_override_type = int(dict["override_type"])
	if dict.has("override_intensity"):
		_override_intensity = float(dict["override_intensity"])


func sample_weather(world_pos: Vector3, biome_id: int) -> WeatherCondition:
	var cond: WeatherCondition = WeatherCondition.new()
	if _config == null or not world_pos.is_finite():
		return cond

	var surface_y: float = _config.disk_thickness_m * 0.5
	var rel_altitude_m: float = world_pos.y - surface_y

	# 1. Barometric Pressure
	if rel_altitude_m >= 0.0:
		cond.pressure_kpa = SEA_LEVEL_PRESSURE_KPA * exp(-rel_altitude_m / SCALE_HEIGHT_M)
	else:
		# Below disk surface towards abyss
		cond.pressure_kpa = (
			SEA_LEVEL_PRESSURE_KPA * clampf(1.0 + rel_altitude_m / 1000.0, 0.05, 1.0)
		)

	# 2. Biome Base Climatology
	var base_temp: float = 18.0
	var base_humidity: float = 0.45
	var base_wind_speed: float = 4.0

	match biome_id:
		TerrainBiomeDefinition.Id.PLAINS:
			base_temp = 19.0
			base_humidity = 0.45
			base_wind_speed = 4.0
		TerrainBiomeDefinition.Id.FOREST:
			base_temp = 16.0
			base_humidity = 0.72
			base_wind_speed = 2.5
		TerrainBiomeDefinition.Id.MOUNTAINS:
			base_temp = 5.0
			base_humidity = 0.50
			base_wind_speed = 12.0
		TerrainBiomeDefinition.Id.TUNDRA:
			base_temp = -9.0
			base_humidity = 0.35
			base_wind_speed = 9.0
		TerrainBiomeDefinition.Id.ICE_WALL:
			base_temp = -26.0
			base_humidity = 0.40
			base_wind_speed = 17.0

	# 3. Temperature with Elevation Lapse Rate
	var lapse_temp_drop: float = rel_altitude_m * LAPSE_RATE_C_PER_M
	cond.temperature_c = base_temp - lapse_temp_drop

	# 4. Front Wave & Humidity
	var norm_pos: Vector2 = Vector2(
		world_pos.x / _config.disk_radius_m, world_pos.z / _config.disk_radius_m
	)
	var radius_ratio: float = norm_pos.length()
	var angle: float = atan2(norm_pos.y, norm_pos.x)

	var synoptic_time: float = _sim_time_sec * FRONT_SPEED
	var front_noise_val: float = 0.0
	if _front_noise != null:
		front_noise_val = _front_noise.get_noise_2d(
			world_pos.x + _sim_time_sec * 3.0, world_pos.z + _sim_time_sec * 1.5
		)

	var wave_phase: float = angle * 2.0 + radius_ratio * 3.5 - synoptic_time
	var front_activity: float = (sin(wave_phase) * 0.4 + front_noise_val * 0.6 + 1.0) * 0.5
	cond.humidity = clampf(base_humidity + (front_activity - 0.5) * 0.4, 0.05, 1.0)

	# 5. Wind Vector (Cyclonic circulation around Pole + Gusts)
	var swirl_tangent: Vector2 = Vector2(-norm_pos.y, norm_pos.x).normalized()
	var gust_val: float = 0.0
	if _gust_noise != null:
		gust_val = _gust_noise.get_noise_2d(
			world_pos.x * 2.0 + _sim_time_sec * 8.0, world_pos.z * 2.0
		)

	var total_wind_speed: float = base_wind_speed + (front_activity * 8.0) + (gust_val * 6.0)
	total_wind_speed = maxf(total_wind_speed, 0.5)

	var wind_2d: Vector2 = (swirl_tangent * 0.8 + norm_pos * 0.2).normalized() * total_wind_speed
	cond.wind_velocity = Vector3(wind_2d.x, gust_val * 0.5, wind_2d.y)

	# 6. Precipitation & Visibility
	if _override_active:
		cond.precipitation_type = _override_type
		cond.precipitation_intensity = _override_intensity
		if _override_type == WeatherCondition.PrecipitationType.FOG:
			cond.fog_density = _override_intensity * 0.08
			cond.visibility_ratio = 1.0 - _override_intensity * 0.75
		elif _override_type == WeatherCondition.PrecipitationType.BLIZZARD:
			cond.fog_density = _override_intensity * 0.06
			cond.visibility_ratio = 1.0 - _override_intensity * 0.85
		elif _override_type == WeatherCondition.PrecipitationType.STORM:
			cond.fog_density = _override_intensity * 0.04
			cond.visibility_ratio = 1.0 - _override_intensity * 0.65
		elif _override_type == WeatherCondition.PrecipitationType.RAIN:
			cond.visibility_ratio = 1.0 - _override_intensity * 0.35
		elif _override_type == WeatherCondition.PrecipitationType.SNOW:
			cond.visibility_ratio = 1.0 - _override_intensity * 0.45
		else:
			cond.visibility_ratio = 1.0
		return cond

	if front_activity > 0.55:
		cond.precipitation_intensity = clampf((front_activity - 0.55) / 0.45, 0.0, 1.0)
		if cond.temperature_c <= 0.0:
			if total_wind_speed > 13.0:
				cond.precipitation_type = WeatherCondition.PrecipitationType.BLIZZARD
				cond.fog_density = cond.precipitation_intensity * 0.05
				cond.visibility_ratio = 1.0 - cond.precipitation_intensity * 0.85
			else:
				cond.precipitation_type = WeatherCondition.PrecipitationType.SNOW
				cond.visibility_ratio = 1.0 - cond.precipitation_intensity * 0.45
		else:
			if total_wind_speed > 13.0:
				cond.precipitation_type = WeatherCondition.PrecipitationType.STORM
				cond.fog_density = cond.precipitation_intensity * 0.03
				cond.visibility_ratio = 1.0 - cond.precipitation_intensity * 0.65
			else:
				cond.precipitation_type = WeatherCondition.PrecipitationType.RAIN
				cond.visibility_ratio = 1.0 - cond.precipitation_intensity * 0.35
	elif cond.humidity > 0.85 and total_wind_speed < 5.0:
		cond.precipitation_type = WeatherCondition.PrecipitationType.FOG
		cond.precipitation_intensity = (cond.humidity - 0.85) / 0.15
		cond.fog_density = cond.precipitation_intensity * 0.06
		cond.visibility_ratio = 1.0 - cond.precipitation_intensity * 0.70
	else:
		cond.precipitation_type = WeatherCondition.PrecipitationType.NONE
		cond.precipitation_intensity = 0.0
		cond.fog_density = 0.0
		cond.visibility_ratio = 1.0

	return cond
