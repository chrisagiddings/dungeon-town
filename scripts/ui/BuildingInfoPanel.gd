extends PanelContainer
class_name BuildingInfoPanel
## Building info panel — shown when a placed building is selected.
## Displays name, tier, category, income/upkeep, staffing, upgrade path, and demolish.

# ── Layout constants ──────────────────────────────────────────────────────────
const PANEL_W: float  = 260.0
const PANEL_H: float  = 300.0
const MARGIN:  float  = 10.0

# ── Node refs ─────────────────────────────────────────────────────────────────
var _title_label:    Label
var _sub_label:      Label
var _income_label:   Label
var _upkeep_label:   Label
var _staff_label:    Label
var _cap_label:      Label
var _upgrade_btn:    Button
var _upgrade_info:   Label
var _demolish_btn:   Button
var _confirm_row:    HBoxContainer

# ── State ─────────────────────────────────────────────────────────────────────
var _current_instance: String = ""
var _grid: BuildingGrid = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ui()
	hide()
	await get_tree().process_frame
	_grid = get_tree().root.find_child("BuildingGrid", true, false) as BuildingGrid
	EventBus.building_selected.connect(_on_building_selected)
	EventBus.building_deselected.connect(_on_building_deselected)
	EventBus.building_demolished.connect(_on_building_demolished)

# ── EventBus handlers ─────────────────────────────────────────────────────────

func _on_building_selected(instance_id: String) -> void:
	_current_instance = instance_id
	_refresh()
	show()

func _on_building_deselected() -> void:
	hide()
	_current_instance = ""

func _on_building_demolished(instance_id: String) -> void:
	if _current_instance == instance_id:
		hide()
		_current_instance = ""

# ── Refresh ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	if _current_instance.is_empty() or _grid == null:
		return

	var data_id := _grid.get_data_id_for_instance(_current_instance)
	var data    := DataRegistry.get_building(data_id) as BuildingData
	if data == null:
		_title_label.text = "Unknown Building"
		return

	_title_label.text  = data.display_name
	_sub_label.text    = "Tier %d  ·  %s" % [data.tier, data.category.capitalize()]
	_income_label.text = "Income:   %d g/day" % data.base_income if data.base_income > 0 \
		else "Income:   %d g/night per guest" % data.income_per_guest if data.income_per_guest > 0 \
		else "Income:   —"
	_upkeep_label.text = "Upkeep:   %d g/day" % data.upkeep
	_staff_label.text  = "Staff:    %d" % data.staffing
	_cap_label.text    = "Capacity: %d" % data.capacity if data.capacity > 0 else "Capacity: —"

	# Upgrade section
	if data.upgrade_to != "":
		var next := DataRegistry.get_building(data.upgrade_to) as BuildingData
		var next_name: String = next.display_name if next else data.upgrade_to
		var can_afford: bool  = EconomyState.can_afford(data.upgrade_cost)
		_upgrade_info.text    = "→ %s  (%d g)" % [next_name, data.upgrade_cost]
		_upgrade_btn.text     = "Upgrade"
		_upgrade_btn.disabled = not can_afford
		_upgrade_btn.visible  = true
		_upgrade_info.visible = true
	else:
		_upgrade_btn.visible  = false
		_upgrade_info.visible = false

	_confirm_row.hide()
	_demolish_btn.show()

# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_CENTER_LEFT)
	offset_left   = MARGIN
	offset_top    = -PANEL_H * 0.5
	offset_right  = MARGIN + PANEL_W
	offset_bottom = PANEL_H * 0.5
	custom_minimum_size = Vector2(PANEL_W, PANEL_H)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)

	# ── Header row ────────────────────────────────────────────────────────────
	var header := HBoxContainer.new()
	vbox.add_child(header)

	_title_label = Label.new()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 14)
	header.add_child(_title_label)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(func(): EventBus.building_deselected.emit())
	header.add_child(close_btn)

	# ── Sub-title ─────────────────────────────────────────────────────────────
	_sub_label = Label.new()
	_sub_label.add_theme_font_size_override("font_size", 11)
	_sub_label.modulate = Color(0.75, 0.75, 0.75)
	vbox.add_child(_sub_label)

	_add_separator(vbox)

	# ── Stats ─────────────────────────────────────────────────────────────────
	_income_label = _stat_label(vbox)
	_upkeep_label = _stat_label(vbox)
	_staff_label  = _stat_label(vbox)
	_cap_label    = _stat_label(vbox)

	_add_separator(vbox)

	# ── Upgrade ───────────────────────────────────────────────────────────────
	_upgrade_info = Label.new()
	_upgrade_info.add_theme_font_size_override("font_size", 11)
	_upgrade_info.modulate = Color(0.85, 0.85, 0.55)
	_upgrade_info.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_upgrade_info)

	_upgrade_btn = Button.new()
	_upgrade_btn.add_theme_font_size_override("font_size", 11)
	_upgrade_btn.custom_minimum_size.y = 28
	_upgrade_btn.pressed.connect(_on_upgrade_pressed)
	vbox.add_child(_upgrade_btn)

	_add_separator(vbox)

	# ── Demolish ──────────────────────────────────────────────────────────────
	_demolish_btn = Button.new()
	_demolish_btn.text = "Demolish"
	_demolish_btn.add_theme_font_size_override("font_size", 11)
	_demolish_btn.custom_minimum_size.y = 28
	_demolish_btn.modulate = Color(1.0, 0.5, 0.5)
	_demolish_btn.pressed.connect(_on_demolish_pressed)
	vbox.add_child(_demolish_btn)

	# Confirm / Cancel row (hidden until Demolish is pressed)
	_confirm_row = HBoxContainer.new()
	_confirm_row.add_theme_constant_override("separation", 6)
	_confirm_row.hide()
	vbox.add_child(_confirm_row)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm Demolish"
	confirm_btn.add_theme_font_size_override("font_size", 11)
	confirm_btn.custom_minimum_size = Vector2(0, 28)
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.modulate = Color(1.0, 0.35, 0.35)
	confirm_btn.pressed.connect(_on_confirm_demolish)
	_confirm_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 11)
	cancel_btn.custom_minimum_size = Vector2(0, 28)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_on_cancel_demolish)
	_confirm_row.add_child(cancel_btn)

# ── Button callbacks ──────────────────────────────────────────────────────────

func _on_upgrade_pressed() -> void:
	EventBus.debug_log_message.emit(
		"Upgrade requested: %s (not implemented in M1)" % _current_instance
	)

func _on_demolish_pressed() -> void:
	_demolish_btn.hide()
	_confirm_row.show()

func _on_cancel_demolish() -> void:
	_confirm_row.hide()
	_demolish_btn.show()

func _on_confirm_demolish() -> void:
	if _current_instance.is_empty() or _grid == null:
		return
	_grid.release(_current_instance)
	EventBus.building_demolished.emit(_current_instance)
	EventBus.debug_log_message.emit("Demolished: %s" % _current_instance)
	EventBus.building_deselected.emit()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _stat_label(parent: VBoxContainer) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 12)
	parent.add_child(lbl)
	return lbl

func _add_separator(parent: VBoxContainer) -> void:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	parent.add_child(sep)
