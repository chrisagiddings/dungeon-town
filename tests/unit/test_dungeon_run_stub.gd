extends GutTest
## Unit tests for DungeonRunStub.
## Async run completion is not tested here — that requires a real timer and
## belongs in integration tests. These tests cover all synchronous behaviour.

var _stub: DungeonRunStub

func before_each() -> void:
	_stub = DungeonRunStub.new()
	add_child_autofree(_stub)

# ── start_run (synchronous effects) ──────────────────────────────────────────

func test_start_run_emits_adventurer_entered_dungeon() -> void:
	watch_signals(EventBus)
	_stub.start_run("adv_0001")
	assert_signal_emitted(EventBus, "adventurer_entered_dungeon")

func test_start_run_emits_dungeon_run_started() -> void:
	watch_signals(EventBus)
	_stub.start_run("adv_0001")
	assert_signal_emitted(EventBus, "dungeon_run_started")

func test_start_run_increments_active_count() -> void:
	_stub.start_run("adv_0001")
	assert_eq(_stub.get_active_run_count(), 1)

func test_start_run_multiple_runs_tracked() -> void:
	_stub.start_run("adv_0001")
	_stub.start_run("adv_0002")
	assert_eq(_stub.get_active_run_count(), 2)

func test_duplicate_run_is_rejected() -> void:
	_stub.start_run("adv_0001")
	var count_before: int = _stub.get_active_run_count()
	_stub.start_run("adv_0001")
	assert_eq(_stub.get_active_run_count(), count_before, "Duplicate start_run should not add a second entry")

func test_duplicate_run_does_not_emit_entered_dungeon_twice() -> void:
	watch_signals(EventBus)
	_stub.start_run("adv_0001")
	_stub.start_run("adv_0001")
	assert_signal_emit_count(EventBus, "adventurer_entered_dungeon", 1)

# ── success rate ──────────────────────────────────────────────────────────────

func test_success_rate_zero_with_no_runs() -> void:
	assert_eq(_stub.get_success_rate(), 0.0, "Success rate should be 0.0 before any runs complete")

# ── active count ──────────────────────────────────────────────────────────────

func test_active_count_starts_at_zero() -> void:
	assert_eq(_stub.get_active_run_count(), 0)

func test_active_count_with_different_adventurers() -> void:
	_stub.start_run("adv_0001")
	_stub.start_run("adv_0002")
	_stub.start_run("adv_0003")
	assert_eq(_stub.get_active_run_count(), 3)
