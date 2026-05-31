extends Node2D
class_name BuildingLayer
## Draws all confirmed placed buildings as coloured isometric footprints with labels.
## Uses placeholder_color and display_name from BuildingData via DataRegistry.

const TILE_W: int = 64
const TILE_H: int = 32
const BORDER_COLOR:  Color = Color(0.0, 0.0, 0.0, 0.55)
const LABEL_COLOR:   Color = Color.WHITE
const LABEL_SHADOW:  Color = Color(0.0, 0.0, 0.0, 0.7)

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
		var data: BuildingData = DataRegistry.get_building(placement["data_id"]) as BuildingData
		var color: Color = data.placeholder_color if data else PlaceholderColors.get_building_color(placement["category"])
		var label: String = data.display_name if data else placement["data_id"]
		_draw_footprint(placement["origin"] as Vector2i, placement["footprint"] as Vector2i, color, label)

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw_footprint(origin: Vector2i, footprint: Vector2i, color: Color, label: String) -> void:
	for row in range(footprint.y):
		for col in range(footprint.x):
			var tile := origin + Vector2i(col, row)
			_draw_iso_tile(_iso_to_screen(tile), color)
	# Label at footprint center
	var cx: float = float(footprint.x - 1) * 0.5
	var cy: float = float(footprint.y - 1) * 0.5
	var center_tile := Vector2(float(origin.x) + cx, float(origin.y) + cy)
	var screen_center := Vector2(
		(center_tile.x - center_tile.y) * float(TILE_W) * 0.5,
		(center_tile.x + center_tile.y) * float(TILE_H) * 0.5
	)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 10
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos := screen_center + Vector2(-text_size.x * 0.5, font_size * 0.5)
	# Shadow
	draw_string(font, text_pos + Vector2(1, 1), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, LABEL_SHADOW)
	# Label
	draw_string(font, text_pos, label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, LABEL_COLOR)

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
