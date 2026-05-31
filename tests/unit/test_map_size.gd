extends GutTest
## Unit tests for map size configuration and entrance size selection.

var _saved_map_size:  int
var _saved_grid_size: int
var _saved_entrance_size:   Vector2i
var _saved_entrance_origin: Vector2i

func before_each() -> void:
	_saved_map_size        = GameState.map_size
	_saved_grid_size       = GameState.grid_size
	_saved_entrance_size   = GameState.dungeon_entrance_size
	_saved_entrance_origin = GameState.dungeon_entrance_origin

func after_each() -> void:
	GameState.map_size              = _saved_map_size
	GameState.grid_size             = _saved_grid_size
	GameState.dungeon_entrance_size = _saved_entrance_size
	GameState.dungeon_entrance_origin = _saved_entrance_origin

# ── GameState map size ────────────────────────────────────────────────────────

func test_set_map_size_small_sets_grid_16() -> void:
	GameState.set_map_size(GameState.MapSize.SMALL)
	assert_eq(GameState.grid_size, 16)

func test_set_map_size_medium_sets_grid_20() -> void:
	GameState.set_map_size(GameState.MapSize.MEDIUM)
	assert_eq(GameState.grid_size, 20)

func test_set_map_size_large_sets_grid_28() -> void:
	GameState.set_map_size(GameState.MapSize.LARGE)
	assert_eq(GameState.grid_size, 28)

func test_get_map_size_name_small() -> void:
	GameState.set_map_size(GameState.MapSize.SMALL)
	assert_true(GameState.get_map_size_name().begins_with("Small"))

func test_get_map_size_name_medium() -> void:
	GameState.set_map_size(GameState.MapSize.MEDIUM)
	assert_true(GameState.get_map_size_name().begins_with("Medium"))

func test_get_map_size_name_large() -> void:
	GameState.set_map_size(GameState.MapSize.LARGE)
	assert_true(GameState.get_map_size_name().begins_with("Large"))

# ── MAP_ENTRANCE_SIZES ────────────────────────────────────────────────────────

func test_small_entrance_sizes_are_1x1_or_2x2() -> void:
	var opts: Array = GameState.MAP_ENTRANCE_SIZES[GameState.MapSize.SMALL]
	assert_true(opts.has(Vector2i(1, 1)))
	assert_true(opts.has(Vector2i(2, 2)))

func test_medium_entrance_sizes_are_2x2_or_3x3() -> void:
	var opts: Array = GameState.MAP_ENTRANCE_SIZES[GameState.MapSize.MEDIUM]
	assert_true(opts.has(Vector2i(2, 2)))
	assert_true(opts.has(Vector2i(3, 3)))

func test_large_entrance_sizes_are_3x3_or_5x5() -> void:
	var opts: Array = GameState.MAP_ENTRANCE_SIZES[GameState.MapSize.LARGE]
	assert_true(opts.has(Vector2i(3, 3)))
	assert_true(opts.has(Vector2i(5, 5)))

# ── DungeonEntranceManager._pick_entrance_size ────────────────────────────────

func test_pick_size_for_small_map_is_valid() -> void:
	GameState.set_map_size(GameState.MapSize.SMALL)
	var grid   := BuildingGrid.new()
	var mgr    := DungeonEntranceManager.new()
	mgr._grid  = grid
	add_child_autofree(grid)
	add_child_autofree(mgr)
	var valid: Array = GameState.MAP_ENTRANCE_SIZES[GameState.MapSize.SMALL]
	for i in range(10):
		var picked := mgr._pick_entrance_size()
		assert_true(valid.has(picked),
			"Small map picked invalid size %s" % picked)

func test_pick_size_for_large_map_is_valid() -> void:
	GameState.set_map_size(GameState.MapSize.LARGE)
	var grid  := BuildingGrid.new()
	var mgr   := DungeonEntranceManager.new()
	mgr._grid = grid
	add_child_autofree(grid)
	add_child_autofree(mgr)
	var valid: Array = GameState.MAP_ENTRANCE_SIZES[GameState.MapSize.LARGE]
	for i in range(10):
		var picked := mgr._pick_entrance_size()
		assert_true(valid.has(picked),
			"Large map picked invalid size %s" % picked)

# ── BuildingGrid dynamic GRID_SIZE ───────────────────────────────────────────

func test_building_grid_respects_updated_grid_size() -> void:
	GameState.set_map_size(GameState.MapSize.SMALL)
	var grid := BuildingGrid.new()
	add_child_autofree(grid)
	grid.update_grid_size()
	# On a 16×16 grid, tile (15,15) is the last valid corner
	assert_true(grid.is_in_bounds(Vector2i(15, 15), Vector2i(1, 1)))
	# Tile 16 is out of bounds on a 16-wide grid
	assert_false(grid.is_in_bounds(Vector2i(16, 0), Vector2i(1, 1)))

func test_building_grid_large_map_allows_tile_27() -> void:
	GameState.set_map_size(GameState.MapSize.LARGE)
	var grid := BuildingGrid.new()
	add_child_autofree(grid)
	grid.update_grid_size()
	assert_true(grid.is_in_bounds(Vector2i(25, 25), Vector2i(2, 2)))
	assert_false(grid.is_in_bounds(Vector2i(27, 0), Vector2i(2, 2)))

# ── save/load round-trip ──────────────────────────────────────────────────────

func test_map_size_survives_save_load() -> void:
	GameState.set_map_size(GameState.MapSize.LARGE)
	SaveSystem.save(5)
	GameState.set_map_size(GameState.MapSize.SMALL)
	SaveSystem.load_slot(5)
	assert_eq(GameState.map_size, GameState.MapSize.LARGE)
	assert_eq(GameState.grid_size, 28)
	SaveSystem.delete_save(5)
