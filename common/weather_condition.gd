class_name WeatherCondition
extends RefCounted

enum PrecipitationType {
	NONE,
	RAIN,
	SNOW,
	STORM,
	BLIZZARD,
	FOG,
}

var temperature_c: float = 15.0
var humidity: float = 0.5
var wind_velocity: Vector3 = Vector3.ZERO
var pressure_kpa: float = 101.3
var precipitation_type: int = PrecipitationType.NONE
var precipitation_intensity: float = 0.0
var fog_density: float = 0.0
var visibility_ratio: float = 1.0


static func precipitation_name(type: int) -> String:
	match type:
		PrecipitationType.RAIN:
			return "Rain"
		PrecipitationType.SNOW:
			return "Snow"
		PrecipitationType.STORM:
			return "Storm"
		PrecipitationType.BLIZZARD:
			return "Blizzard"
		PrecipitationType.FOG:
			return "Fog"
		_:
			return "Clear"


func to_dictionary() -> Dictionary:
	return {
		"temperature_c": temperature_c,
		"humidity": humidity,
		"wind_x": wind_velocity.x,
		"wind_y": wind_velocity.y,
		"wind_z": wind_velocity.z,
		"pressure_kpa": pressure_kpa,
		"precipitation_type": precipitation_type,
		"precipitation_intensity": precipitation_intensity,
		"fog_density": fog_density,
		"visibility_ratio": visibility_ratio,
	}


static func from_dictionary(dict: Dictionary) -> WeatherCondition:
	var cond: WeatherCondition = WeatherCondition.new()
	if dict.has("temperature_c"):
		cond.temperature_c = float(dict["temperature_c"])
	if dict.has("humidity"):
		cond.humidity = float(dict["humidity"])
	if dict.has("wind_x") and dict.has("wind_y") and dict.has("wind_z"):
		cond.wind_velocity = Vector3(
			float(dict["wind_x"]), float(dict["wind_y"]), float(dict["wind_z"])
		)
	if dict.has("pressure_kpa"):
		cond.pressure_kpa = float(dict["pressure_kpa"])
	if dict.has("precipitation_type"):
		cond.precipitation_type = int(dict["precipitation_type"])
	if dict.has("precipitation_intensity"):
		cond.precipitation_intensity = float(dict["precipitation_intensity"])
	if dict.has("fog_density"):
		cond.fog_density = float(dict["fog_density"])
	if dict.has("visibility_ratio"):
		cond.visibility_ratio = float(dict["visibility_ratio"])
	return cond


func duplicate_condition() -> WeatherCondition:
	var copy: WeatherCondition = WeatherCondition.new()
	copy.temperature_c = temperature_c
	copy.humidity = humidity
	copy.wind_velocity = wind_velocity
	copy.pressure_kpa = pressure_kpa
	copy.precipitation_type = precipitation_type
	copy.precipitation_intensity = precipitation_intensity
	copy.fog_density = fog_density
	copy.visibility_ratio = visibility_ratio
	return copy
