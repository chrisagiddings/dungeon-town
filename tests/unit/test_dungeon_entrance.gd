extends GutTest
## Unit tests for dungeon entrance placement logic.

var _manager: DungeonEntranceManager
var _grid:    BuildingGrid
var _saved_origin: Vector2i
var _saved_size:   Vector2i

func before_each() -> void:
	_saved_origin = GameState.dungeon_entrance_origin
	_saved_size   = GameState.dungeon_entrance_size
	_grid    = BuildingGrid.new()
	_manager = DungeonEntranceManager.new()
	_manager._grid = _grid
	add_child_autofree(_grid)
	add_child_autofree(_manager)

func after_each() -> void:
	GameState.dungeon_entrance_origin = _saved_origin
	GameState.dungeon_entrance_size   = _saved_size

# ── _place_randomly ───────────────────────────────────────────────────────────

func test_random_placement_sets_non_negative_origin() -> void:
	GameState.dungeon_entrance_origin = Vector2i(-1, -1)
	GameState.dungeon_entrance_size   = Vector2i(3, 3)
	_manager._place_randomly()
	assert_true(GameState.dungeon_entrance_origin.x >= 0)
	assert_true(GameState.dungeon_entrance_origin.y >= 0)

func test_random_placement_respects_margin() -> void:
	GameState.dungeon_entrance_origin = Vector2i(-1, -1)
	GameState.dungeon_entrance_size   = Vector2i(3, 3)
	_manager._place_randomly()
	var o: Vector2i = GameState.dungeon_entrance_origin
	var margin: int = 3 + 2  # max(footprint) + 2
	assert_true(o.x >= margin, "origin.x %d should be >= margin %d" % [o.x, margin])
	assert_true(o.y >= margin, "origin.y %d should be >= margin %d" % [o.y, margin])

func test_random_placement_stays_inside_grid() -> void:
	GameState.dungeon_entrance_size = Vector2i(3, 3)
	# Run 20 times to catch any out-of-bounds
	for i in range(20):
		GameState.dungeon_entrance_origin = Vector2i(-1, -1)
		_manager._place_randomly()
		var o: Vector2i = GameState.dungeon_entrance_origin
		var s: Vector2i = GameState.dungeon_entrance_size
		assert_true(o.x + s.x <= GameState.grid_size,
			"Entrance x overflows grid on iteration %d (origin=%s)" % [i, o])
		assert_true(o.y + s.y <= GameState.grid_size,
			"Entrance y overflows grid on iteration %d (origin=%s)" % [i, o])

func test_random_placement_emits_signal() -> void:
	GameState.dungeon_entrance_origin = Vector2i(-1, -1)
	GameState.dungeon_entrance_size   = Vector2i(3, 3)
	watch_signals(EventBus)
	_manager._place_randomly()
	assert_signal_emitted(EventBus, "dungeon_entrance_placed")

func test_random_placement_reserves_tiles_in_grid() -> void:
	_grid.clear()
	GameState.dungeon_entrance_origin = Vector2i(-1, -1)
	_manager._place_randomly()
	var o: Vector2i = GameState.dungeon_entrance_origin
	var s: Vector2i = GameState.dungeon_entrance_size
	assert_true(_grid.is_tile_occupied(o),
		"Origin tile should be reserved after placement")
	assert_true(_grid.is_tile_occupied(o + s - Vector2i(1, 1)),
		"Bottom-right tile of footprint should be reserved")

# ── _reserve_current ──────────────────────────────────────────────────────────

func test_reserve_current_marks_all_footprint_tiles() -> void:
	_grid.clear()
	GameState.dungeon_entrance_origin = Vector2i(5, 5)
	GameState.dungeon_entrance_size   = Vector2i(3, 3)
	_manager._reserve_current()
	for row in range(3):
		for col in range(3):
			assert_true(_grid.is_tile_occupied(Vector2i(5 + col, 5 + row)),
				"Tile (%d,%d) should be occupied" % [5 + col, 5 + row])

func test_reserve_current_does_not_double_reserve() -> void:
	_grid.clear()
	GameState.dungeon_entrance_origin = Vector2i(5, 5)
	GameState.dungeon_entrance_size   = Vector2i(2, 2)
	_manager._reserve_current()
	_manager._reserve_current()  # second call should be a no-op
	assert_eq(_grid.get_placement_count(), 1)

# ── margin formula ────────────────────────────────────────────────────────────

func test_1x1_entrance_has_minimum_3_tile_margin() -> void:
	GameState.dungeon_entrance_size = Vector2i(1, 1)
	for i in range(10):
		GameState.dungeon_entrance_origin = Vector2i(-1, -1)
		_manager._place_randomly()
		var o: Vector2i = GameState.dungeon_entrance_origin
		assert_true(o.x >= 3 and o.y >= 3,
			"1x1 entrance should have margin >= 3, got %s" % o)

func test_2x2_entrance_has_minimum_4_tile_margin() -> void:
	GameState.dungeon_entrance_size = Vector2i(2, 2)
	for i in range(10):
		GameState.dungeon_entrance_origin = Vector2i(-1, -1)
		_manager._place_randomly()
		var o: Vector2i = GameState.dungeon_entrance_origin
		assert_true(o.x >= 4 and o.y >= 4,
			"2x2 entrance should have margin >= 4, got %s" % o)

# ── save/load round-trip ──────────────────────────────────────────────────────

func test_entrance_origin_survives_save_load() -> void:
	GameState.dungeon_entrance_origin = Vector2i(7, 8)
	GameState.dungeon_entrance_size   = Vector2i(3, 3)
	SaveSystem.save(5)
	GameState.dungeon_entrance_origin = Vector2i(-1, -1)
	SaveSystem.load_slot(5)
	assert_eq(GameState.dungeon_entrance_origin, Vector2i(7, 8))
	SaveSystem.delete_save(5)

func test_entrance_size_survives_save_load() -> void:
	GameState.dungeon_entrance_origin = Vector2i(5, 5)
	GameState.dungeon_entrance_size   = Vector2i(2, 2)
	SaveSystem.save(5)
	GameState.dungeon_entrance_size = Vector2i(3, 3)
	SaveSystem.load_slot(5)
	assert_eq(GameState.dungeon_entrance_size, Vector2i(2, 2))
	SaveSystem.delete_save(5)
