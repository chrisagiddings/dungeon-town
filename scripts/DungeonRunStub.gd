extends Node
class_name DungeonRunStub
## Simulates a dungeon run: adventurer enters, waits, returns with loot.
## Uses async (await) so multiple runs can overlap.
## In M1, this becomes a proper state machine driving actual combat.

# ── Constants ─────────────────────────────────────────────────────────────────
const RUN_DURATION_SECONDS: float = 10.0
const GOLD_MIN: int = 15
const GOLD_MAX: int = 75
const FAILURE_CHANCE: float = 0.15  ## 15% chance of failed run (no gold)

# ── State ─────────────────────────────────────────────────────────────────────
var _active_runs: Dictionary = {}  ## { adventurer_id: String → true }
var _total_runs: int = 0
var _successful_runs: int = 0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.debug_log_message.emit("DungeonRunStub: ready")

# ── Public API ────────────────────────────────────────────────────────────────

func start_run(adventurer_id: String) -> void:
	## Begin a dungeon run. Non-blocking — uses await internally.
	if adventurer_id in _active_runs:
		EventBus.debug_log_message.emit(
			"Run refused: %s is already in the dungeon" % adventurer_id
		)
		return

	_active_runs[adventurer_id] = true
	_total_runs += 1

	EventBus.adventurer_entered_dungeon.emit(adventurer_id)
	EventBus.dungeon_run_started.emit(adventurer_id)
	EventBus.debug_log_message.emit(
		"Dungeon run started: %s  (%.0fs)" % [adventurer_id, RUN_DURATION_SECONDS]
	)

	# Non-blocking wait — this coroutine suspends while the scene keeps running
	await get_tree().create_timer(RUN_DURATION_SECONDS).timeout
	_finish_run(adventurer_id)

func get_active_run_count() -> int:
	return _active_runs.size()

func get_success_rate() -> float:
	if _total_runs == 0:
		return 0.0
	return float(_successful_runs) / float(_total_runs)

# ── Internal ──────────────────────────────────────────────────────────────────

func _finish_run(adventurer_id: String) -> void:
	if not adventurer_id in _active_runs:
		return  # Was cancelled or double-called
	_active_runs.erase(adventurer_id)

	var success: bool = randf() > FAILURE_CHANCE
	var gold_earned: int = 0

	if success:
		gold_earned = randi_range(GOLD_MIN, GOLD_MAX)
		EconomyState.add_gold(gold_earned, "dungeon:%s" % adventurer_id)
		_successful_runs += 1

	var result: Dictionary = {
		"adventurer_id": adventurer_id,
		"success":       success,
		"gold_earned":   gold_earned,
	}

	EventBus.adventurer_returned.emit(adventurer_id, result)
	EventBus.dungeon_run_completed.emit(adventurer_id, result)

	var status_str: String = "+%dg" % gold_earned if success else "FAILED"
	EventBus.debug_log_message.emit(
		"Run complete: %s [%s]" % [adventurer_id, status_str]
	)
