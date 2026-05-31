extends Node2D
class_name RoadPlacer
## Handles road painting mode: click-drag to place, right-drag to erase.
## Hold SHIFT while painting to constrain to a straight horizontal or vertical line.
## Activated via enter_road_mode() / exit_road_mode().
## Mutually exclusive with BuildingPlacer placement mode.

const TILE_W: int = 64
const TILE_H: int = 32
const COLOR_PREVIEW:       Color = Color(PlaceholderColors.ENV_ROAD.r, PlaceholderColors.ENV_ROAD.g,
										 PlaceholderColors.ENV_ROAD.b, 0.75)
const COLOR_PREVIEW_LINE:  Color = Color(PlaceholderColors.ENV_ROAD.r + 0.15, PlaceholderColors.ENV_ROAD.g + 0.1,
										 PlaceholderColors.ENV_ROAD.b, 0.90)
const COLOR_ERASE:         Color = Color(1.0, 0.3, 0.3, 0.55)
const COLOR_BORDER:        Color = Color(0.6, 0.5, 0.35, 0.9)
const COLOR_BLOCKED:       Color = Color(1.0, 0.2, 0.2, 0.45)

# ── State ─────────────────────────────────────────────────────────────────────
var _active:        bool     = false
var _is_painting:   bool     = false
var _is_erasing:    bool     = false
var _preview_tile:  Vector2i = Vector2i(-1, -1)
var _paint_start:   Vector2i = Vector2i(-1, -1)
var _stroke_tiles:  Array[Vector2i] = []  ## tiles committed in the current stroke

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
	var changed := tile != _preview_tile
	_preview_tile = tile
	if changed:
		queue_redraw()

	if _is_painting:
		if _shift_held():
			_paint_line_stroke(tile)
		else:
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
				_paint_start  = _mouse_tile()
				_stroke_tiles = []
				_try_place(_paint_start)
				_stroke_tiles.append(_paint_start)
			else:
				_paint_start  = Vector2i(-1, -1)
				_stroke_tiles = []
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_is_erasing = mb.pressed
			if mb.pressed:
				_road_grid.remove_road(_mouse_tile())
			get_viewport().set_input_as_handled()

	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.keycode == KEY_ESCAPE and ke.pressed:
			exit_road_mode()
			get_viewport().set_input_as_handled()
		elif ke.keycode == KEY_SHIFT:
			# Redraw preview when SHIFT is toggled mid-drag
			queue_redraw()

func _draw() -> void:
	if not _active or _preview_tile == Vector2i(-1, -1):
		return

	if _is_painting and _shift_held() and _paint_start != Vector2i(-1, -1):
		# Show the projected straight line
		for tile in _line_tiles(_paint_start, _preview_tile):
			var col: Color = COLOR_BLOCKED if _is_blocked(tile) else COLOR_PREVIEW_LINE
			_draw_iso_tile(_iso_to_screen(tile), col)
	else:
		# Single tile cursor preview
		var col: Color
		if _is_blocked(_preview_tile):
			col = COLOR_BLOCKED
		elif _is_erasing and _road_grid != null and _road_grid.has_road(_preview_tile):
			col = COLOR_ERASE
		else:
			col = COLOR_PREVIEW
		_draw_iso_tile(_iso_to_screen(_preview_tile), col)

# ── Public API ────────────────────────────────────────────────────────────────

func enter_road_mode() -> void:
	_active       = true
	_is_painting  = false
	_is_erasing   = false
	_preview_tile = Vector2i(-1, -1)
	_paint_start  = Vector2i(-1, -1)
	_stroke_tiles = []
	queue_redraw()
	EventBus.road_mode_entered.emit()
	EventBus.debug_log_message.emit("Road tool: ON  (LMB=paint · SHIFT+LMB=straight · RMB=erase · ESC=exit)")

func exit_road_mode() -> void:
	_active       = false
	_is_painting  = false
	_is_erasing   = false
	_preview_tile = Vector2i(-1, -1)
	_paint_start  = Vector2i(-1, -1)
	_stroke_tiles = []
	queue_redraw()
	EventBus.road_mode_exited.emit()
	EventBus.debug_log_message.emit("Road tool: OFF")

func is_road_mode() -> bool:
	return _active

# ── Internal ──────────────────────────────────────────────────────────────────

func _paint_line_stroke(end_tile: Vector2i) -> void:
	## Paint only the straight line from _paint_start to end_tile,
	## removing any tiles committed earlier in this stroke that fall off the line.
	var new_tiles := _line_tiles(_paint_start, end_tile)

	# Remove previously-painted stroke tiles that are no longer on the line
	for tile in _stroke_tiles:
		if not new_tiles.has(tile):
			_road_grid.remove_road(tile)

	# Place all tiles on the new line
	for tile in new_tiles:
		_try_place(tile)

	_stroke_tiles = new_tiles

func _line_tiles(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	## Returns tiles for the straight cardinal line from → to.
	## Chooses horizontal or vertical based on dominant delta.
	var tiles: Array[Vector2i] = []
	var dx: int = to.x - from.x
	var dy: int = to.y - from.y
	if abs(dx) >= abs(dy):
		# Horizontal
		var step: int = 1 if dx >= 0 else -1
		var x: int = from.x
		while true:
			tiles.append(Vector2i(x, from.y))
			if x == to.x:
				break
			x += step
	else:
		# Vertical
		var step: int = 1 if dy >= 0 else -1
		var y: int = from.y
		while true:
			tiles.append(Vector2i(from.x, y))
			if y == to.y:
				break
			y += step
	return tiles

func _try_place(tile: Vector2i) -> void:
	if not _is_blocked(tile):
		_road_grid.place_road(tile)

func _is_blocked(tile: Vector2i) -> bool:
	return _building_grid != null and _building_grid.is_tile_occupied(tile)

func _shift_held() -> bool:
	return Input.is_key_pressed(KEY_SHIFT)

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
