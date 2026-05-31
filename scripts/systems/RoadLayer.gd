extends Node2D
class_name RoadLayer
## Draws all placed road tiles as isometric diamonds in ENV_ROAD colour.

const TILE_W: int = 64
const TILE_H: int = 32
const ROAD_COLOR:   Color = PlaceholderColors.ENV_ROAD
const BORDER_COLOR: Color = Color(0.30, 0.26, 0.22, 0.6)

var _grid: RoadGrid = null

func _ready() -> void:
	await get_tree().process_frame
	_grid = get_parent().get_node_or_null("RoadGrid") as RoadGrid
	if _grid == null:
		push_error("RoadLayer: RoadGrid sibling not found")
		return
	EventBus.road_placed.connect(_on_road_changed)
	EventBus.road_removed.connect(_on_road_changed)
	EventBus.game_loaded.connect(func(_s): queue_redraw())

func _on_road_changed(_tile: Vector2i) -> void:
	queue_redraw()

func _draw() -> void:
	if _grid == null:
		return
	for tile in _grid.get_road_tiles():
		_draw_iso_tile(_iso_to_screen(tile))

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw_iso_tile(center: Vector2) -> void:
	var pts := _tile_polygon(center)
	draw_colored_polygon(pts, ROAD_COLOR)
	draw_polyline(pts, BORDER_COLOR, 1.0)

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
