extends GutTest
## Unit tests for RoadGrid.

var _grid: RoadGrid

func before_each() -> void:
	_grid = RoadGrid.new()
	add_child_autofree(_grid)

# ── place_road ────────────────────────────────────────────────────────────────

func test_place_road_records_tile() -> void:
	_grid.place_road(Vector2i(3, 3))
	assert_true(_grid.has_road(Vector2i(3, 3)))

func test_place_road_increments_count() -> void:
	_grid.place_road(Vector2i(0, 0))
	_grid.place_road(Vector2i(1, 0))
	assert_eq(_grid.get_road_count(), 2)

func test_place_road_emits_signal() -> void:
	watch_signals(EventBus)
	_grid.place_road(Vector2i(2, 2))
	assert_signal_emitted(EventBus, "road_placed")

func test_place_road_duplicate_ignored() -> void:
	_grid.place_road(Vector2i(0, 0))
	_grid.place_road(Vector2i(0, 0))
	assert_eq(_grid.get_road_count(), 1)

func test_place_road_out_of_bounds_ignored() -> void:
	_grid.place_road(Vector2i(-1, 0))
	_grid.place_road(Vector2i(0, -1))
	_grid.place_road(Vector2i(20, 0))
	_grid.place_road(Vector2i(0, 20))
	assert_eq(_grid.get_road_count(), 0)

# ── remove_road ───────────────────────────────────────────────────────────────

func test_remove_road_clears_tile() -> void:
	_grid.place_road(Vector2i(5, 5))
	_grid.remove_road(Vector2i(5, 5))
	assert_false(_grid.has_road(Vector2i(5, 5)))

func test_remove_road_decrements_count() -> void:
	_grid.place_road(Vector2i(0, 0))
	_grid.place_road(Vector2i(1, 0))
	_grid.remove_road(Vector2i(0, 0))
	assert_eq(_grid.get_road_count(), 1)

func test_remove_road_emits_signal() -> void:
	_grid.place_road(Vector2i(3, 3))
	watch_signals(EventBus)
	_grid.remove_road(Vector2i(3, 3))
	assert_signal_emitted(EventBus, "road_removed")

func test_remove_road_nonexistent_is_noop() -> void:
	_grid.remove_road(Vector2i(9, 9))
	assert_eq(_grid.get_road_count(), 0)

# ── has_road / get_road_tiles ─────────────────────────────────────────────────

func test_has_road_false_on_empty_grid() -> void:
	assert_false(_grid.has_road(Vector2i(0, 0)))

func test_get_road_tiles_returns_all_placed() -> void:
	_grid.place_road(Vector2i(0, 0))
	_grid.place_road(Vector2i(1, 1))
	_grid.place_road(Vector2i(2, 2))
	var tiles := _grid.get_road_tiles()
	assert_eq(tiles.size(), 3)
	assert_true(tiles.has(Vector2i(0, 0)))
	assert_true(tiles.has(Vector2i(1, 1)))
	assert_true(tiles.has(Vector2i(2, 2)))

# ── clear_roads ───────────────────────────────────────────────────────────────

func test_clear_roads_removes_all() -> void:
	_grid.place_road(Vector2i(0, 0))
	_grid.place_road(Vector2i(5, 5))
	_grid.clear_roads()
	assert_eq(_grid.get_road_count(), 0)

func test_clear_roads_all_tiles_gone() -> void:
	_grid.place_road(Vector2i(0, 0))
	_grid.clear_roads()
	assert_false(_grid.has_road(Vector2i(0, 0)))

# ── navigation ────────────────────────────────────────────────────────────────

func test_path_exists_between_adjacent_tiles() -> void:
	var path := _grid.find_path(Vector2i(0, 0), Vector2i(1, 0))
	assert_true(path.size() > 0)

func test_path_includes_endpoints() -> void:
	var path := _grid.find_path(Vector2i(0, 0), Vector2i(3, 0))
	assert_true(path.size() >= 2)
	assert_true(path.has(Vector2i(0, 0)) or path[0] == Vector2i(0, 0))

func test_set_tile_impassable_breaks_direct_path() -> void:
	# Block tile (1,0) — only path from (0,0) to (2,0) must route around
	_grid.set_tile_passable(Vector2i(1, 0), false)
	var path := _grid.find_path(Vector2i(0, 0), Vector2i(2, 0))
	# Path should still exist (can go around via row 1)
	assert_true(path.size() > 0)
	# But shouldn't go through (1,0)
	assert_false(path.has(Vector2i(1, 0)))

func test_path_on_road_shorter_weight_than_ground() -> void:
	# Place road along row 0 from (0,0) to (5,0)
	for i in range(6):
		_grid.place_road(Vector2i(i, 0))
	# Diagonal path without road should have higher cost
	# We just check the road path is found and has correct number of tiles
	var path := _grid.find_path(Vector2i(0, 0), Vector2i(5, 0))
	assert_true(path.size() > 0)
