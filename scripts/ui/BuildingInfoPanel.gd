extends PanelContainer
class_name BuildingInfoPanel
## Building info panel — shown when a placed building is selected.
## Displays name, tier, category, income/upkeep, staffing, upgrade requirements, demolish.

const PANEL_W: float = 270.0
const PANEL_H: float = 380.0
const MARGIN:  float = 10.0

# ── Node refs ─────────────────────────────────────────────────────────────────
var _title_label:   Label
var _sub_label:     Label
var _income_label:  Label
var _upkeep_label:  Label
var _staff_label:   Label
var _cap_label:     Label
var _req_container: VBoxContainer
var _upgrade_btn:   Button
var _construction_label: Label
var _demolish_btn:  Button
var _confirm_row:   HBoxContainer

# ── State ─────────────────────────────────────────────────────────────────────
var _current_instance: String = ""
var _grid:    BuildingGrid   = null
var _manager: UpgradeManager = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ui()
	hide()
	await get_tree().process_frame
	_grid    = get_tree().root.find_child("BuildingGrid",   true, false) as BuildingGrid
	_manager = get_tree().root.find_child("UpgradeManager", true, false) as UpgradeManager
	EventBus.building_selected.connect(_on_building_selected)
	EventBus.building_deselected.connect(_on_building_deselected)
	EventBus.building_demolished.connect(_on_building_demolished)
	EventBus.building_upgrade_started.connect(_on_upgrade_started)
	EventBus.building_upgrade_completed.connect(_on_upgrade_completed)
	EventBus.day_started.connect(_on_day_started)

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

func _on_upgrade_started(instance_id: String, _target: String, _day: int) -> void:
	if _current_instance == instance_id:
		_refresh()

func _on_upgrade_completed(old_instance_id: String, new_instance_id: String) -> void:
	if _current_instance == old_instance_id:
		_current_instance = new_instance_id
		_refresh()

func _on_day_started(_day: int) -> void:
	if visible and _current_instance != "" and _manager != null:
		if _manager.is_under_construction(_current_instance):
			_refresh()

# ── Refresh ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	if _current_instance.is_empty() or _grid == null:
		return
	_confirm_row.hide()

	var data_id := _grid.get_data_id_for_instance(_current_instance)
	var data    := DataRegistry.get_building(data_id) as BuildingData
	if data == null:
		_title_label.text = "Unknown Building"
		return

	_title_label.text  = data.display_name
	_sub_label.text    = "Tier %d  ·  %s" % [data.tier, data.category.capitalize()]

	if data.base_income > 0:
		_income_label.text = "Income:   %d g/day" % data.base_income
	elif data.income_per_guest > 0:
		_income_label.text = "Income:   %d g/guest/night" % data.income_per_guest
	else:
		_income_label.text = "Income:   —"
	_upkeep_label.text = "Upkeep:   %d g/day" % data.upkeep
	_staff_label.text  = "Staff:    %d" % data.staffing
	_cap_label.text    = "Capacity: %d" % data.capacity if data.capacity > 0 else "Capacity: —"

	# Under construction state
	var under_construction: bool = _manager != null and _manager.is_under_construction(_current_instance)
	if under_construction:
		_show_construction_state()
		return

	# Upgrade / no upgrade
	if data.upgrade_to != "":
		_show_upgrade_requirements(data)
	else:
		_req_container.visible = false
		_upgrade_btn.visible   = false
		_construction_label.visible = false

	_demolish_btn.show()

func _show_construction_state() -> void:
	_clear_requirements()
	var days: int = _manager.days_remaining(_current_instance) if _manager else 0
	_construction_label.text    = "Under Construction — %d day%s remaining" % [days, "s" if days != 1 else ""]
	_construction_label.visible = true
	_req_container.visible      = false
	_upgrade_btn.visible        = false
	_demolish_btn.hide()

func _show_upgrade_requirements(data: BuildingData) -> void:
	_clear_requirements()
	_construction_label.visible = false

	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	var can_upgrade: bool = result["can_upgrade"]

	# Requirement rows
	for req in result["requirements"]:
		_req_container.add_child(_make_req_row(req))
	_req_container.visible = not result["requirements"].is_empty()

	# Next building name
	var next := DataRegistry.get_building(data.upgrade_to) as BuildingData
	var next_name: String = next.display_name if next else data.upgrade_to
	_upgrade_btn.text     = "Upgrade → %s" % next_name
	_upgrade_btn.disabled = not can_upgrade
	_upgrade_btn.visible  = true

func _make_req_row(req: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var icon := Label.new()
	icon.add_theme_font_size_override("font_size", 12)
	if not req["trackable"]:
		icon.text    = "~"
		icon.modulate = Color(0.6, 0.6, 0.6)
	elif req["met"]:
		icon.text    = "✓"
		icon.modulate = Color(0.3, 1.0, 0.4)
	else:
		icon.text    = "✗"
		icon.modulate = Color(1.0, 0.3, 0.3)
	row.add_child(icon)

	var lbl := Label.new()
	lbl.text = req["label"]
	lbl.add_theme_font_size_override("font_size", 11)
	if not req["trackable"]:
		lbl.modulate = Color(0.6, 0.6, 0.6)
		lbl.text    += " (M2)"
	row.add_child(lbl)
	return row

func _clear_requirements() -> void:
	for child in _req_container.get_children():
		child.queue_free()

# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_CENTER_LEFT)
	offset_left   = MARGIN
	offset_top    = -PANEL_H * 0.5
	offset_right  = MARGIN + PANEL_W
	offset_bottom = PANEL_H * 0.5
	custom_minimum_size = Vector2(PANEL_W, PANEL_H)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# Header
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

	_sub_label = Label.new()
	_sub_label.add_theme_font_size_override("font_size", 11)
	_sub_label.modulate = Color(0.75, 0.75, 0.75)
	vbox.add_child(_sub_label)

	_add_sep(vbox)
	_income_label = _stat(vbox)
	_upkeep_label = _stat(vbox)
	_staff_label  = _stat(vbox)
	_cap_label    = _stat(vbox)
	_add_sep(vbox)

	# Under-construction label
	_construction_label = Label.new()
	_construction_label.add_theme_font_size_override("font_size", 11)
	_construction_label.modulate = Color(1.0, 0.85, 0.4)
	_construction_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_construction_label.visible = false
	vbox.add_child(_construction_label)

	# Requirements list
	_req_container = VBoxContainer.new()
	_req_container.add_theme_constant_override("separation", 2)
	vbox.add_child(_req_container)

	# Upgrade button
	_upgrade_btn = Button.new()
	_upgrade_btn.add_theme_font_size_override("font_size", 11)
	_upgrade_btn.custom_minimum_size.y = 28
	_upgrade_btn.visible = false
	_upgrade_btn.pressed.connect(_on_upgrade_pressed)
	vbox.add_child(_upgrade_btn)

	_add_sep(vbox)

	# Demolish
	_demolish_btn = Button.new()
	_demolish_btn.text = "Demolish"
	_demolish_btn.add_theme_font_size_override("font_size", 11)
	_demolish_btn.custom_minimum_size.y = 28
	_demolish_btn.modulate = Color(1.0, 0.5, 0.5)
	_demolish_btn.pressed.connect(_on_demolish_pressed)
	vbox.add_child(_demolish_btn)

	# Confirm row
	_confirm_row = HBoxContainer.new()
	_confirm_row.add_theme_constant_override("separation", 6)
	_confirm_row.hide()
	vbox.add_child(_confirm_row)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm Demolish"
	confirm_btn.add_theme_font_size_override("font_size", 11)
	confirm_btn.custom_minimum_size.y = 28
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.modulate = Color(1.0, 0.35, 0.35)
	confirm_btn.pressed.connect(_on_confirm_demolish)
	_confirm_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 11)
	cancel_btn.custom_minimum_size.y = 28
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_on_cancel_demolish)
	_confirm_row.add_child(cancel_btn)

# ── Button callbacks ──────────────────────────────────────────────────────────

func _on_upgrade_pressed() -> void:
	if _manager == null or _grid == null:
		return
	var data_id := _grid.get_data_id_for_instance(_current_instance)
	var data    := DataRegistry.get_building(data_id) as BuildingData
	if data:
		_manager.start_upgrade(_current_instance, data)

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

func _stat(parent: VBoxContainer) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 12)
	parent.add_child(lbl)
	return lbl

func _add_sep(parent: VBoxContainer) -> void:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 3)
	parent.add_child(sep)
