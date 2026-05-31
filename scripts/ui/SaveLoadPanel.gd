extends PanelContainer
class_name SaveLoadPanel
## Save/Load slot UI — 5 manual slots + autosave display.
## Each slot shows its save name (default: town name + day).
## Manual slots allow renaming via an inline text field.

const PANEL_W: float = 400.0
const PANEL_H: float = 310.0
const MARGIN:  float = 10.0

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

	# Autosave row (load-only, not renameable)
	vbox.add_child(_build_slot_row(0, "Autosave", true))
	vbox.add_child(_sep())

	# Manual slots 1–5
	for slot in range(1, SaveSystem.MAX_SLOTS + 1):
		vbox.add_child(_build_slot_row(slot, "Slot %d" % slot, false))

func _build_slot_row(slot: int, label: String, read_only: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_slot_rows.append(row)

	# Slot label
	var name_lbl := Label.new()
	name_lbl.text = label
	name_lbl.custom_minimum_size.x = 58
	name_lbl.add_theme_font_size_override("font_size", 11)
	row.add_child(name_lbl)

	if read_only:
		# Autosave: just a static info label
		var info_lbl := Label.new()
		info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_lbl.add_theme_font_size_override("font_size", 11)
		info_lbl.modulate = Color(0.7, 0.7, 0.7)
		info_lbl.name = "InfoLabel"
		row.add_child(info_lbl)
	else:
		# Editable name field
		var name_edit := LineEdit.new()
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_edit.add_theme_font_size_override("font_size", 11)
		name_edit.placeholder_text = "— empty —"
		name_edit.editable = false
		name_edit.name = "NameEdit"
		name_edit.text_submitted.connect(func(t): _on_name_submitted(slot, t, name_edit))
		name_edit.focus_exited.connect(func(): _on_name_submitted(slot, name_edit.text, name_edit))
		row.add_child(name_edit)

		# Save button
		var save_btn := Button.new()
		save_btn.text = "Save"
		save_btn.add_theme_font_size_override("font_size", 11)
		save_btn.custom_minimum_size = Vector2(46, 26)
		save_btn.pressed.connect(func(): _do_save(slot))
		row.add_child(save_btn)

	# Load button
	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.add_theme_font_size_override("font_size", 11)
	load_btn.custom_minimum_size = Vector2(46, 26)
	load_btn.name = "LoadButton"
	load_btn.pressed.connect(func(): _confirm_load(slot, load_btn))
	row.add_child(load_btn)

	_update_row(row, slot)
	return row

# ── Save / Load actions ───────────────────────────────────────────────────────

func _do_save(slot: int) -> void:
	SaveSystem.save(slot)
	# After saving, make the name field editable so the user can rename
	var row := _slot_rows[slot]
	var name_edit := row.get_node_or_null("NameEdit") as LineEdit
	if name_edit:
		name_edit.editable = true
		name_edit.grab_focus()
		name_edit.select_all()

func _on_name_submitted(slot: int, new_text: String, edit: LineEdit) -> void:
	var trimmed := new_text.strip_edges()
	if trimmed.is_empty():
		# Revert to default
		var info := SaveSystem.get_save_info(slot)
		trimmed = info.get("name", "")
	SaveSystem.rename_save(slot, trimmed)
	edit.text    = trimmed
	edit.editable = false
	edit.release_focus()

func _confirm_load(slot: int, btn: Button) -> void:
	var orig_text: String = btn.text
	if btn.text == "Confirm?":
		SaveSystem.load_slot(slot)
		btn.text = orig_text
	else:
		btn.text = "Confirm?"
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(btn):
			btn.text = orig_text

# ── Slot refresh ──────────────────────────────────────────────────────────────

func _refresh_slots() -> void:
	for i in range(_slot_rows.size()):
		_update_row(_slot_rows[i], i)

func _update_row(row: HBoxContainer, slot: int) -> void:
	var info   := SaveSystem.get_save_info(slot)
	var empty  := info.is_empty()

	# Autosave uses InfoLabel; manual slots use NameEdit
	var info_lbl  := row.get_node_or_null("InfoLabel")  as Label
	var name_edit := row.get_node_or_null("NameEdit")   as LineEdit
	var load_btn  := row.get_node_or_null("LoadButton") as Button

	if info_lbl:
		info_lbl.text = "— empty —" if empty else \
			"%s  |  Day %d  |  %dg" % [info.get("name",""), info.get("day",0), info.get("gold",0)]

	if name_edit:
		if empty:
			name_edit.text       = ""
			name_edit.placeholder_text = "— empty —"
			name_edit.editable   = false
		else:
			name_edit.text       = info.get("name", "")
			name_edit.editable   = false  # editable only after Save

	if load_btn:
		load_btn.disabled = empty

func _sep() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_constant_override("separation", 3)
	return s
