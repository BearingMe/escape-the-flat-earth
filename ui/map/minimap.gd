class_name MinimapHUD
extends CanvasLayer

const BEZEL_COLOR: Color = Color(0.72, 0.58, 0.28, 1.0)
const BEZEL_BG_COLOR: Color = Color(0.08, 0.1, 0.12, 0.85)
const GRID_COLOR: Color = Color(0.35, 0.45, 0.55, 0.4)
const TEXT_GOLD: Color = Color(0.9, 0.8, 0.4, 1.0)
const TEXT_DANGER: Color = Color(1.0, 0.35, 0.3, 1.0)
const TEXT_MUTED: Color = Color(0.65, 0.7, 0.75, 1.0)
const PLAYER_COLOR: Color = Color(1.0, 0.85, 0.2, 1.0)
const TEAMMATE_COLORS: Array[Color] = [
	Color(0.2, 0.8, 1.0, 1.0),
	Color(0.4, 1.0, 0.4, 1.0),
	Color(1.0, 0.4, 0.9, 1.0),
	Color(1.0, 0.6, 0.2, 1.0),
	Color(0.7, 0.5, 1.0, 1.0),
]

@export var map_radius_px: float = 90.0
@export var current_zoom: int = SurveyMapProjection.ZoomLevel.LOCAL_NEAR
@export var rotation_mode: int = SurveyMapProjection.RotationMode.HEADING_UP

var _config: WorldConfig
var _raster: SurveyMapRaster
var _chart_texture: ImageTexture
var _target_player: Node3D
var _teammates: Dictionary = {}
var _fullscreen_active: bool = false
var _cached_telemetry: Dictionary = {}

@onready var _minimap_panel: Control = %MinimapPanel
@onready var _fullscreen_panel: Control = %FullscreenPanel
@onready var _telemetry_label: Label = %TelemetryLabel
@onready var _fullscreen_chart_rect: TextureRect = %FullscreenChartRect
@onready var _fullscreen_telemetry_label: Label = %FullscreenTelemetryLabel


func _ready() -> void:
	if _config == null:
		_config = World.config
	if _raster == null and _config != null:
		configure_world(_config, _config.world_seed)
	if is_instance_valid(_minimap_panel):
		_minimap_panel.draw.connect(func() -> void: draw_minimap(_minimap_panel))
	if is_instance_valid(_fullscreen_panel):
		_fullscreen_panel.visible = false
		_fullscreen_panel.draw.connect(func() -> void: draw_fullscreen_crosshair(_fullscreen_panel))


func configure_world(config: WorldConfig, seed_value: int) -> Error:
	if config == null or config.validate() != OK:
		return ERR_INVALID_PARAMETER
	_config = config.duplicate(true) as WorldConfig
	_raster = SurveyMapRaster.new()
	var config_err: Error = _raster.configure(_config, seed_value, 256)
	if config_err != OK:
		return config_err
	_chart_texture = _raster.get_or_create_texture()
	if is_instance_valid(_fullscreen_chart_rect):
		_fullscreen_chart_rect.texture = _chart_texture
	return OK


func bind_player(player: Node3D) -> void:
	_target_player = player


func register_teammate(peer_id: int, player_name: String, get_position_cb: Callable) -> void:
	if peer_id <= 0 or not get_position_cb.is_valid():
		return
	_teammates[peer_id] = {
		"name": player_name,
		"callable": get_position_cb,
	}


func unregister_teammate(peer_id: int) -> void:
	_teammates.erase(peer_id)


func clear_teammates() -> void:
	_teammates.clear()


func cycle_zoom() -> void:
	match current_zoom:
		SurveyMapProjection.ZoomLevel.LOCAL_NEAR:
			current_zoom = SurveyMapProjection.ZoomLevel.LOCAL_FAR
		SurveyMapProjection.ZoomLevel.LOCAL_FAR:
			current_zoom = SurveyMapProjection.ZoomLevel.FULL_DISK
		_:
			current_zoom = SurveyMapProjection.ZoomLevel.LOCAL_NEAR
	_queue_redraws()


func toggle_rotation_mode() -> void:
	rotation_mode = (
		SurveyMapProjection.RotationMode.NORTH_UP
		if rotation_mode == SurveyMapProjection.RotationMode.HEADING_UP
		else SurveyMapProjection.RotationMode.HEADING_UP
	)
	_queue_redraws()


func toggle_fullscreen_map() -> void:
	_fullscreen_active = not _fullscreen_active
	if is_instance_valid(_fullscreen_panel):
		_fullscreen_panel.visible = _fullscreen_active
	_queue_redraws()


func is_fullscreen_open() -> bool:
	return _fullscreen_active


func get_telemetry() -> Dictionary:
	return _cached_telemetry.duplicate(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			toggle_fullscreen_map()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Z:
			cycle_zoom()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_N:
			toggle_rotation_mode()
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _target_player == null or not is_instance_valid(_target_player):
		_find_local_observer()
	_update_telemetry()
	_queue_redraws()


func _find_local_observer() -> void:
	var local_id: int = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	var players: Array[Node] = get_tree().get_nodes_in_group("network_players")
	for p: Node in players:
		if p is ObserverPlayer and p.peer_id == local_id:
			_target_player = p
			return
	if not players.is_empty() and players[0] is Node3D:
		_target_player = players[0] as Node3D


func _update_telemetry() -> void:
	if _target_player == null or not is_instance_valid(_target_player) or _config == null:
		return
	var pos: Vector3 = _target_player.global_position
	var yaw: float = _target_player.rotation.y
	var heading_deg: float = SurveyMapProjection.yaw_to_heading_degrees(yaw)
	var cardinal: String = SurveyMapProjection.heading_degrees_to_cardinal(heading_deg)
	var zone_info: Dictionary = SurveyMapProjection.evaluate_traversal_zone(pos, _config)

	var biome_name: String = "Plains"
	if _raster != null:
		var biome_id: int = _raster.sample_biome_at_world(pos.x, pos.z)
		var b_def: TerrainBiomeDefinition = TerrainBiomeCatalog.get_biome(biome_id)
		if b_def != null:
			biome_name = b_def.display_name

	_cached_telemetry = {
		"position_x": pos.x,
		"position_y": pos.y,
		"position_z": pos.z,
		"heading_deg": heading_deg,
		"cardinal": cardinal,
		"biome_name": biome_name,
		"zone_info": zone_info,
	}

	var status_text: String = ""
	if zone_info["is_off_disk"]:
		status_text = "[! FALLING OFF DISK - ABYSS !]"
	elif zone_info["is_underside"]:
		status_text = "[! TRAVERSING UNDERSIDE !]"
	elif zone_info["zone"] == SurveyMapProjection.TraversalZone.ICE_WALL:
		status_text = "[! ICE WALL PERIMETER !]"

	var text: String = (
		"HEADING: %03d° %s | BIOME: %s\n" % [int(heading_deg), cardinal, biome_name]
		+ "X: %+.0fm | Z: %+.0fm | ALT: %+.1fm\n" % [pos.x, pos.z, pos.y]
		+ (
			"RIM DIST: %.0fm (%s) %s"
			% [
				maxf(zone_info["distance_to_rim_m"], 0.0),
				zone_info["zone_name"],
				status_text,
			]
		)
	)
	if is_instance_valid(_telemetry_label):
		_telemetry_label.text = text
		if zone_info["is_off_disk"] or zone_info["is_underside"]:
			_telemetry_label.modulate = TEXT_DANGER
		else:
			_telemetry_label.modulate = TEXT_GOLD

	if _fullscreen_active and is_instance_valid(_fullscreen_telemetry_label):
		_fullscreen_telemetry_label.text = (
			"OFFICIAL FLAT EARTH SURVEY COMMISSION\n"
			+ "STANDARD AZIMUTHAL SURVEY CHART\n\n"
			+ "SECTOR: %s | ZONE: %s\n" % [biome_name.to_upper(), zone_info["zone_name"].to_upper()]
			+ "COORDINATES: (X: %+.1fm, Z: %+.1fm)\n" % [pos.x, pos.z]
			+ "AZIMUTH: %03.1f° %s | ALTITUDE: %+.1fm\n" % [heading_deg, cardinal, pos.y]
			+ "PERIMETER DISTANCE: %.1fm\n" % zone_info["distance_to_rim_m"]
			+ (status_text if not status_text.is_empty() else "SURFACE INTEGRITY: NOMINAL")
		)


func _queue_redraws() -> void:
	if is_instance_valid(_minimap_panel):
		_minimap_panel.queue_redraw()
	if _fullscreen_active and is_instance_valid(_fullscreen_panel):
		_fullscreen_panel.queue_redraw()


func draw_minimap(control: Control) -> void:
	if _config == null or control == null:
		return
	var center: Vector2 = control.size * 0.5
	var r: float = minf(center.x, center.y) - 6.0

	# 1. Bezel background
	control.draw_circle(center, r + 4.0, BEZEL_COLOR)
	control.draw_circle(center, r, BEZEL_BG_COLOR)

	var player_pos: Vector3 = (
		_target_player.global_position if is_instance_valid(_target_player) else Vector3.ZERO
	)
	var player_yaw: float = _target_player.rotation.y if is_instance_valid(_target_player) else 0.0
	var view_radius_m: float = float(SurveyMapProjection.ZOOM_RADII_M[current_zoom])

	# 2. Render survey chart texture if available
	if _chart_texture != null:
		var tex_size: Vector2 = _chart_texture.get_size()
		# Disk radius in chart texture corresponds to half of tex_size
		var chart_scale: float = (r / view_radius_m) * (_config.disk_radius_m / (tex_size.x * 0.5))
		var chart_center_in_map: Vector2 = center
		if current_zoom != SurveyMapProjection.ZoomLevel.FULL_DISK:
			var offset_world: Vector2 = Vector2(-player_pos.x, -player_pos.z)
			if rotation_mode == SurveyMapProjection.RotationMode.HEADING_UP:
				offset_world = offset_world.rotated(player_yaw)
			chart_center_in_map = center + offset_world * (r / view_radius_m)

		var draw_rot: float = (
			player_yaw if rotation_mode == SurveyMapProjection.RotationMode.HEADING_UP else 0.0
		)

		control.draw_set_transform(chart_center_in_map, draw_rot, Vector2.ONE * chart_scale)
		control.draw_texture(_chart_texture, -tex_size * 0.5, Color(1, 1, 1, 0.85))
		control.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 3. Concentric grid lines & compass cross
	control.draw_arc(center, r * 0.5, 0.0, TAU, 32, GRID_COLOR, 1.0)
	control.draw_arc(center, r * 0.9, 0.0, TAU, 48, GRID_COLOR, 1.0)
	control.draw_line(center - Vector2(r, 0), center + Vector2(r, 0), GRID_COLOR, 1.0)
	control.draw_line(center - Vector2(0, r), center + Vector2(0, r), GRID_COLOR, 1.0)

	# 4. Teammate markers (squad mode only, zero markers in FFA)
	var teammate_idx: int = 0
	for peer_id: int in _teammates:
		var data: Dictionary = _teammates[peer_id]
		var cb: Callable = data.get("callable", Callable())
		if not cb.is_valid():
			continue
		var t_pos: Variant = cb.call()
		if not t_pos is Vector3:
			continue
		var m_pt: Vector2 = SurveyMapProjection.world_to_map_point(
			t_pos,
			Vector3.ZERO if current_zoom == SurveyMapProjection.ZoomLevel.FULL_DISK else player_pos,
			view_radius_m,
			control.size,
			(
				SurveyMapProjection.RotationMode.NORTH_UP
				if current_zoom == SurveyMapProjection.ZoomLevel.FULL_DISK
				else rotation_mode
			),
			player_yaw
		)
		if SurveyMapProjection.is_within_map_radius(m_pt, center, r - 4.0):
			var col: Color = TEAMMATE_COLORS[teammate_idx % TEAMMATE_COLORS.size()]
			control.draw_circle(m_pt, 4.0, col)
		teammate_idx += 1

	# 5. Local Player marker
	var player_map_pt: Vector2 = center
	if current_zoom == SurveyMapProjection.ZoomLevel.FULL_DISK:
		player_map_pt = SurveyMapProjection.world_to_map_point(
			player_pos,
			Vector3.ZERO,
			_config.disk_radius_m,
			control.size,
			SurveyMapProjection.RotationMode.NORTH_UP,
			0.0
		)

	if SurveyMapProjection.is_within_map_radius(player_map_pt, center, r - 2.0):
		var arrow_angle: float = 0.0
		if current_zoom == SurveyMapProjection.ZoomLevel.FULL_DISK:
			arrow_angle = -player_yaw - PI * 0.5
		elif rotation_mode == SurveyMapProjection.RotationMode.NORTH_UP:
			arrow_angle = -player_yaw - PI * 0.5
		else:
			arrow_angle = -PI * 0.5  # Heading up: forward is always up

		var arrow_dir: Vector2 = Vector2.from_angle(arrow_angle)
		var arrow_tip: Vector2 = player_map_pt + arrow_dir * 9.0
		var arrow_left: Vector2 = player_map_pt + Vector2.from_angle(arrow_angle + 2.5) * 6.0
		var arrow_right: Vector2 = player_map_pt + Vector2.from_angle(arrow_angle - 2.5) * 6.0

		var poly: PackedVector2Array = PackedVector2Array([arrow_tip, arrow_left, arrow_right])
		control.draw_colored_polygon(poly, PLAYER_COLOR)
		control.draw_polyline(
			PackedVector2Array([arrow_tip, arrow_left, arrow_right, arrow_tip]), Color.BLACK, 1.5
		)

	# 6. Cardinal Marks on Bezel
	var n_angle: float = (
		0.0
		if (
			rotation_mode == SurveyMapProjection.RotationMode.NORTH_UP
			or current_zoom == SurveyMapProjection.ZoomLevel.FULL_DISK
		)
		else player_yaw
	)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 11
	_draw_cardinal_label(control, font, font_size, center, r + 1.0, -PI * 0.5 + n_angle, "N")
	_draw_cardinal_label(control, font, font_size, center, r + 1.0, 0.0 + n_angle, "E")
	_draw_cardinal_label(control, font, font_size, center, r + 1.0, PI * 0.5 + n_angle, "S")
	_draw_cardinal_label(control, font, font_size, center, r + 1.0, PI + n_angle, "W")


func _draw_cardinal_label(
	control: Control,
	font: Font,
	font_size: int,
	center: Vector2,
	radius: float,
	angle: float,
	text: String
) -> void:
	var pos: Vector2 = center + Vector2.from_angle(angle) * (radius - 8.0)
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	control.draw_string(
		font,
		pos - text_size * 0.5 + Vector2(0, text_size.y * 0.4),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		font_size,
		TEXT_GOLD if text == "N" else TEXT_MUTED
	)


func draw_fullscreen_crosshair(control: Control) -> void:
	if _config == null or control == null or not is_instance_valid(_fullscreen_chart_rect):
		return
	var rect_size: Vector2 = _fullscreen_chart_rect.size
	var rect_pos: Vector2 = _fullscreen_chart_rect.position
	var chart_center: Vector2 = rect_pos + rect_size * 0.5
	var r: float = rect_size.x * 0.5

	var player_pos: Vector3 = (
		_target_player.global_position if is_instance_valid(_target_player) else Vector3.ZERO
	)
	var player_yaw: float = _target_player.rotation.y if is_instance_valid(_target_player) else 0.0

	var p_norm: Vector2 = SurveyMapProjection.world_to_normalized_disk(
		player_pos, _config.disk_radius_m
	)
	var p_canvas: Vector2 = chart_center + p_norm * r

	# Crosshair on chart
	control.draw_line(p_canvas - Vector2(12, 0), p_canvas + Vector2(12, 0), PLAYER_COLOR, 2.0)
	control.draw_line(p_canvas - Vector2(0, 12), p_canvas + Vector2(0, 12), PLAYER_COLOR, 2.0)
	control.draw_circle(p_canvas, 3.0, Color.BLACK)

	# Facing vector
	var heading_angle: float = -player_yaw - PI * 0.5
	var facing_end: Vector2 = p_canvas + Vector2.from_angle(heading_angle) * 18.0
	control.draw_line(p_canvas, facing_end, PLAYER_COLOR, 2.0)
