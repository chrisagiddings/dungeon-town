extends Node2D
class_name BuildingPlacer
## Handles building placement mode: preview, input, confirm, cancel.
## Enter placement mode by calling enter_placement_mode(building_data).
## Confirm: left-click on a valid tile.
## Cancel: right-click or ESC.

# ── Constants ─────────────────────────────────────────────────────────────────
const TILE_W: int = 64
const TILE_H: int = 32
const COLOR_VALID:   Color = Color(0.2, 1.0, 0.3, 0.55)
const COLOR_INVALID: Color = Color(1.0, 0.2, 0.2, 0.55)
const COLOR_BORDER_VALID:   Color = Color(0.1, 0.9, 0.2, 0.9)
const COLOR_BORDER_INVALID: Color = Color(0.9, 0.1, 0.1, 0.9)

# ── State ─────────────────────────────────────────────────────────────────────
var _active_data: BuildingData = null
var _preview_origin: Vector2i = Vector2i(-1, -1)
var _is_valid: bool = false
var _grid: BuildingGrid = null
var _terrain: TerrainGrid = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	await get_tree().process_frame
	_grid    = get_parent().get_node_or_null("BuildingGrid") as BuildingGrid
	_terrain = get_parent().get_node_or_null("TerrainGrid")  as TerrainGrid
	if _grid == null:
		push_error("BuildingPlacer: BuildingGrid sibling not found")
	if _terrain == null:
		push_error("BuildingPlacer: TerrainGrid sibling not found")

func _process(_delta: float) -> void:
	if not is_placing():
		return
	var mouse_world := get_global_mouse_position()
	var local_pos   := _terrain.to_local(mouse_world)
	var tile        := _terrain.screen_to_iso(local_pos)
	if tile != _preview_origin:
		_preview_origin = tile
		_is_valid = _grid.can_place(_preview_origin, _active_data.footprint)
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not is_placing():
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT and _is_valid:
			_confirm_placement()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_placement()
			get_viewport().set_input_as_handled()

	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode == KEY_ESCAPE:
			_cancel_placement()
			get_viewport().set_input_as_handled()

func _draw() -> void:
	if not is_placing() or _preview_origin == Vector2i(-1, -1):
		return
	var fill   := COLOR_VALID   if _is_valid else COLOR_INVALID
	var border := COLOR_BORDER_VALID if _is_valid else COLOR_BORDER_INVALID
	for row in range(_active_data.footprint.y):
		for col in range(_active_data.footprint.x):
			var tile    := _preview_origin + Vector2i(col, row)
			var center  := _iso_to_screen(tile)
			_draw_iso_tile(center, fill, border)

# ── Public API ────────────────────────────────────────────────────────────────

func enter_placement_mode(data: BuildingData) -> void:
	_active_data    = data
	_preview_origin = Vector2i(-1, -1)
	_is_valid       = false
	queue_redraw()
	EventBus.building_placement_started.emit(data)
	EventBus.debug_log_message.emit(
		"Placement mode: %s (%dx%d)" % [data.display_name, data.footprint.x, data.footprint.y]
	)

func exit_placement_mode() -> void:
	_active_data    = null
	_preview_origin = Vector2i(-1, -1)
	_is_valid       = false
	queue_redraw()

func is_placing() -> bool:
	return _active_data != null

# ── Internal ──────────────────────────────────────────────────────────────────

func _confirm_placement() -> void:
	_grid.reserve(_preview_origin, _active_data.footprint, _active_data.id, _active_data.category)
	EventBus.debug_log_message.emit(
		"Placed: %s at %s" % [_active_data.display_name, _preview_origin]
	)
	exit_placement_mode()

func _cancel_placement() -> void:
	EventBus.building_placement_cancelled.emit()
	EventBus.debug_log_message.emit("Placement cancelled")
	exit_placement_mode()

func _draw_iso_tile(center: Vector2, fill: Color, border: Color) -> void:
	var pts := _tile_polygon(center)
	draw_colored_polygon(pts, fill)
	draw_polyline(pts, border, 2.0)

func _tile_polygon(center: Vector2) -> PackedVector2Array:
	var hw: float = TILE_W * 0.5
	var hh: float = TILE_H * 0.5
	return PackedVector2Array([
		Vector2(center.x,       center.y - hh),
		Vector2(center.x + hw,  center.y),
		Vector2(center.x,       center.y + hh),
		Vector2(center.x - hw,  center.y),
		Vector2(center.x,       center.y - hh),
	])

func _iso_to_screen(tile: Vector2i) -> Vector2:
	return Vector2(
		float(tile.x - tile.y) * float(TILE_W) * 0.5,
		float(tile.x + tile.y) * float(TILE_H) * 0.5
	)
