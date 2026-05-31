extends Node2D
class_name TerrainGrid
## Placeholder isometric terrain grid drawn procedurally.
## Dungeon entrance position and size are read from GameState at draw time.

# ── Constants ─────────────────────────────────────────────────────────────────
const TILE_W: int = 64
const TILE_H: int = 32


const COLOR_EVEN:           Color = Color(0.58, 0.76, 0.48)
const COLOR_ODD:            Color = Color(0.52, 0.69, 0.43)
const COLOR_DUNGEON_FILL:   Color = Color(0.22, 0.10, 0.32)
const COLOR_DUNGEON_BORDER: Color = Color(0.65, 0.30, 0.90)
const COLOR_GRID:           Color = Color(0.38, 0.55, 0.30, 0.40)
const COLOR_ENTRANCE_LABEL: Color = Color.WHITE

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.dungeon_entrance_placed.connect(_on_entrance_placed)
	EventBus.game_loaded.connect(func(_s): queue_redraw())
	queue_redraw()

func _on_entrance_placed(_origin: Vector2i, _size: Vector2i) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_tiles()
	if GameState.dungeon_entrance_origin != Vector2i(-1, -1):
		_draw_dungeon_entrance()

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw_tiles() -> void:
	var entrance_tiles := _get_entrance_tiles()
	for row in range(GameState.grid_size):
		for col in range(GameState.grid_size):
			var coord := Vector2i(col, row)
			if entrance_tiles.has(coord):
				continue  # entrance drawn separately
			var center: Vector2 = iso_to_screen(coord)
			var color: Color = COLOR_EVEN if (col + row) % 2 == 0 else COLOR_ODD
			_draw_iso_tile(center, color, COLOR_GRID, 1.0)

func _draw_dungeon_entrance() -> void:
	var origin:    Vector2i = GameState.dungeon_entrance_origin
	var footprint: Vector2i = GameState.dungeon_entrance_size
	# Draw each tile in the footprint
	for row in range(footprint.y):
		for col in range(footprint.x):
			var tile := origin + Vector2i(col, row)
			var center: Vector2 = iso_to_screen(tile)
			_draw_iso_tile(center, COLOR_DUNGEON_FILL, COLOR_DUNGEON_BORDER, 2.0)
	# Label at footprint centre
	var cx: float = float(origin.x) + float(footprint.x - 1) * 0.5
	var cy: float = float(origin.y) + float(footprint.y - 1) * 0.5
	var center_screen := Vector2(
		(cx - cy) * float(TILE_W) * 0.5,
		(cx + cy) * float(TILE_H) * 0.5
	)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, center_screen + Vector2(-20, 6), "D U N G E O N",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_ENTRANCE_LABEL)

func _draw_iso_tile(center: Vector2, fill: Color, border: Color, border_width: float) -> void:
	var pts: PackedVector2Array = _tile_polygon(center)
	draw_colored_polygon(pts, fill)
	draw_polyline(pts, border, border_width)

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

# ── Coordinate Helpers ────────────────────────────────────────────────────────

func iso_to_screen(tile: Vector2i) -> Vector2:
	return Vector2(
		float(tile.x - tile.y) * float(TILE_W) * 0.5,
		float(tile.x + tile.y) * float(TILE_H) * 0.5
	)

func screen_to_iso(screen: Vector2) -> Vector2i:
	var col: float = (screen.x / float(TILE_W) + screen.y / float(TILE_H))
	var row: float = (screen.y / float(TILE_H) - screen.x / float(TILE_W))
	return Vector2i(int(round(col)), int(round(row)))

func get_dungeon_screen_pos() -> Vector2:
	if GameState.dungeon_entrance_origin == Vector2i(-1, -1):
		return Vector2.ZERO
	return iso_to_screen(GameState.dungeon_entrance_origin)

# ── Internal ──────────────────────────────────────────────────────────────────

func _get_entrance_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var origin: Vector2i    = GameState.dungeon_entrance_origin
	var footprint: Vector2i = GameState.dungeon_entrance_size
	if origin == Vector2i(-1, -1):
		return tiles
	for row in range(footprint.y):
		for col in range(footprint.x):
			tiles.append(origin + Vector2i(col, row))
	return tiles
