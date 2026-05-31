extends PanelContainer
class_name SaveLoadPanel
## Save/Load slot UI — 5 manual slots + autosave display.
## Toggled via DebugPanel "Save/Load" button.

const PANEL_W: float  = 360.0
const PANEL_H: float  = 290.0
const MARGIN:  float  = 10.0

var _slot_rows: Array[HBoxContainer] = []

func _ready() -> void:
	_build_ui()
	hide()
	EventBus.game_saved.connect(func(_s): _refresh_slots())
	EventBus.game_loaded.connect(func(_s): _refresh_slots())

# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left   = -PANEL_W * 0.5
	offset_top    = -PANEL_H * 0.5
	offset_right  =  PANEL_W * 0.5
	offset_bottom =  PANEL_H * 0.5
	custom_minimum_size = Vector2(PANEL_W, PANEL_H)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "  Save / Load"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 14)
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(func(): hide())
	header.add_child(close_btn)

	vbox.add_child(_sep())

	# Autosave row (read-only load)
	vbox.add_child(_build_slot_row(0, "Autosave", read_only_save: true))

	vbox.add_child(_sep())

	# Manual slots 1–5
	for slot in range(1, SaveSystem.MAX_SLOTS + 1):
		vbox.add_child(_build_slot_row(slot, "Slot %d" % slot, read_only_save: false))

func _build_slot_row(slot: int, label: String, read_only_save: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_slot_rows.append(row)

	var name_lbl := Label.new()
	name_lbl.text = label
	name_lbl.custom_minimum_size.x = 70
	name_lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(name_lbl)

	var info_lbl := Label.new()
	info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_lbl.add_theme_font_size_override("font_size", 11)
	info_lbl.modulate = Color(0.7, 0.7, 0.7)
	info_lbl.name = "InfoLabel"
	row.add_child(info_lbl)

	if not read_only_save:
		var save_btn := Button.new()
		save_btn.text = "Save"
		save_btn.add_theme_font_size_override("font_size", 11)
		save_btn.custom_minimum_size = Vector2(52, 26)
		save_btn.pressed.connect(func(): SaveSystem.save(slot))
		row.add_child(save_btn)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.add_theme_font_size_override("font_size", 11)
	load_btn.custom_minimum_size = Vector2(52, 26)
	load_btn.name = "LoadButton"
	load_btn.pressed.connect(func(): _confirm_load(slot, load_btn))
	row.add_child(load_btn)

	_update_row(row, slot)
	return row

# ── Slot refresh ──────────────────────────────────────────────────────────────

func _refresh_slots() -> void:
	# Slot 0 = autosave row (index 0), slots 1–5 = rows 1–5
	for i in range(_slot_rows.size()):
		var slot: int = i  # row 0 = autosave (slot 0), row 1 = slot 1, etc.
		_update_row(_slot_rows[i], slot)

func _update_row(row: HBoxContainer, slot: int) -> void:
	var info_lbl := row.get_node_or_null("InfoLabel") as Label
	var load_btn := row.get_node_or_null("LoadButton") as Button
	if info_lbl == null:
		return
	var info := SaveSystem.get_save_info(slot)
	if info.is_empty():
		info_lbl.text = "— Empty —"
		if load_btn:
			load_btn.disabled = true
	else:
		info_lbl.text = "Day %d  |  %dg  |  %d buildings" % [
			info.get("day", 0), info.get("gold", 0), info.get("buildings", 0)
		]
		if load_btn:
			load_btn.disabled = false

func _confirm_load(slot: int, btn: Button) -> void:
	var orig_text: String = btn.text
	if btn.text == "Confirm?":
		SaveSystem.load_slot(slot)
		btn.text = orig_text
	else:
		btn.text = "Confirm?"
		# Reset after 3 seconds if not clicked
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(btn):
			btn.text = orig_text

func _sep() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_constant_override("separation", 3)
	return s
