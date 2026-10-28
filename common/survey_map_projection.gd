class_name SurveyMapProjection
extends RefCounted

enum TraversalZone {
	INTERIOR,
	TUNDRA,
	ICE_WALL,
	ABYSS,
	UNDERSIDE,
}

enum RotationMode {
	NORTH_UP,
	HEADING_UP,
}

enum ZoomLevel {
	LOCAL_NEAR,
	LOCAL_FAR,
	FULL_DISK,
}

const ZOOM_RADII_M: Dictionary = {
	ZoomLevel.LOCAL_NEAR: 500.0,
	ZoomLevel.LOCAL_FAR: 1500.0,
	ZoomLevel.FULL_DISK: 5000.0,
}

const TUNDRA_RATIO: float = 0.66
const ICE_WALL_RATIO: float = 0.91


static func world_to_normalized_disk(world_position: Vector3, disk_radius_m: float) -> Vector2:
	if not is_finite(disk_radius_m) or disk_radius_m <= 0.0:
		return Vector2.ZERO
	if not world_position.is_finite():
		return Vector2.ZERO
	return Vector2(world_position.x / disk_radius_m, world_position.z / disk_radius_m)


static func normalized_disk_to_world(
	disk_coords: Vector2, disk_radius_m: float, elevation_y: float = 0.0
) -> Vector3:
	if not is_finite(disk_radius_m) or disk_radius_m <= 0.0:
		return Vector3.ZERO
	if not disk_coords.is_finite():
		return Vector3.ZERO
	return Vector3(disk_coords.x * disk_radius_m, elevation_y, disk_coords.y * disk_radius_m)


static func yaw_to_heading_degrees(yaw: float) -> float:
	if not is_finite(yaw):
		return 0.0
	var degrees: float = rad_to_deg(-yaw)
	return fposmod(degrees, 360.0)


static func heading_degrees_to_cardinal(heading_deg: float) -> String:
	var normalized: float = fposmod(heading_deg, 360.0)
	if normalized >= 337.5 or normalized < 22.5:
		return "N"
	if normalized < 67.5:
		return "NE"
	if normalized < 112.5:
		return "E"
	if normalized < 157.5:
		return "SE"
	if normalized < 202.5:
		return "S"
	if normalized < 247.5:
		return "SW"
	if normalized < 292.5:
		return "W"
	return "NW"


static func evaluate_traversal_zone(world_position: Vector3, config: WorldConfig) -> Dictionary:
	if config == null or config.validate() != OK or not world_position.is_finite():
		return {
			"zone": TraversalZone.INTERIOR,
			"radial_distance_m": 0.0,
			"radial_ratio": 0.0,
			"altitude_m": 0.0,
			"distance_to_rim_m": 0.0,
			"is_off_disk": false,
			"is_underside": false,
			"zone_name": "Interior",
		}

	var radial_distance_m: float = Vector2(world_position.x, world_position.z).length()
	var radial_ratio: float = radial_distance_m / config.disk_radius_m
	var surface_y: float = config.disk_thickness_m * 0.5
	var underside_y: float = -surface_y
	var is_underside: bool = world_position.y < underside_y
	var is_off_disk: bool = radial_distance_m > config.disk_radius_m
	var distance_to_rim_m: float = config.disk_radius_m - radial_distance_m

	var zone: int = TraversalZone.INTERIOR
	var zone_name: String = "Interior"

	if is_underside:
		zone = TraversalZone.UNDERSIDE
		zone_name = "Underside"
	elif is_off_disk:
		zone = TraversalZone.ABYSS
		zone_name = "Abyss Void"
	elif radial_ratio >= ICE_WALL_RATIO:
		zone = TraversalZone.ICE_WALL
		zone_name = "Ice Wall Rim"
	elif radial_ratio >= TUNDRA_RATIO:
		zone = TraversalZone.TUNDRA
		zone_name = "Outer Tundra"
	else:
		zone = TraversalZone.INTERIOR
		zone_name = "Habitable Basin"

	return {
		"zone": zone,
		"radial_distance_m": radial_distance_m,
		"radial_ratio": radial_ratio,
		"altitude_m": world_position.y,
		"distance_to_rim_m": distance_to_rim_m,
		"is_off_disk": is_off_disk,
		"is_underside": is_underside,
		"zone_name": zone_name,
	}


static func world_to_map_point(
	world_position: Vector3,
	center_position: Vector3,
	view_radius_m: float,
	map_size_px: Vector2,
	rotation_mode: int,
	observer_yaw: float
) -> Vector2:
	if not world_position.is_finite() or not center_position.is_finite():
		return map_size_px * 0.5
	if view_radius_m <= 0.0 or map_size_px.x <= 0.0 or map_size_px.y <= 0.0:
		return map_size_px * 0.5

	var delta_world: Vector2 = Vector2(
		world_position.x - center_position.x, world_position.z - center_position.z
	)

	var effective_delta: Vector2 = delta_world
	if rotation_mode == RotationMode.HEADING_UP:
		effective_delta = delta_world.rotated(observer_yaw)

	var half_size: Vector2 = map_size_px * 0.5
	var scale_factor: float = half_size.x / view_radius_m

	var map_offset: Vector2 = effective_delta * scale_factor
	return half_size + map_offset


static func is_within_map_radius(point: Vector2, map_center: Vector2, radius_px: float) -> bool:
	return point.distance_squared_to(map_center) <= radius_px * radius_px
