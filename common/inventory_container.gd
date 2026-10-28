class_name InventoryContainer
extends RefCounted

signal inventory_changed

var slot_count: int = 12
var max_weight_kg: float = 60.0
var _slots: Array[Dictionary] = []


func _init(slots_num: int = 12, max_weight: float = 60.0) -> void:
	slot_count = maxi(1, slots_num)
	max_weight_kg = maxf(1.0, max_weight)
	_slots.resize(slot_count)
	for i: int in range(slot_count):
		_slots[i] = _empty_slot()


func _empty_slot() -> Dictionary:
	return {
		"item_id": "",
		"count": 0,
		"max_stack": 50,
		"unit_weight_kg": 0.5,
		"metadata": {},
	}


func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= slot_count:
		return _empty_slot()
	return _slots[index].duplicate(true)


func is_slot_empty(index: int) -> bool:
	if index < 0 or index >= slot_count:
		return true
	return _slots[index]["item_id"].is_empty() or _slots[index]["count"] <= 0


func add_item(
	item_id: String,
	count: int,
	max_stack: int = 50,
	unit_weight: float = 0.5,
	metadata: Dictionary = {}
) -> int:
	if item_id.is_empty() or count <= 0:
		return count
	var remaining: int = count

	# 1. Fill existing matching stacks
	for i: int in range(slot_count):
		var slot: Dictionary = _slots[i]
		if slot["item_id"] == item_id and slot["count"] < slot["max_stack"]:
			var space: int = slot["max_stack"] - slot["count"]
			var to_add: int = mini(space, remaining)
			slot["count"] += to_add
			remaining -= to_add
			if remaining <= 0:
				inventory_changed.emit()
				return 0

	# 2. Fill empty slots
	for i: int in range(slot_count):
		if is_slot_empty(i):
			var to_add: int = mini(max_stack, remaining)
			_slots[i] = {
				"item_id": item_id,
				"count": to_add,
				"max_stack": max_stack,
				"unit_weight_kg": unit_weight,
				"metadata": metadata.duplicate(true),
			}
			remaining -= to_add
			if remaining <= 0:
				inventory_changed.emit()
				return 0

	inventory_changed.emit()
	return remaining


func remove_from_slot(slot_index: int, count: int) -> int:
	if slot_index < 0 or slot_index >= slot_count or count <= 0:
		return 0
	if is_slot_empty(slot_index):
		return 0

	var slot: Dictionary = _slots[slot_index]
	var to_remove: int = mini(slot["count"], count)
	slot["count"] -= to_remove
	if slot["count"] <= 0:
		_slots[slot_index] = _empty_slot()
	inventory_changed.emit()
	return to_remove


func remove_item_by_id(item_id: String, count: int) -> int:
	if item_id.is_empty() or count <= 0:
		return 0
	var removed_total: int = 0
	var needed: int = count

	for i: int in range(slot_count):
		var slot: Dictionary = _slots[i]
		if slot["item_id"] == item_id and slot["count"] > 0:
			var taking: int = mini(slot["count"], needed)
			slot["count"] -= taking
			needed -= taking
			removed_total += taking
			if slot["count"] <= 0:
				_slots[i] = _empty_slot()
			if needed <= 0:
				break

	if removed_total > 0:
		inventory_changed.emit()
	return removed_total


func transfer_slot_to(from_slot: int, target_inv: InventoryContainer, count: int) -> bool:
	if target_inv == null or from_slot < 0 or from_slot >= slot_count:
		return false
	if is_slot_empty(from_slot):
		return false

	var slot: Dictionary = _slots[from_slot]
	var desired_count: int = mini(slot["count"], count)
	var remainder: int = target_inv.add_item(
		slot["item_id"], desired_count, slot["max_stack"], slot["unit_weight_kg"], slot["metadata"]
	)
	var actual_moved: int = desired_count - remainder
	if actual_moved > 0:
		slot["count"] -= actual_moved
		if slot["count"] <= 0:
			_slots[from_slot] = _empty_slot()
		inventory_changed.emit()
		return true
	return false


func swap_slots(slot_a: int, slot_b: int) -> bool:
	if slot_a < 0 or slot_a >= slot_count or slot_b < 0 or slot_b >= slot_count:
		return false
	if slot_a == slot_b:
		return true
	var temp: Dictionary = _slots[slot_a]
	_slots[slot_a] = _slots[slot_b]
	_slots[slot_b] = temp
	inventory_changed.emit()
	return true


func get_item_count(item_id: String) -> int:
	var total: int = 0
	for slot: Dictionary in _slots:
		if slot["item_id"] == item_id:
			total += int(slot["count"])
	return total


func has_item(item_id: String, required: int) -> bool:
	return get_item_count(item_id) >= required


func get_total_weight() -> float:
	var total: float = 0.0
	for slot: Dictionary in _slots:
		if not slot["item_id"].is_empty():
			total += float(slot["count"]) * float(slot["unit_weight_kg"])
	return total


func to_dictionary() -> Dictionary:
	return {
		"slot_count": slot_count,
		"max_weight_kg": max_weight_kg,
		"slots": _slots.duplicate(true),
	}


func from_dictionary(dict: Dictionary) -> void:
	if dict.has("slot_count"):
		slot_count = int(dict["slot_count"])
	if dict.has("max_weight_kg"):
		max_weight_kg = float(dict["max_weight_kg"])
	_slots.resize(slot_count)
	var saved_slots: Variant = dict.get("slots", [])
	if saved_slots is Array:
		for i: int in range(slot_count):
			if i < saved_slots.size() and saved_slots[i] is Dictionary:
				_slots[i] = saved_slots[i].duplicate(true)
			else:
				_slots[i] = _empty_slot()
	inventory_changed.emit()
