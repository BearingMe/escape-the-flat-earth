class_name EnemyEntity
extends CharacterBody3D

signal enemy_defeated(archetype_id: int, killer_peer_id: int)
signal attack_executed(target: Node, damage: float)

enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEFEATED,
}

@export var archetype: EnemyArchetypeDefinition

var health: float = 80.0
var current_state: int = State.IDLE
var target_player: ObserverPlayer = null
var attack_cooldown_timer: float = 0.0
var last_attacker_peer_id: int = 0


func _ready() -> void:
	if archetype != null:
		health = archetype.max_health


func apply_damage(amount: float, dealer_peer_id: int) -> void:
	if amount <= 0.0 or current_state == State.DEFEATED:
		return
	health = maxf(health - amount, 0.0)
	last_attacker_peer_id = dealer_peer_id

	if health <= 0.0:
		current_state = State.DEFEATED
		enemy_defeated.emit(archetype.archetype_id if archetype != null else 0, dealer_peer_id)
		_spawn_loot_drop()
		queue_free()
		return

	# If idling and struck, agro onto attacker
	if target_player == null and dealer_peer_id > 0:
		var parent_node: Node = get_parent()
		if parent_node != null:
			target_player = (
				parent_node.get_node_or_null("Player_%d" % dealer_peer_id) as ObserverPlayer
			)


func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	if current_state == State.DEFEATED or archetype == null:
		return

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	_update_perception()
	_update_state_machine(delta)


func _update_perception() -> void:
	if target_player != null and is_instance_valid(target_player) and target_player.is_alive:
		var dist_sq: float = global_position.distance_squared_to(target_player.global_position)
		if dist_sq <= (archetype.perception_radius_m * archetype.perception_radius_m * 1.5):
			return

	target_player = null
	var players: Array[Node] = get_tree().get_nodes_in_group("network_players")
	var nearest_dist_sq: float = archetype.perception_radius_m * archetype.perception_radius_m
	for node: Node in players:
		var p: ObserverPlayer = node as ObserverPlayer
		if p != null and is_instance_valid(p) and p.is_alive:
			var d_sq: float = global_position.distance_squared_to(p.global_position)
			if d_sq <= nearest_dist_sq:
				nearest_dist_sq = d_sq
				target_player = p


func _update_state_machine(delta: float) -> void:
	if target_player == null:
		current_state = State.IDLE
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		move_and_slide()
		return

	var in_attack_range: bool = AISteeringModel.is_target_in_range(
		global_position, target_player.global_position, archetype.attack_range_m
	)

	if in_attack_range:
		current_state = State.ATTACK
		velocity.x = 0.0
		velocity.z = 0.0
		_execute_attack()
	else:
		current_state = State.CHASE
		var pursuit: Vector3 = AISteeringModel.calculate_pursuit_velocity(
			global_position, target_player.global_position, archetype.movement_speed_m_s
		)
		velocity.x = pursuit.x
		velocity.z = pursuit.z

	var gravity_m_s2: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	if not is_on_floor():
		velocity.y = maxf(velocity.y - gravity_m_s2 * delta, -50.0)
	else:
		velocity.y = 0.0

	move_and_slide()


func _execute_attack() -> void:
	if attack_cooldown_timer > 0.0 or target_player == null or not is_instance_valid(target_player):
		return
	attack_cooldown_timer = archetype.attack_cooldown_sec
	attack_executed.emit(target_player, archetype.damage)

	match archetype.archetype_id:
		EnemyArchetypeDefinition.ArchetypeId.GEODETIC_DRONE:
			target_player.apply_damage(archetype.damage, 0)
			var knock_dir: Vector3 = (target_player.global_position - global_position).normalized()
			target_player.knockdown_host(knock_dir * 12.0 + Vector3(0, 3, 0))
		EnemyArchetypeDefinition.ArchetypeId.ICE_SENTINEL:
			target_player.apply_damage(archetype.damage, 0)
			target_player.knockdown_host(Vector3(0, 4, 0))
		EnemyArchetypeDefinition.ArchetypeId.VOID_SWARMER:
			target_player.apply_damage(archetype.damage, 0)
			if target_player.survival != null:
				target_player.survival.stamina = maxf(target_player.survival.stamina - 30.0, 0.0)
		EnemyArchetypeDefinition.ArchetypeId.PATROL_ROVER:
			target_player.apply_damage(archetype.damage, 0)
			var push: Vector3 = (
				(target_player.global_position - global_position).normalized() * 15.0
			)
			target_player.velocity += push
		EnemyArchetypeDefinition.ArchetypeId.MAGNETIC_ANOMALY:
			target_player.apply_damage(archetype.damage, 0)
			var pull: Vector3 = AISteeringModel.calculate_magnetic_pull(
				target_player.global_position, global_position
			)
			target_player.velocity += pull * 0.05


func _spawn_loot_drop() -> void:
	if archetype == null or archetype.drop_item_id.is_empty():
		return
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	var drop_pos: Vector3 = global_position + Vector3(0.0, 0.5, 0.0)
	var prop: PhysicalProp = (
		preload("res://entities/props/physical_prop.tscn").instantiate() as PhysicalProp
	)
	parent_node.add_child(prop)
	prop.global_position = drop_pos
