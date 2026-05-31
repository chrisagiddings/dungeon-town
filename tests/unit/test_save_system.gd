extends GutTest
## Unit tests for SaveSystem.
## Uses a dedicated test slot (slot 5) to avoid clobbering real saves.
## Cleans up after itself.

const TEST_SLOT: int = 5

var _saved_day:      int
var _saved_hour:     float
var _saved_gold:     int
var _saved_income:   int
var _saved_expenses: int

func before_each() -> void:
	_saved_day      = GameState.current_day
	_saved_hour     = GameState.current_hour
	_saved_gold     = EconomyState.gold
	_saved_income   = EconomyState.total_income
	_saved_expenses = EconomyState.total_expenses

func after_each() -> void:
	GameState.current_day   = _saved_day
	GameState.current_hour  = _saved_hour
	EconomyState.gold           = _saved_gold
	EconomyState.total_income   = _saved_income
	EconomyState.total_expenses = _saved_expenses
	SaveSystem.delete_save(TEST_SLOT)

# ── has_save ──────────────────────────────────────────────────────────────────

func test_has_save_false_before_any_save() -> void:
	SaveSystem.delete_save(TEST_SLOT)
	assert_false(SaveSystem.has_save(TEST_SLOT))

func test_has_save_true_after_save() -> void:
	SaveSystem.save(TEST_SLOT)
	assert_true(SaveSystem.has_save(TEST_SLOT))

# ── save / get_save_info ──────────────────────────────────────────────────────

func test_save_persists_game_day() -> void:
	GameState.current_day = 42
	SaveSystem.save(TEST_SLOT)
	var info := SaveSystem.get_save_info(TEST_SLOT)
	assert_eq(info.get("day", -1), 42)

func test_save_persists_gold() -> void:
	EconomyState.gold = 1337
	SaveSystem.save(TEST_SLOT)
	var info := SaveSystem.get_save_info(TEST_SLOT)
	assert_eq(info.get("gold", -1), 1337)

func test_save_emits_game_saved_signal() -> void:
	watch_signals(EventBus)
	SaveSystem.save(TEST_SLOT)
	assert_signal_emitted(EventBus, "game_saved")

func test_get_save_info_empty_when_no_save() -> void:
	SaveSystem.delete_save(TEST_SLOT)
	var info := SaveSystem.get_save_info(TEST_SLOT)
	assert_true(info.is_empty())

# ── load ──────────────────────────────────────────────────────────────────────

func test_load_restores_game_day() -> void:
	GameState.current_day = 17
	SaveSystem.save(TEST_SLOT)
	GameState.current_day = 1
	SaveSystem.load_slot(TEST_SLOT)
	assert_eq(GameState.current_day, 17)

func test_load_restores_gold() -> void:
	EconomyState.gold = 999
	SaveSystem.save(TEST_SLOT)
	EconomyState.gold = 0
	SaveSystem.load_slot(TEST_SLOT)
	assert_eq(EconomyState.gold, 999)

func test_load_restores_game_hour() -> void:
	GameState.current_hour = 14.5
	SaveSystem.save(TEST_SLOT)
	GameState.current_hour = 6.0
	SaveSystem.load_slot(TEST_SLOT)
	assert_almost_eq(GameState.current_hour, 14.5, 0.001)

func test_load_emits_game_loaded_signal() -> void:
	SaveSystem.save(TEST_SLOT)
	watch_signals(EventBus)
	SaveSystem.load_slot(TEST_SLOT)
	assert_signal_emitted(EventBus, "game_loaded")

func test_load_returns_false_when_no_save() -> void:
	SaveSystem.delete_save(TEST_SLOT)
	var result := SaveSystem.load_slot(TEST_SLOT)
	assert_false(result)

# ── BuildingGrid restoration (unit-level, no scene tree needed) ───────────────

func test_restore_placement_occupies_correct_tiles() -> void:
	var grid := BuildingGrid.new()
	add_child_autofree(grid)
	grid.restore_placement("lodging_t1_0001", Vector2i(2, 3), Vector2i(2, 2), "lodging_t1", "hospitality")
	assert_true(grid.is_tile_occupied(Vector2i(2, 3)))
	assert_true(grid.is_tile_occupied(Vector2i(3, 3)))
	assert_true(grid.is_tile_occupied(Vector2i(2, 4)))
	assert_true(grid.is_tile_occupied(Vector2i(3, 4)))

func test_restore_placement_preserves_instance_id() -> void:
	var grid := BuildingGrid.new()
	add_child_autofree(grid)
	grid.restore_placement("farm_t1_0042", Vector2i(0, 0), Vector2i(3, 3), "farm_t1", "production")
	var occ := grid.get_occupant(Vector2i(0, 0))
	assert_eq(occ, "farm_t1_0042")

func test_restore_placement_preserves_data_id() -> void:
	var grid := BuildingGrid.new()
	add_child_autofree(grid)
	grid.restore_placement("tavern_t1_0007", Vector2i(0, 0), Vector2i(2, 2), "tavern_t1", "hospitality")
	assert_eq(grid.get_data_id_for_instance("tavern_t1_0007"), "tavern_t1")

func test_multiple_placements_restored_independently() -> void:
	var grid := BuildingGrid.new()
	add_child_autofree(grid)
	grid.restore_placement("bldg_a_0001", Vector2i(0, 0), Vector2i(2, 2), "lodging_t1", "hospitality")
	grid.restore_placement("bldg_b_0002", Vector2i(5, 5), Vector2i(3, 3), "farm_t1", "production")
	assert_eq(grid.get_placement_count(), 2)
	assert_eq(grid.get_occupant(Vector2i(0, 0)), "bldg_a_0001")
	assert_eq(grid.get_occupant(Vector2i(5, 5)), "bldg_b_0002")

func test_instance_counter_restored_correctly() -> void:
	var grid := BuildingGrid.new()
	add_child_autofree(grid)
	grid.set_instance_counter(99)
	assert_eq(grid.get_instance_counter(), 99)

# ── roads serialization (unit-level) ─────────────────────────────────────────

func test_road_tiles_survive_clear_and_restore() -> void:
	var road_grid := RoadGrid.new()
	add_child_autofree(road_grid)
	road_grid.place_road(Vector2i(4, 4))
	road_grid.place_road(Vector2i(5, 4))
	road_grid.place_road(Vector2i(6, 4))
	var saved_tiles := road_grid.get_road_tiles().duplicate()
	road_grid.clear_roads()
	for tile in saved_tiles:
		road_grid.place_road(tile)
	assert_true(road_grid.has_road(Vector2i(4, 4)))
	assert_true(road_grid.has_road(Vector2i(5, 4)))
	assert_true(road_grid.has_road(Vector2i(6, 4)))
	assert_eq(road_grid.get_road_count(), 3)

# ── delete_save ───────────────────────────────────────────────────────────────

func test_delete_save_removes_file() -> void:
	SaveSystem.save(TEST_SLOT)
	assert_true(SaveSystem.has_save(TEST_SLOT))
	SaveSystem.delete_save(TEST_SLOT)
	assert_false(SaveSystem.has_save(TEST_SLOT))
