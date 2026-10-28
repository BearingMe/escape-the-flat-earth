class_name WeatherController
extends Node3D

const TRANSITION_SPEED: float = 1.5
const RAIN_EMISSION_MAX: int = 400
const SNOW_EMISSION_MAX: int = 300

var _target_camera: Camera3D
var _current_condition: WeatherCondition = WeatherCondition.new()
var _rain_amount: float = 0.0
var _snow_amount: float = 0.0
var _fog_amount: float = 0.0
var _target_rain: float = 0.0
var _target_snow: float = 0.0
var _target_fog: float = 0.0

@onready var _rain_particles: CPUParticles3D = %RainParticles
@onready var _snow_particles: CPUParticles3D = %SnowParticles


func _ready() -> void:
	if is_instance_valid(_rain_particles):
		_rain_particles.emitting = false
		_rain_particles.amount = RAIN_EMISSION_MAX
	if is_instance_valid(_snow_particles):
		_snow_particles.emitting = false
		_snow_particles.amount = SNOW_EMISSION_MAX


func _process(delta: float) -> void:
	if (
		_target_camera == null
		or not is_instance_valid(_target_camera)
		or not _target_camera.current
	):
		_find_active_camera()

	var query_pos: Vector3 = (
		_target_camera.global_position if is_instance_valid(_target_camera) else global_position
	)
	_current_condition = World.get_weather_at(query_pos)

	_update_target_amounts()
	_step_transitions(delta)
	_apply_visuals()

	if is_instance_valid(_target_camera):
		global_position = _target_camera.global_position


func _find_active_camera() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		_target_camera = viewport.get_camera_3d()


func _update_target_amounts() -> void:
	_target_rain = 0.0
	_target_snow = 0.0
	_target_fog = _current_condition.fog_density

	match _current_condition.precipitation_type:
		WeatherCondition.PrecipitationType.RAIN:
			_target_rain = _current_condition.precipitation_intensity
		WeatherCondition.PrecipitationType.STORM:
			_target_rain = clampf(_current_condition.precipitation_intensity * 1.5, 0.0, 1.0)
		WeatherCondition.PrecipitationType.SNOW:
			_target_snow = _current_condition.precipitation_intensity
		WeatherCondition.PrecipitationType.BLIZZARD:
			_target_snow = clampf(_current_condition.precipitation_intensity * 1.5, 0.0, 1.0)
		WeatherCondition.PrecipitationType.FOG:
			_target_fog = maxf(_target_fog, _current_condition.precipitation_intensity * 0.08)


func _step_transitions(delta: float) -> void:
	var blend: float = clampf(delta * TRANSITION_SPEED, 0.0, 1.0)
	_rain_amount = lerpf(_rain_amount, _target_rain, blend)
	_snow_amount = lerpf(_snow_amount, _target_snow, blend)
	_fog_amount = lerpf(_fog_amount, _target_fog, blend)


func _apply_visuals() -> void:
	if is_instance_valid(_rain_particles):
		if _rain_amount > 0.01:
			_rain_particles.emitting = true
			_rain_particles.amount = maxi(10, int(_rain_amount * RAIN_EMISSION_MAX))
			_rain_particles.initial_velocity_min = 18.0 + _current_condition.wind_velocity.length()
			_rain_particles.initial_velocity_max = 24.0 + _current_condition.wind_velocity.length()
		else:
			_rain_particles.emitting = false

	if is_instance_valid(_snow_particles):
		if _snow_amount > 0.01:
			_snow_particles.emitting = true
			_snow_particles.amount = maxi(10, int(_snow_amount * SNOW_EMISSION_MAX))
			_snow_particles.initial_velocity_min = (
				2.0 + _current_condition.wind_velocity.length() * 0.3
			)
			_snow_particles.initial_velocity_max = (
				5.0 + _current_condition.wind_velocity.length() * 0.5
			)
		else:
			_snow_particles.emitting = false


func get_current_condition() -> WeatherCondition:
	return _current_condition.duplicate_condition()


func get_transition_state() -> Dictionary:
	return {
		"rain_amount": _rain_amount,
		"snow_amount": _snow_amount,
		"fog_amount": _fog_amount,
		"target_rain": _target_rain,
		"target_snow": _target_snow,
	}
