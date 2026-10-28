extends GutTest

const WEATHER_CONTROLLER_SCENE: PackedScene = preload(
	"res://entities/world/weather_controller.tscn"
)

var _controller: WeatherController


func before_each() -> void:
	World.set_seed(17320508)
	_controller = WEATHER_CONTROLLER_SCENE.instantiate() as WeatherController
	add_child_autofree(_controller)


func test_clear_weather_particles_not_emitting() -> void:
	World.force_weather(WeatherCondition.PrecipitationType.NONE, 0.0)
	# Process multiple frames to settle transition
	for i: int in range(15):
		_controller._process(0.1)

	var transition: Dictionary = _controller.get_transition_state()
	assert_almost_eq(float(transition["rain_amount"]), 0.0, 0.05)
	assert_almost_eq(float(transition["snow_amount"]), 0.0, 0.05)
	assert_false(_controller._rain_particles.emitting)
	assert_false(_controller._snow_particles.emitting)


func test_rain_weather_smooth_transition() -> void:
	World.force_weather(WeatherCondition.PrecipitationType.RAIN, 0.8)

	for i: int in range(15):
		_controller._process(0.1)

	var transition: Dictionary = _controller.get_transition_state()
	assert_gt(float(transition["rain_amount"]), 0.5)
	assert_almost_eq(float(transition["snow_amount"]), 0.0, 0.05)
	assert_true(_controller._rain_particles.emitting)
	assert_false(_controller._snow_particles.emitting)


func test_snow_weather_smooth_transition() -> void:
	World.force_weather(WeatherCondition.PrecipitationType.SNOW, 0.7)

	for i: int in range(15):
		_controller._process(0.1)

	var transition: Dictionary = _controller.get_transition_state()
	assert_gt(float(transition["snow_amount"]), 0.5)
	assert_almost_eq(float(transition["rain_amount"]), 0.0, 0.05)
	assert_true(_controller._snow_particles.emitting)
	assert_false(_controller._rain_particles.emitting)


func after_each() -> void:
	World.clear_weather_override()
