extends Node2D
class_name BuildingLayer
## Draws all confirmed placed buildings as coloured isometric footprints with labels.
## Under-construction buildings are drawn with a scaffold colour and "🔨 Building..." label.

const TILE_W: int = 64
const TILE_H: int = 32
const BORDER_COLOR:      Color = Color(0.0, 0.0, 0.0, 0.55)
const LABEL_COLOR:       Color = Color.WHITE
const LABEL_SHADOW:      Color = Color(0.0, 0.0, 0.0, 0.7)
const CONSTRUCTION_COLOR: Color = Color(0.72, 0.68, 0.42, 0.85)

var _grid:    BuildingGrid   = null
var _manager: UpgradeManager = null

func _ready() -> void:
	await get_tree().process_frame
	_grid    = get_parent().get_node_or_null("BuildingGrid") as BuildingGrid
	_manager = get_tree().root.find_child("UpgradeManager", true, false) as UpgradeManager
	if _grid == null:
		push_error("BuildingLayer: BuildingGrid sibling not found")
		return
	EventBus.building_placed.connect(_on_redraw_trigger)
	EventBus.building_demolished.connect(_on_redraw_trigger.bind(""))
	EventBus.building_upgrade_started.connect(_on_redraw_trigger.bind("", 0))
	EventBus.building_upgrade_completed.connect(_on_redraw_trigger.bind(""))
	EventBus.game_loaded.connect(_on_redraw_trigger.bind(0))
	EventBus.building_construction_cancelled.connect(_on_redraw_trigger.bind(""))

func _on_redraw_trigger(_a = null, _b = null, _c = null) -> void:
	queue_redraw()

func _draw() -> void:
	if _grid == null:
		return
	# Sort by isometric depth (painter's algorithm): lower origin.x+origin.y
	# is further from the viewer and must be drawn first.
	var placements := _grid.get_placements().duplicate()
	placements.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ao: Vector2i = a["origin"] as Vector2i
		var bo: Vector2i = b["origin"] as Vector2i
		return (ao.x + ao.y) < (bo.x + bo.y)
	)
	for placement in placements:
		var instance_id: String = placement["instance_id"]
		var under_construction: bool = _manager != null and _manager.is_under_construction(instance_id)

		var data_id: String    = placement.get("data_id", "")
		var data: BuildingData = DataRegistry.get_building(data_id) as BuildingData
		var name:  String      = data.display_name if data else data_id

		var color:    Color
		var label:    String
		var sublabel: String = ""

		if under_construction:
			color = CONSTRUCTION_COLOR
			var days: int = _manager.days_remaining(instance_id)
			var kind: String = _manager.get_all_constructions().get(instance_id, {}).get("kind", "build")
			sublabel = ("Upgrading... (%dd)" if kind == "upgrade" else "Building... (%dd)") % days
			label = name
		else:
			color = data.placeholder_color if data else PlaceholderColors.get_building_color(placement.get("category", ""))
			label = name

		_draw_footprint(placement["origin"] as Vector2i, placement["footprint"] as Vector2i, color, label, sublabel)

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw_footprint(origin: Vector2i, footprint: Vector2i, color: Color, label: String, sublabel: String = "") -> void:
	for row in range(footprint.y):
		for col in range(footprint.x):
			_draw_iso_tile(_iso_to_screen(origin + Vector2i(col, row)), color)
	var cx: float = float(footprint.x - 1) * 0.5
	var cy: float = float(footprint.y - 1) * 0.5
	var ct := Vector2(float(origin.x) + cx, float(origin.y) + cy)
	var sc := Vector2(
		(ct.x - ct.y) * float(TILE_W) * 0.5,
		(ct.x + ct.y) * float(TILE_H) * 0.5
	)
	var font:      Font = ThemeDB.fallback_font
	var font_size: int  = 10
	var line_h:    int  = font_size + 2

	# Main label — shift up slightly if sublabel is present
	var y_offset: float = font_size * 0.5 - (line_h * 0.5 if sublabel != "" else 0.0)
	var sz  := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := sc + Vector2(-sz.x * 0.5, y_offset)
	draw_string(font, pos + Vector2(1, 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, LABEL_SHADOW)
	draw_string(font, pos,                 label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, LABEL_COLOR)

	# Sublabel (construction status) — smaller, amber, below main label
	if sublabel != "":
		var sub_size: int = 9
		var sub_color: Color = Color(1.0, 0.85, 0.4, 0.9)
		var ssz  := font.get_string_size(sublabel, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size)
		var spos := sc + Vector2(-ssz.x * 0.5, y_offset + line_h)
		draw_string(font, spos + Vector2(1, 1), sublabel, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, LABEL_SHADOW)
		draw_string(font, spos,                 sublabel, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, sub_color)

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
