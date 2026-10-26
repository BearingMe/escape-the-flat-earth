extends Node

var _field: DiskGravityField = DiskGravityField.new()


func _ready() -> void:
	var result: Error = configure(World.config)
	if result != OK:
		Log.error("gravity.configure_failed", {"error": result})


func configure(config: WorldConfig) -> Error:
	return _field.configure(config)


func gravity_at(position: Vector3) -> Vector3:
	return _field.gravity_at(position)
