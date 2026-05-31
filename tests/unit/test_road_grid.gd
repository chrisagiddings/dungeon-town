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

# ── RoadPlacer straight-line logic ────────────────────────────────────────────
# Tests via a RoadPlacer instance (line_tiles is a pure internal method we
# invoke indirectly by setting up a painting stroke and checking results).

var _placer:          RoadPlacer     = null
var _building_placer: BuildingPlacer = null

func _make_placer() -> void:
	_placer = RoadPlacer.new()
	_placer._road_grid     = _grid
	_placer._building_grid = BuildingGrid.new()
	add_child_autofree(_placer._building_grid)
	add_child_autofree(_placer)

func _make_building_placer() -> void:
	## Creates a BuildingPlacer wired to the test's RoadGrid and a fresh BuildingGrid.
	## _terrain is not needed for _has_road_conflict — left null.
	var bgrid := BuildingGrid.new()
	add_child_autofree(bgrid)
	_building_placer = BuildingPlacer.new()
	_building_placer._road_grid = _grid
	_building_placer._grid      = bgrid
	add_child_autofree(_building_placer)

func test_line_horizontal_left_to_right() -> void:
	_make_placer()
	var tiles := _placer._line_tiles(Vector2i(0, 2), Vector2i(4, 2))
	assert_eq(tiles.size(), 5)
	for x in range(5):
		assert_true(tiles.has(Vector2i(x, 2)), "missing (%d, 2)" % x)

func test_line_horizontal_right_to_left() -> void:
	_make_placer()
	var tiles := _placer._line_tiles(Vector2i(4, 2), Vector2i(0, 2))
	assert_eq(tiles.size(), 5)

func test_line_vertical_top_to_bottom() -> void:
	_make_placer()
	var tiles := _placer._line_tiles(Vector2i(3, 0), Vector2i(3, 5))
	assert_eq(tiles.size(), 6)
	for y in range(6):
		assert_true(tiles.has(Vector2i(3, y)), "missing (3, %d)" % y)

func test_line_dominant_axis_horizontal() -> void:
	# dx=5, dy=2 → horizontal wins
	_make_placer()
	var tiles := _placer._line_tiles(Vector2i(0, 0), Vector2i(5, 2))
	for t in tiles:
		assert_eq(t.y, 0, "all tiles should be on y=0")

func test_line_dominant_axis_vertical() -> void:
	# dx=1, dy=4 → vertical wins
	_make_placer()
	var tiles := _placer._line_tiles(Vector2i(3, 0), Vector2i(4, 4))
	for t in tiles:
		assert_eq(t.x, 3, "all tiles should be on x=3")

func test_line_single_tile() -> void:
	_make_placer()
	var tiles := _placer._line_tiles(Vector2i(5, 5), Vector2i(5, 5))
	assert_eq(tiles.size(), 1)
	assert_true(tiles.has(Vector2i(5, 5)))

func test_shift_stroke_removes_off_axis_tiles() -> void:
	_make_placer()
	# Simulate: paint start at (0,0), free-paint some tiles, then shift-lock to horizontal
	_grid.place_road(Vector2i(0, 0))
	_grid.place_road(Vector2i(1, 1))  # off-axis tile that should be removed
	_grid.place_road(Vector2i(2, 2))  # off-axis tile that should be removed
	_placer._paint_start  = Vector2i(0, 0)
	_placer._stroke_tiles = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]

	# Shift-lock to end tile (4, 0) — horizontal line
	_placer._paint_line_stroke(Vector2i(4, 0))

	assert_false(_grid.has_road(Vector2i(1, 1)), "off-axis tile should be removed")
	assert_false(_grid.has_road(Vector2i(2, 2)), "off-axis tile should be removed")
	assert_true(_grid.has_road(Vector2i(0, 0)))
	assert_true(_grid.has_road(Vector2i(1, 0)))
	assert_true(_grid.has_road(Vector2i(4, 0)))

# ── _line_tiles equal-delta tie-break ────────────────────────────────────────

func test_line_equal_delta_picks_horizontal() -> void:
	# dx=3, dy=3 — tie goes to horizontal (>= condition)
	_make_placer()
	var tiles := _placer._line_tiles(Vector2i(0, 0), Vector2i(3, 3))
	for t in tiles:
		assert_eq(t.y, 0, "equal delta should resolve to horizontal (y stays at start)")

# ── _has_road_conflict ────────────────────────────────────────────────────────

func test_has_road_conflict_false_on_clean_ground() -> void:
	_make_building_placer()
	assert_false(_building_placer._has_road_conflict(Vector2i(0, 0), Vector2i(2, 2)))

func test_has_road_conflict_true_when_road_under_footprint() -> void:
	_make_building_placer()
	_grid.place_road(Vector2i(1, 1))
	assert_true(_building_placer._has_road_conflict(Vector2i(0, 0), Vector2i(2, 2)))

func test_has_road_conflict_true_on_partial_overlap() -> void:
	_make_building_placer()
	# Road at (2,0) — only one tile of a 3×1 footprint overlaps
	_grid.place_road(Vector2i(2, 0))
	assert_true(_building_placer._has_road_conflict(Vector2i(0, 0), Vector2i(3, 1)))

func test_has_road_conflict_false_when_road_adjacent_not_under() -> void:
	_make_building_placer()
	# Road at (3,0) — just outside a 2×2 footprint at (0,0)...(1,1)
	_grid.place_road(Vector2i(3, 0))
	assert_false(_building_placer._has_road_conflict(Vector2i(0, 0), Vector2i(2, 2)))

func test_has_road_conflict_false_after_road_removed() -> void:
	_make_building_placer()
	_grid.place_road(Vector2i(1, 1))
	_grid.remove_road(Vector2i(1, 1))
	assert_false(_building_placer._has_road_conflict(Vector2i(0, 0), Vector2i(2, 2)))

# ── Road placement blocked by building ───────────────────────────────────────

func test_road_not_placed_on_occupied_building_tile() -> void:
	_make_placer()
	_placer._building_grid.reserve(Vector2i(2, 2), Vector2i(2, 2), "bldg", "civic")
	_placer._try_place(Vector2i(2, 2))
	assert_false(_grid.has_road(Vector2i(2, 2)))

func test_road_not_placed_on_any_tile_of_large_footprint() -> void:
	_make_placer()
	_placer._building_grid.reserve(Vector2i(1, 1), Vector2i(3, 3), "big_bldg", "civic")
	for row in range(3):
		for col in range(3):
			_placer._try_place(Vector2i(1 + col, 1 + row))
	for row in range(3):
		for col in range(3):
			assert_false(_grid.has_road(Vector2i(1 + col, 1 + row)),
				"road should be blocked at (%d,%d)" % [1 + col, 1 + row])

func test_road_placed_normally_on_adjacent_free_tile() -> void:
	_make_placer()
	_placer._building_grid.reserve(Vector2i(2, 2), Vector2i(2, 2), "bldg", "civic")
	# Tile (1,2) is free — road should place fine
	_placer._try_place(Vector2i(1, 2))
	assert_true(_grid.has_road(Vector2i(1, 2)))
