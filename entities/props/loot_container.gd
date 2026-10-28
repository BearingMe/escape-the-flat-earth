class_name LootContainer
extends StaticBody3D

signal container_opened(peer_id: int)
signal container_closed(peer_id: int)

@export var slot_count: int = 16
@export var max_weight_kg: float = 150.0

var inventory: InventoryContainer
var _active_users: Dictionary = {}


func _ready() -> void:
	inventory = InventoryContainer.new(slot_count, max_weight_kg)


func seed_loot(world_pos: Vector3, disk_radius_m: float, rolls: Array[float]) -> void:
	if inventory == null:
		inventory = InventoryContainer.new(slot_count, max_weight_kg)
	for r: float in rolls:
		var drop: Dictionary = SalvageDistribution.sample_loot_at(world_pos, disk_radius_m, r)
		inventory.add_item(drop["item_id"], int(drop["count"]))


func transfer_to_player(from_container_slot: int, player: ObserverPlayer, count: int) -> bool:
	if player == null or player.inventory == null or inventory == null:
		return false
	return inventory.transfer_slot_to(from_container_slot, player.inventory, count)


func transfer_from_player(from_player_slot: int, player: ObserverPlayer, count: int) -> bool:
	if player == null or player.inventory == null or inventory == null:
		return false
	return player.inventory.transfer_slot_to(from_player_slot, inventory, count)


func open_container(peer_id: int) -> void:
	_active_users[peer_id] = true
	container_opened.emit(peer_id)


func close_container(peer_id: int) -> void:
	_active_users.erase(peer_id)
	container_closed.emit(peer_id)


func is_user_active(peer_id: int) -> bool:
	return _active_users.has(peer_id)
