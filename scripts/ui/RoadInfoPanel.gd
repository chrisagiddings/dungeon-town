extends PanelContainer
class_name RoadInfoPanel
## Simple info panel shown when a road tile is selected.
## Shows tile coordinates and a Remove button.

const PANEL_W: float = 180.0
const PANEL_H: float = 110.0
const MARGIN:  float = 10.0

var _tile_label:   Label
var _confirm_row:  HBoxContainer
var _remove_btn:   Button

var _current_tile: Vector2i = Vector2i(-1, -1)
var _road_grid:    RoadGrid  = null

func _ready() -> void:
	_build_ui()
	hide()
	await get_tree().process_frame
	_road_grid = get_tree().root.find_child("RoadGrid", true, false) as RoadGrid
	EventBus.road_tile_selected.connect(_on_road_tile_selected)
	EventBus.road_tile_deselected.connect(_on_road_tile_deselected)
	EventBus.road_removed.connect(_on_road_removed)
	EventBus.building_selected.connect(func(_id): hide())

func _on_road_tile_selected(tile: Vector2i) -> void:
	_current_tile  = tile
	_tile_label.text = "Road Tile  [%d, %d]" % [tile.x, tile.y]
	_confirm_row.hide()
	_remove_btn.show()
	show()

func _on_road_tile_deselected() -> void:
	hide()
	_current_tile = Vector2i(-1, -1)

func _on_road_removed(tile: Vector2i) -> void:
	if tile == _current_tile:
		hide()
		_current_tile = Vector2i(-1, -1)

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_CENTER_LEFT)
	offset_left   = MARGIN
	offset_top    = -PANEL_H * 0.5
	offset_right  = MARGIN + PANEL_W
	offset_bottom = PANEL_H * 0.5
	custom_minimum_size = Vector2(PANEL_W, PANEL_H)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "Road"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 14)
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(func(): EventBus.road_tile_deselected.emit())
	header.add_child(close_btn)

	_tile_label = Label.new()
	_tile_label.add_theme_font_size_override("font_size", 11)
	_tile_label.modulate = Color(0.75, 0.75, 0.75)
	vbox.add_child(_tile_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_remove_btn = Button.new()
	_remove_btn.text = "Remove Road"
	_remove_btn.add_theme_font_size_override("font_size", 11)
	_remove_btn.custom_minimum_size.y = 28
	_remove_btn.modulate = Color(1.0, 0.5, 0.5)
	_remove_btn.pressed.connect(_on_remove_pressed)
	vbox.add_child(_remove_btn)

	_confirm_row = HBoxContainer.new()
	_confirm_row.add_theme_constant_override("separation", 6)
	_confirm_row.hide()
	vbox.add_child(_confirm_row)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.add_theme_font_size_override("font_size", 11)
	confirm_btn.custom_minimum_size.y = 28
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.modulate = Color(1.0, 0.35, 0.35)
	confirm_btn.pressed.connect(_on_confirm_remove)
	_confirm_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 11)
	cancel_btn.custom_minimum_size.y = 28
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_on_cancel_remove)
	_confirm_row.add_child(cancel_btn)

func _on_remove_pressed() -> void:
	_remove_btn.hide()
	_confirm_row.show()

func _on_cancel_remove() -> void:
	_confirm_row.hide()
	_remove_btn.show()

func _on_confirm_remove() -> void:
	if _road_grid != null and _current_tile != Vector2i(-1, -1):
		_road_grid.remove_road(_current_tile)
	EventBus.road_tile_deselected.emit()
