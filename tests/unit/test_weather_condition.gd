extends GutTest


func test_weather_condition_defaults() -> void:
	var cond: WeatherCondition = WeatherCondition.new()
	assert_almost_eq(cond.temperature_c, 15.0, 0.01)
	assert_almost_eq(cond.humidity, 0.5, 0.01)
	assert_eq(cond.precipitation_type, WeatherCondition.PrecipitationType.NONE)
	assert_almost_eq(cond.visibility_ratio, 1.0, 0.01)


func test_weather_condition_serialization() -> void:
	var cond: WeatherCondition = WeatherCondition.new()
	cond.temperature_c = -12.5
	cond.humidity = 0.85
	cond.wind_velocity = Vector3(10.0, 1.0, -5.0)
	cond.pressure_kpa = 94.2
	cond.precipitation_type = WeatherCondition.PrecipitationType.BLIZZARD
	cond.precipitation_intensity = 0.9
	cond.fog_density = 0.05
	cond.visibility_ratio = 0.2

	var dict: Dictionary = cond.to_dictionary()
	var restored: WeatherCondition = WeatherCondition.from_dictionary(dict)

	assert_almost_eq(restored.temperature_c, -12.5, 0.01)
	assert_almost_eq(restored.humidity, 0.85, 0.01)
	assert_almost_eq(restored.wind_velocity.x, 10.0, 0.01)
	assert_almost_eq(restored.wind_velocity.y, 1.0, 0.01)
	assert_almost_eq(restored.wind_velocity.z, -5.0, 0.01)
	assert_almost_eq(restored.pressure_kpa, 94.2, 0.01)
	assert_eq(restored.precipitation_type, WeatherCondition.PrecipitationType.BLIZZARD)
	assert_almost_eq(restored.precipitation_intensity, 0.9, 0.01)
	assert_almost_eq(restored.fog_density, 0.05, 0.01)
	assert_almost_eq(restored.visibility_ratio, 0.2, 0.01)


func test_precipitation_names() -> void:
	assert_eq(WeatherCondition.precipitation_name(WeatherCondition.PrecipitationType.NONE), "Clear")
	assert_eq(WeatherCondition.precipitation_name(WeatherCondition.PrecipitationType.RAIN), "Rain")
	assert_eq(WeatherCondition.precipitation_name(WeatherCondition.PrecipitationType.SNOW), "Snow")
	assert_eq(
		WeatherCondition.precipitation_name(WeatherCondition.PrecipitationType.STORM), "Storm"
	)
	assert_eq(
		WeatherCondition.precipitation_name(WeatherCondition.PrecipitationType.BLIZZARD), "Blizzard"
	)
	assert_eq(WeatherCondition.precipitation_name(WeatherCondition.PrecipitationType.FOG), "Fog")
