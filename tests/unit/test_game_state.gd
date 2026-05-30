extends GutTest
## Unit tests for GameState autoload.
## Saves and restores all mutable state around each test so autoload
## side-effects don't bleed between test functions.

# ── Saved state ───────────────────────────────────────────────────────────────

var _saved_day:   int
var _saved_hour:  float
var _saved_phase: int
var _saved_paused: bool
var _saved_speed: float

func before_each() -> void:
	_saved_day    = GameState.current_day
	_saved_hour   = GameState.current_hour
	_saved_phase  = GameState.current_phase
	_saved_paused = GameState.is_paused
	_saved_speed  = GameState.sim_speed

func after_each() -> void:
	GameState.current_day   = _saved_day
	GameState.current_hour  = _saved_hour
	GameState.current_phase = _saved_phase
	GameState.is_paused     = _saved_paused
	GameState.sim_speed     = _saved_speed

# ── Time tick ─────────────────────────────────────────────────────────────────

func test_tick_advances_hour_by_half() -> void:
	GameState.current_hour = 6.0
	GameState.advance_one_tick()
	assert_eq(GameState.current_hour, 6.5, "One tick should advance hour by HOURS_PER_TICK (0.5)")

func test_multiple_ticks_accumulate() -> void:
	GameState.current_hour = 6.0
	GameState.advance_one_tick()
	GameState.advance_one_tick()
	assert_eq(GameState.current_hour, 7.0, "Two ticks should advance hour by 1.0")

func test_day_rollover_increments_day() -> void:
	GameState.current_day  = 1
	GameState.current_hour = 23.5
	GameState.advance_one_tick()
	assert_eq(GameState.current_day, 2, "Tick past midnight should increment day")

func test_day_rollover_wraps_hour_to_zero() -> void:
	GameState.current_hour = 23.5
	GameState.advance_one_tick()
	assert_almost_eq(GameState.current_hour, 0.0, 0.001, "Hour should wrap to 0.0 after midnight")

func test_tick_emits_time_tick_signal() -> void:
	watch_signals(EventBus)
	GameState.advance_one_tick()
	assert_signal_emitted(EventBus, "time_tick")

func test_day_rollover_emits_day_started() -> void:
	GameState.current_hour = 23.5
	watch_signals(EventBus)
	GameState.advance_one_tick()
	assert_signal_emitted(EventBus, "day_started")

# ── Phase transitions ─────────────────────────────────────────────────────────

func test_phase_morning_at_hour_6() -> void:
	GameState.current_hour  = 5.5
	GameState.current_phase = GameState.Phase.NIGHT
	GameState.advance_one_tick()  # moves to 6.0
	assert_eq(GameState.current_phase, GameState.Phase.MORNING, "Hour 6.0 should be MORNING")

func test_phase_day_at_hour_9() -> void:
	GameState.current_hour  = 8.5
	GameState.current_phase = GameState.Phase.MORNING
	GameState.advance_one_tick()  # moves to 9.0
	assert_eq(GameState.current_phase, GameState.Phase.DAY, "Hour 9.0 should be DAY")

func test_phase_evening_at_hour_18() -> void:
	GameState.current_hour  = 17.5
	GameState.current_phase = GameState.Phase.DAY
	GameState.advance_one_tick()  # moves to 18.0
	assert_eq(GameState.current_phase, GameState.Phase.EVENING, "Hour 18.0 should be EVENING")

func test_phase_night_at_hour_21() -> void:
	GameState.current_hour  = 20.5
	GameState.current_phase = GameState.Phase.EVENING
	GameState.advance_one_tick()  # moves to 21.0
	assert_eq(GameState.current_phase, GameState.Phase.NIGHT, "Hour 21.0 should be NIGHT")

func test_phase_change_emits_signal() -> void:
	GameState.current_hour  = 8.5
	GameState.current_phase = GameState.Phase.MORNING
	watch_signals(EventBus)
	GameState.advance_one_tick()  # crosses into DAY
	assert_signal_emitted(EventBus, "phase_changed")

func test_no_phase_signal_when_phase_unchanged() -> void:
	GameState.current_hour  = 9.0
	GameState.current_phase = GameState.Phase.DAY
	watch_signals(EventBus)
	GameState.advance_one_tick()  # stays in DAY
	assert_signal_not_emitted(EventBus, "phase_changed")

# ── Pause ─────────────────────────────────────────────────────────────────────

func test_set_paused_sets_flag() -> void:
	GameState.set_paused(true)
	assert_true(GameState.is_paused)

func test_set_unpaused_clears_flag() -> void:
	GameState.is_paused = true
	GameState.set_paused(false)
	assert_false(GameState.is_paused)

func test_set_paused_emits_signal() -> void:
	watch_signals(EventBus)
	GameState.set_paused(true)
	assert_signal_emitted(EventBus, "sim_paused")

# ── Sim speed ─────────────────────────────────────────────────────────────────

func test_set_sim_speed_applies_value() -> void:
	GameState.set_sim_speed(2.0)
	assert_eq(GameState.sim_speed, 2.0)

func test_set_sim_speed_clamps_below_min() -> void:
	GameState.set_sim_speed(0.0)
	assert_eq(GameState.sim_speed, 0.25, "Speed below 0.25 should clamp to 0.25")

func test_set_sim_speed_clamps_above_max() -> void:
	GameState.set_sim_speed(999.0)
	assert_eq(GameState.sim_speed, 8.0, "Speed above 8.0 should clamp to 8.0")

func test_set_sim_speed_emits_signal() -> void:
	watch_signals(EventBus)
	GameState.set_sim_speed(4.0)
	assert_signal_emitted(EventBus, "sim_speed_changed")

# ── get_time_string ───────────────────────────────────────────────────────────

func test_time_string_morning() -> void:
	GameState.current_hour = 8.5
	assert_eq(GameState.get_time_string(), "08:30 AM")

func test_time_string_noon() -> void:
	GameState.current_hour = 12.0
	assert_eq(GameState.get_time_string(), "12:00 PM")

func test_time_string_midnight() -> void:
	GameState.current_hour = 0.0
	assert_eq(GameState.get_time_string(), "12:00 AM")

func test_time_string_just_before_noon() -> void:
	GameState.current_hour = 11.5
	assert_eq(GameState.get_time_string(), "11:30 AM")

func test_time_string_evening() -> void:
	GameState.current_hour = 21.0
	assert_eq(GameState.get_time_string(), "09:00 PM")
