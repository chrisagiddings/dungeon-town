extends GutTest
## Unit tests for AdventurerSpawner.
## Instantiates a fresh node per test — not the scene's autoload instance.

var _spawner: AdventurerSpawner

func before_each() -> void:
	_spawner = AdventurerSpawner.new()
	add_child_autofree(_spawner)

# ── spawn_adventurer ──────────────────────────────────────────────────────────

func test_spawn_returns_non_empty_id() -> void:
	var id: String = _spawner.spawn_adventurer()
	assert_ne(id, "", "spawn_adventurer should return a non-empty ID")

func test_spawn_increments_active_count() -> void:
	_spawner.spawn_adventurer()
	assert_eq(_spawner.get_active_count(), 1)

func test_spawn_multiple_increments_count() -> void:
	_spawner.spawn_adventurer()
	_spawner.spawn_adventurer()
	_spawner.spawn_adventurer()
	assert_eq(_spawner.get_active_count(), 3)

func test_spawn_ids_are_unique() -> void:
	var id1: String = _spawner.spawn_adventurer()
	var id2: String = _spawner.spawn_adventurer()
	assert_ne(id1, id2, "Each spawn should produce a unique ID")

func test_spawn_emits_adventurer_spawned_signal() -> void:
	watch_signals(EventBus)
	_spawner.spawn_adventurer()
	assert_signal_emitted(EventBus, "adventurer_spawned")

func test_spawn_returns_empty_at_capacity() -> void:
	for i in range(AdventurerSpawner.MAX_ADVENTURERS):
		_spawner.spawn_adventurer()
	var id: String = _spawner.spawn_adventurer()
	assert_eq(id, "", "spawn_adventurer should return empty string when at capacity")

func test_active_count_does_not_exceed_max() -> void:
	for i in range(AdventurerSpawner.MAX_ADVENTURERS + 3):
		_spawner.spawn_adventurer()
	assert_eq(_spawner.get_active_count(), AdventurerSpawner.MAX_ADVENTURERS)

# ── idle tracking ─────────────────────────────────────────────────────────────

func test_new_adventurer_is_idle() -> void:
	_spawner.spawn_adventurer()
	assert_eq(_spawner.get_idle_count(), 1, "Newly spawned adventurer should be idle")

func test_idle_count_decreases_when_entering_dungeon() -> void:
	var id: String = _spawner.spawn_adventurer()
	EventBus.adventurer_entered_dungeon.emit(id)
	assert_eq(_spawner.get_idle_count(), 0)

func test_idle_count_restores_when_adventurer_returns() -> void:
	var id: String = _spawner.spawn_adventurer()
	EventBus.adventurer_entered_dungeon.emit(id)
	EventBus.adventurer_returned.emit(id, {})
	assert_eq(_spawner.get_idle_count(), 1)

func test_get_idle_adventurer_returns_valid_id() -> void:
	_spawner.spawn_adventurer()
	var idle_id: String = _spawner.get_idle_adventurer()
	assert_ne(idle_id, "", "Should return a valid ID when an idle adventurer exists")

func test_get_idle_adventurer_returns_empty_when_all_in_dungeon() -> void:
	var id: String = _spawner.spawn_adventurer()
	EventBus.adventurer_entered_dungeon.emit(id)
	var idle_id: String = _spawner.get_idle_adventurer()
	assert_eq(idle_id, "", "Should return empty when all adventurers are in the dungeon")

func test_unknown_id_in_dungeon_signal_is_ignored() -> void:
	_spawner.spawn_adventurer()
	EventBus.adventurer_entered_dungeon.emit("adv_9999")
	assert_eq(_spawner.get_idle_count(), 1, "Unknown ID should not affect idle count")
