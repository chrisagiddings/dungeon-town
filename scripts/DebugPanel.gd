extends PanelContainer
class_name DebugPanel
## Debug panel: action buttons + scrolling log output.
## Positioned bottom-right. Builds its own UI in _ready().

# ── Constants ─────────────────────────────────────────────────────────────────
const MAX_LOG_LINES: int = 30
const PANEL_WIDTH:   float = 320.0
const PANEL_HEIGHT:  float = 270.0
const MARGIN:        float = 10.0

# ── State ─────────────────────────────────────────────────────────────────────
var _log_output: RichTextLabel
var _log_lines: Array[String] = []
var _last_adv_id: String = ""

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ui()
	EventBus.debug_log_message.connect(_on_log)

# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Anchor to bottom-right corner
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left   = -(PANEL_WIDTH + MARGIN)
	offset_top    = -(PANEL_HEIGHT + MARGIN)
	offset_right  = -MARGIN
	offset_bottom = -MARGIN
	custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)

	# Title bar
	var title := Label.new()
	title.text = "  Debug Panel"
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = Color(0.75, 0.80, 1.0)
	vbox.add_child(title)

	# Row 1 buttons
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 4)
	vbox.add_child(row1)
	_btn(row1, "Spawn Adventurer", _on_spawn)
	_btn(row1, "Advance Time",     _on_advance_time)

	# Row 2 buttons
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 4)
	vbox.add_child(row2)
	_btn(row2, "Dungeon Run",  _on_dungeon_run)
	_btn(row2, "Speed Cycle",  _on_speed_cycle)
	_btn(row2, "Pause/Play",   _on_pause_toggle)

	# Log label
	var log_hdr := Label.new()
	log_hdr.text = "Log:"
	log_hdr.add_theme_font_size_override("font_size", 11)
	log_hdr.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(log_hdr)

	# Log output
	_log_output = RichTextLabel.new()
	_log_output.custom_minimum_size = Vector2(PANEL_WIDTH - 16, 170)
	_log_output.scroll_following  = true
	_log_output.selection_enabled = true
	_log_output.add_theme_font_size_override("normal_font_size", 11)
	vbox.add_child(_log_output)

func _btn(parent: HBoxContainer, label: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.add_theme_font_size_override("font_size", 11)
	b.custom_minimum_size.y = 26
	b.pressed.connect(cb)
	parent.add_child(b)

# ── Button Callbacks ──────────────────────────────────────────────────────────

func _on_spawn() -> void:
	var spawner: AdventurerSpawner = _find("AdventurerSpawner")
	if spawner:
		var id: String = spawner.spawn_adventurer()
		if not id.is_empty():
			_last_adv_id = id
	else:
		EventBus.debug_log_message.emit("ERROR: AdventurerSpawner not found in scene")

func _on_advance_time() -> void:
	GameState.advance_one_tick()

func _on_dungeon_run() -> void:
	var dungeon: DungeonRunStub = _find("DungeonRunStub")
	if not dungeon:
		EventBus.debug_log_message.emit("ERROR: DungeonRunStub not found in scene")
		return

	# Auto-spawn if we have no adventurer yet
	if _last_adv_id.is_empty():
		_on_spawn()

	if not _last_adv_id.is_empty():
		dungeon.start_run(_last_adv_id)
		# Each press uses a fresh adventurer next time (run is async, no double-send guard here)
		_last_adv_id = ""

func _on_speed_cycle() -> void:
	# Cycle: 1× → 2× → 4× → 0.25× → 1×
	var speeds: Array[float] = [1.0, 2.0, 4.0, 0.25]
	var current: float = GameState.sim_speed
	var next_idx: int = 0
	for i in range(speeds.size()):
		if absf(speeds[i] - current) < 0.01:
			next_idx = (i + 1) % speeds.size()
			break
	GameState.set_sim_speed(speeds[next_idx])

func _on_pause_toggle() -> void:
	GameState.set_paused(not GameState.is_paused)

# ── Log ───────────────────────────────────────────────────────────────────────

func _on_log(message: String) -> void:
	_log_lines.append(message)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	_log_output.clear()
	for line in _log_lines:
		_log_output.add_text(line + "\n")

# ── Helpers ───────────────────────────────────────────────────────────────────

func _find(node_name: String) -> Node:
	return get_tree().root.find_child(node_name, true, false)
