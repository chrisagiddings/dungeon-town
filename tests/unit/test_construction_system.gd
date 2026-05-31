extends GutTest
## Unit tests for the construction timer system (new placements via UpgradeManager).

var _manager: UpgradeManager
var _grid:    BuildingGrid
var _saved_day:  int
var _saved_gold: int

func before_each() -> void:
	_saved_day  = GameState.current_day
	_saved_gold = EconomyState.gold
	_grid    = BuildingGrid.new()
	_manager = UpgradeManager.new()
	_manager._grid = _grid
	add_child_autofree(_grid)
	add_child_autofree(_manager)

func after_each() -> void:
	GameState.current_day  = _saved_day
	EconomyState.gold      = _saved_gold

# ── start_new_construction ────────────────────────────────────────────────────

func test_construction_marks_building_under_construction() -> void:
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg", "civic")
	_manager.start_new_construction(iid, 3)
	assert_true(_manager.is_under_construction(iid))

func test_construction_emits_started_signal() -> void:
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg", "civic")
	watch_signals(EventBus)
	_manager.start_new_construction(iid, 2)
	assert_signal_emitted(EventBus, "building_construction_started")

func test_construction_days_remaining_correct() -> void:
	GameState.current_day = 5
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg", "civic")
	_manager.start_new_construction(iid, 3)
	assert_eq(_manager.days_remaining(iid), 3)

func test_construction_duplicate_start_ignored() -> void:
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg", "civic")
	_manager.start_new_construction(iid, 2)
	_manager.start_new_construction(iid, 5)  # should be ignored
	assert_eq(_manager.days_remaining(iid), 2)

func test_construction_not_started_for_unknown_id() -> void:
	assert_false(_manager.is_under_construction("nonexistent"))

# ── completion ────────────────────────────────────────────────────────────────

func test_construction_completes_on_correct_day() -> void:
	GameState.current_day = 1
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg", "civic")
	_manager.start_new_construction(iid, 2)
	# Simulate day 3 arriving (1 + 2)
	GameState.current_day = 3
	_manager._on_day_started(3)
	assert_false(_manager.is_under_construction(iid))

func test_construction_emits_completed_signal() -> void:
	GameState.current_day = 1
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg", "civic")
	_manager.start_new_construction(iid, 1)
	watch_signals(EventBus)
	GameState.current_day = 2
	_manager._on_day_started(2)
	assert_signal_emitted(EventBus, "building_construction_completed")

func test_construction_does_not_complete_before_due_day() -> void:
	GameState.current_day = 1
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg", "civic")
	_manager.start_new_construction(iid, 5)
	GameState.current_day = 3
	_manager._on_day_started(3)
	assert_true(_manager.is_under_construction(iid))

func test_building_remains_in_grid_after_completion() -> void:
	GameState.current_day = 1
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg", "civic")
	_manager.start_new_construction(iid, 1)
	GameState.current_day = 2
	_manager._on_day_started(2)
	# Building should still be in the grid (unlike upgrades which swap)
	assert_true(_grid.is_tile_occupied(Vector2i(0, 0)))

# ── progress ─────────────────────────────────────────────────────────────────

func test_progress_zero_at_start() -> void:
	GameState.current_day = 1
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg", "civic")
	_manager.start_new_construction(iid, 4)
	assert_almost_eq(_manager.construction_progress(iid), 0.0, 0.01)

func test_progress_increases_over_time() -> void:
	GameState.current_day = 1
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg", "civic")
	_manager.start_new_construction(iid, 4)
	GameState.current_day = 3  # 2 of 4 days elapsed
	assert_almost_eq(_manager.construction_progress(iid), 0.5, 0.01)

func test_progress_one_for_unknown_instance() -> void:
	assert_almost_eq(_manager.construction_progress("nonexistent"), 1.0, 0.01)

func test_total_days_returns_registered_value() -> void:
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg", "civic")
	_manager.start_new_construction(iid, 7)
	assert_eq(_manager.total_days(iid), 7)

# ── upgrade construction still works ─────────────────────────────────────────

func test_upgrade_and_new_build_tracked_separately() -> void:
	EconomyState.gold = 9999
	var build_iid   := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "lodging_t1", "hospitality")
	var upgrade_iid := _grid.reserve(Vector2i(5, 5), Vector2i(2, 2), "lodging_t1", "hospitality")
	var data := DataRegistry.get_building("lodging_t1") as BuildingData
	if data == null:
		return  # DataRegistry not seeded — skip
	_manager.start_new_construction(build_iid, 2)
	_manager.start_upgrade(upgrade_iid, data)
	assert_true(_manager.is_under_construction(build_iid))
	assert_true(_manager.is_under_construction(upgrade_iid))
	assert_eq(_manager.get_construction_ids().size(), 2)

# ── construction_days in BuildingData ────────────────────────────────────────

func test_lodging_t1_has_construction_days() -> void:
	var data := DataRegistry.get_building("lodging_t1") as BuildingData
	if data == null:
		return
	assert_true(data.construction_days > 0, "lodging_t1 should require construction time")

func test_mayor_t1_has_longer_construction_than_lodging() -> void:
	var lodging := DataRegistry.get_building("lodging_t1") as BuildingData
	var mayor   := DataRegistry.get_building("mayor_t1")   as BuildingData
	if lodging == null or mayor == null:
		return
	assert_true(mayor.construction_days > lodging.construction_days,
		"Mayor's Hall should take longer to build than a Tent Camp")

func test_store_t1_is_immediate() -> void:
	var data := DataRegistry.get_building("store_t1") as BuildingData
	if data == null:
		return
	assert_eq(data.construction_days, 0, "General Store should be immediate (0 days)")
