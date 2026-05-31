extends Node2D
class_name RoadPlacer
## Handles road painting mode: click-drag to place, right-drag to erase.
## Activated via enter_road_mode() / exit_road_mode().
## Mutually exclusive with BuildingPlacer placement mode.

const TILE_W: int = 64
const TILE_H: int = 32
const COLOR_PREVIEW:  Color = Color(PlaceholderColors.ENV_ROAD.r, PlaceholderColors.ENV_ROAD.g,
									PlaceholderColors.ENV_ROAD.b, 0.75)
const COLOR_ERASE:    Color = Color(1.0, 0.3, 0.3, 0.55)
const COLOR_BORDER:   Color = Color(0.6, 0.5, 0.35, 0.9)

# ── State ─────────────────────────────────────────────────────────────────────
var _active:          bool     = false
var _is_painting:     bool     = false
var _is_erasing:      bool     = false
var _preview_tile:    Vector2i = Vector2i(-1, -1)

var _road_grid:     RoadGrid     = null
var _building_grid: BuildingGrid = null
var _terrain:       TerrainGrid  = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	await get_tree().process_frame
	_road_grid     = get_parent().get_node_or_null("RoadGrid")     as RoadGrid
	_building_grid = get_parent().get_node_or_null("BuildingGrid") as BuildingGrid
	_terrain       = get_parent().get_node_or_null("TerrainGrid")  as TerrainGrid
	if _road_grid == null:
		push_error("RoadPlacer: RoadGrid sibling not found")
	if _building_grid == null:
		push_error("RoadPlacer: BuildingGrid sibling not found")
	if _terrain == null:
		push_error("RoadPlacer: TerrainGrid sibling not found")

func _process(_delta: float) -> void:
	if not _active:
		return
	var tile := _mouse_tile()
	if tile != _preview_tile:
		_preview_tile = tile
		queue_redraw()

	# Paint/erase while button held
	if _is_painting:
		_try_place(tile)
	elif _is_erasing:
		_road_grid.remove_road(tile)

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_is_painting = mb.pressed
			if mb.pressed:
				_try_place(_mouse_tile())
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_is_erasing = mb.pressed
			if mb.pressed:
				_road_grid.remove_road(_mouse_tile())
			get_viewport().set_input_as_handled()

	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode == KEY_ESCAPE:
			exit_road_mode()
			get_viewport().set_input_as_handled()

func _draw() -> void:
	if not _active or _preview_tile == Vector2i(-1, -1):
		return
	var on_building := _building_grid != null and _building_grid.is_tile_occupied(_preview_tile)
	var is_road     := _road_grid != null and _road_grid.has_road(_preview_tile)
	var color: Color
	if on_building:
		color = Color(1.0, 0.2, 0.2, 0.45)  # can't place here
	elif _is_erasing and is_road:
		color = COLOR_ERASE
	else:
		color = COLOR_PREVIEW
	_draw_iso_tile(_iso_to_screen(_preview_tile), color)

# ── Public API ────────────────────────────────────────────────────────────────

func enter_road_mode() -> void:
	_active       = true
	_is_painting  = false
	_is_erasing   = false
	_preview_tile = Vector2i(-1, -1)
	queue_redraw()
	EventBus.road_mode_entered.emit()
	EventBus.debug_log_message.emit("Road tool: ON  (LMB paint · RMB erase · ESC exit)")

func exit_road_mode() -> void:
	_active       = false
	_is_painting  = false
	_is_erasing   = false
	_preview_tile = Vector2i(-1, -1)
	queue_redraw()
	EventBus.road_mode_exited.emit()
	EventBus.debug_log_message.emit("Road tool: OFF")

func is_road_mode() -> bool:
	return _active

# ── Internal ──────────────────────────────────────────────────────────────────

func _try_place(tile: Vector2i) -> void:
	if _building_grid != null and _building_grid.is_tile_occupied(tile):
		return  # can't paint over a building
	_road_grid.place_road(tile)

func _mouse_tile() -> Vector2i:
	return _terrain.screen_to_iso(_terrain.to_local(get_global_mouse_position()))

func _draw_iso_tile(center: Vector2, fill: Color) -> void:
	var pts := _tile_polygon(center)
	draw_colored_polygon(pts, fill)
	draw_polyline(pts, COLOR_BORDER, 1.5)

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
