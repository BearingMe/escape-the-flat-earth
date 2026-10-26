extends StaticBody3D

var _configured_geometry_signature: String = ""

@onready var _collision: CollisionShape3D = %CollisionShape3D
@onready var _top_surface: MeshInstance3D = %TopSurface
@onready var _underside_surface: MeshInstance3D = %UndersideSurface
@onready var _rim_surface: MeshInstance3D = %RimSurface


func _ready() -> void:
	add_to_group("world_disks")
	_top_surface.material_override = _surface_material(Color("#557b42"))
	_underside_surface.material_override = _surface_material(Color("#43566b"))
	_rim_surface.material_override = _surface_material(Color("#c7e5ed"))
	var result: Error = configure(World.config)
	if result != OK:
		Log.error("world.disk_configuration_failed", {"error": result})


func configure(config: WorldConfig) -> Error:
	if config == null or config.validate() != OK:
		return ERR_INVALID_PARAMETER
	if (
		_collision == null
		or _top_surface == null
		or _underside_surface == null
		or _rim_surface == null
	):
		return ERR_UNCONFIGURED
	var geometry_signature: String = "%s|%s" % [config.disk_radius_m, config.disk_thickness_m]
	if geometry_signature == _configured_geometry_signature and _collision.shape != null:
		return OK
	var half_thickness: float = config.disk_thickness_m * 0.5
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = config.disk_radius_m
	shape.height = config.disk_thickness_m
	_collision.shape = shape
	_configure_cylinder(_top_surface, config.disk_radius_m, minf(1.0, config.disk_thickness_m))
	_top_surface.position.y = half_thickness - minf(0.5, half_thickness)
	_configure_cylinder(
		_underside_surface, config.disk_radius_m, minf(1.0, config.disk_thickness_m)
	)
	_underside_surface.position.y = -half_thickness + minf(0.5, half_thickness)
	_configure_cylinder(_rim_surface, config.disk_radius_m, config.disk_thickness_m)
	_rim_surface.position.y = 0.0
	_configured_geometry_signature = geometry_signature
	return OK


func _configure_cylinder(instance: MeshInstance3D, radius: float, height: float) -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 96
	instance.mesh = mesh


func _surface_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
