extends PanelContainer
class_name TopBarUI
## Top-of-screen HUD: day counter, time, phase, gold balance, sim speed.
## Builds its own child nodes in _ready() so the .tscn stays simple.

# ── State ─────────────────────────────────────────────────────────────────────
var _day_label:   Label
var _time_label:  Label
var _phase_label: Label
var _gold_label:  Label
var _speed_label: Label

# ── Phase label colors ────────────────────────────────────────────────────────
const PHASE_COLORS: Dictionary = {
	0: Color(1.0, 0.90, 0.50),  # MORNING
	1: Color(0.8, 1.00, 0.80),  # DAY
	2: Color(1.0, 0.60, 0.30),  # EVENING
	3: Color(0.6, 0.60, 1.00),  # NIGHT
}

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ui()
	_connect_signals()
	_refresh_all()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size.y = 36.0

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	add_child(hbox)

	_day_label   = _label("Day 1", 14)
	_time_label  = _label("06:00 AM", 14)
	_phase_label = _label("[Morning]", 14, PHASE_COLORS[0])
	_gold_label  = _label("Gold: 500", 14, Color(1.0, 0.85, 0.20))
	_speed_label = _label("Speed: 1x", 13, Color(0.8, 0.8, 0.8))

	hbox.add_child(_day_label)
	_sep(hbox)
	hbox.add_child(_time_label)
	hbox.add_child(_phase_label)
	_sep(hbox)
	hbox.add_child(_gold_label)
	_sep(hbox)
	hbox.add_child(_speed_label)

func _label(txt: String, size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.modulate = color
	return l

func _sep(parent: HBoxContainer) -> void:
	var s := Label.new()
	s.text = "|"
	s.modulate = Color(1, 1, 1, 0.25)
	parent.add_child(s)

# ── Signals ───────────────────────────────────────────────────────────────────

func _connect_signals() -> void:
	EventBus.time_tick.connect(_on_time_tick)
	EventBus.day_started.connect(_on_day_started)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.sim_speed_changed.connect(_on_speed_changed)
	EventBus.sim_paused.connect(_on_paused)

func _refresh_all() -> void:
	_day_label.text   = "Day %d" % GameState.current_day
	_time_label.text  = GameState.get_time_string()
	_phase_label.text = "[%s]" % GameState.get_phase_name()
	_gold_label.text  = "Gold: %d" % EconomyState.gold

func _on_time_tick(_hour: float) -> void:
	_time_label.text = GameState.get_time_string()
	_day_label.text  = "Day %d" % GameState.current_day

func _on_day_started(day: int) -> void:
	_day_label.text = "Day %d" % day

func _on_phase_changed(phase_int: int) -> void:
	_phase_label.text    = "[%s]" % GameState.get_phase_name()
	_phase_label.modulate = PHASE_COLORS.get(phase_int, Color.WHITE)

func _on_gold_changed(new_amount: int, _delta: int) -> void:
	_gold_label.text = "Gold: %d" % new_amount

func _on_speed_changed(speed: float) -> void:
	_speed_label.text = "Speed: %sx" % str(snappedf(speed, 0.01))

func _on_paused(paused: bool) -> void:
	_speed_label.text = "PAUSED" if paused else "Speed: %sx" % str(snappedf(GameState.sim_speed, 0.01))
	_speed_label.modulate = Color(1.0, 0.5, 0.5) if paused else Color(0.8, 0.8, 0.8)
