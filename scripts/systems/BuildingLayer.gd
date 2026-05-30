extends Node2D
class_name BuildingLayer
## Draws all confirmed placed buildings as coloured isometric footprints.
## Reads placement data from BuildingGrid and redraws on building_placed signal.

const TILE_W: int = 64
const TILE_H: int = 32
const BORDER_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)

var _grid: BuildingGrid = null

func _ready() -> void:
	await get_tree().process_frame
	_grid = get_parent().get_node_or_null("BuildingGrid") as BuildingGrid
	if _grid == null:
		push_error("BuildingLayer: BuildingGrid sibling not found")
		return
	EventBus.building_placed.connect(_on_building_placed)

func _on_building_placed(_id: String, _origin: Vector2i) -> void:
	queue_redraw()

func _draw() -> void:
	if _grid == null:
		return
	for placement in _grid.get_placements():
		var color: Color = PlaceholderColors.get_building_color(placement["category"])
		_draw_footprint(placement["origin"], placement["footprint"], color)

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw_footprint(origin: Vector2i, footprint: Vector2i, color: Color) -> void:
	for row in range(footprint.y):
		for col in range(footprint.x):
			var tile := origin + Vector2i(col, row)
			var center := _iso_to_screen(tile)
			_draw_iso_tile(center, color)

func _draw_iso_tile(center: Vector2, fill: Color) -> void:
	var pts := _tile_polygon(center)
	draw_colored_polygon(pts, fill)
	draw_polyline(pts, BORDER_COLOR, 1.5)

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
