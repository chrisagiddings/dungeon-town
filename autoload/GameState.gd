extends Node
## GameState — authoritative source for simulation state.
## Owns the time tick loop and phase transitions.

enum Phase { MORNING, DAY, EVENING, NIGHT }

# ── Constants ─────────────────────────────────────────────────────────────────
const HOURS_PER_DAY: int = 24
const TICK_REAL_SECONDS: float = 1.0   ## Real seconds per game tick at 1× speed
const HOURS_PER_TICK: float = 0.5      ## Game hours advanced per tick

# ── State ─────────────────────────────────────────────────────────────────────
var current_day: int = 1
var current_hour: float = 6.0          ## Starts at 6 AM
var current_phase: Phase = Phase.MORNING
var is_paused: bool = false
var sim_speed: float = 1.0

var _tick_accumulator: float = 0.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if is_paused:
		return
	_tick_accumulator += delta * sim_speed
	if _tick_accumulator >= TICK_REAL_SECONDS:
		_tick_accumulator -= TICK_REAL_SECONDS
		_advance_time()

# ── Public API ────────────────────────────────────────────────────────────────

func advance_one_tick() -> void:
	## Manually advance time by one tick (used by debug panel).
	_advance_time()

func set_paused(paused: bool) -> void:
	is_paused = paused
	EventBus.sim_paused.emit(paused)

func set_sim_speed(speed: float) -> void:
	sim_speed = clamp(speed, 0.25, 8.0)
	EventBus.sim_speed_changed.emit(sim_speed)

func get_time_string() -> String:
	var hour: int = int(current_hour)
	var minutes: int = int((current_hour - float(hour)) * 60.0)
	var period: String = "AM" if hour < 12 else "PM"
	var display_hour: int = hour % 12
	if display_hour == 0:
		display_hour = 12
	return "%02d:%02d %s" % [display_hour, minutes, period]

func get_phase_name() -> String:
	match current_phase:
		Phase.MORNING: return "Morning"
		Phase.DAY:     return "Day"
		Phase.EVENING: return "Evening"
		Phase.NIGHT:   return "Night"
	return "Unknown"

# ── Internal ──────────────────────────────────────────────────────────────────

func _advance_time() -> void:
	current_hour += HOURS_PER_TICK
	if current_hour >= float(HOURS_PER_DAY):
		current_hour -= float(HOURS_PER_DAY)
		current_day += 1
		EventBus.day_started.emit(current_day)
	_update_phase()
	EventBus.time_tick.emit(current_hour)

func _update_phase() -> void:
	var new_phase: Phase
	if current_hour >= 6.0 and current_hour < 9.0:
		new_phase = Phase.MORNING
	elif current_hour >= 9.0 and current_hour < 18.0:
		new_phase = Phase.DAY
	elif current_hour >= 18.0 and current_hour < 21.0:
		new_phase = Phase.EVENING
	else:
		new_phase = Phase.NIGHT

	if new_phase != current_phase:
		current_phase = new_phase
		EventBus.phase_changed.emit(int(current_phase))
