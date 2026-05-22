extends Node2D
class_name TerrainGrid
## Placeholder isometric terrain grid drawn procedurally.
## Renders a GRID_SIZE × GRID_SIZE isometric tile field with a marked dungeon entrance.
## Responds to phase changes by adjusting its modulate (handled by DayNightSystem on parent).

# ── Constants ─────────────────────────────────────────────────────────────────
const TILE_W: int = 64   ## Full tile width in pixels
const TILE_H: int = 32   ## Full tile height in pixels (half width for isometric)
const GRID_SIZE: int = 20

const DUNGEON_ENTRANCE: Vector2i = Vector2i(10, 10)

const COLOR_EVEN:           Color = Color(0.58, 0.76, 0.48)
const COLOR_ODD:            Color = Color(0.52, 0.69, 0.43)
const COLOR_DUNGEON_FILL:   Color = Color(0.22, 0.10, 0.32)
const COLOR_DUNGEON_BORDER: Color = Color(0.65, 0.30, 0.90)
const COLOR_GRID:           Color = Color(0.38, 0.55, 0.30, 0.40)
const COLOR_ENTRANCE_LABEL: Color = Color.WHITE

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	_draw_tiles()
	_draw_dungeon_entrance()

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw_tiles() -> void:
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var coord := Vector2i(col, row)
			if coord == DUNGEON_ENTRANCE:
				continue  # drawn separately
			var center: Vector2 = iso_to_screen(coord)
			var color: Color = COLOR_EVEN if (col + row) % 2 == 0 else COLOR_ODD
			_draw_iso_tile(center, color, COLOR_GRID, 1.0)

func _draw_dungeon_entrance() -> void:
	var center: Vector2 = iso_to_screen(DUNGEON_ENTRANCE)
	_draw_iso_tile(center, COLOR_DUNGEON_FILL, COLOR_DUNGEON_BORDER, 2.0)
	# Label
	var font: Font = ThemeDB.fallback_font
	draw_string(font, center + Vector2(-10, 6), "D U N G E O N",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_ENTRANCE_LABEL)

func _draw_iso_tile(center: Vector2, fill: Color, border: Color, border_width: float) -> void:
	var pts: PackedVector2Array = _tile_polygon(center)
	draw_colored_polygon(pts, fill)
	draw_polyline(pts, border, border_width)

func _tile_polygon(center: Vector2) -> PackedVector2Array:
	var hw: float = TILE_W * 0.5
	var hh: float = TILE_H * 0.5
	# Diamond: top, right, bottom, left, close
	return PackedVector2Array([
		Vector2(center.x,        center.y - hh),
		Vector2(center.x + hw,   center.y),
		Vector2(center.x,        center.y + hh),
		Vector2(center.x - hw,   center.y),
		Vector2(center.x,        center.y - hh),
	])

# ── Coordinate Helpers ────────────────────────────────────────────────────────

func iso_to_screen(tile: Vector2i) -> Vector2:
	## Convert grid (col, row) to isometric screen position.
	return Vector2(
		float(tile.x - tile.y) * float(TILE_W) * 0.5,
		float(tile.x + tile.y) * float(TILE_H) * 0.5
	)

func screen_to_iso(screen: Vector2) -> Vector2i:
	## Convert screen position to nearest grid tile.
	var col: float = (screen.x / float(TILE_W) + screen.y / float(TILE_H))
	var row: float = (screen.y / float(TILE_H) - screen.x / float(TILE_W))
	return Vector2i(int(round(col)), int(round(row)))

func get_dungeon_screen_pos() -> Vector2:
	return iso_to_screen(DUNGEON_ENTRANCE)
