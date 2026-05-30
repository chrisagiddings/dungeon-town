extends GutTest
## Unit tests for BuildingGrid.
## Instantiates a fresh BuildingGrid per test — pure data/logic, no scene needed.

var _grid: BuildingGrid

func before_each() -> void:
	_grid = BuildingGrid.new()
	add_child_autofree(_grid)

# ── get_tiles ─────────────────────────────────────────────────────────────────

func test_get_tiles_1x1() -> void:
	var tiles := _grid.get_tiles(Vector2i(2, 3), Vector2i(1, 1))
	assert_eq(tiles.size(), 1)
	assert_true(tiles.has(Vector2i(2, 3)))

func test_get_tiles_2x2() -> void:
	var tiles := _grid.get_tiles(Vector2i(0, 0), Vector2i(2, 2))
	assert_eq(tiles.size(), 4)
	assert_true(tiles.has(Vector2i(0, 0)))
	assert_true(tiles.has(Vector2i(1, 0)))
	assert_true(tiles.has(Vector2i(0, 1)))
	assert_true(tiles.has(Vector2i(1, 1)))

func test_get_tiles_3x2() -> void:
	var tiles := _grid.get_tiles(Vector2i(1, 1), Vector2i(3, 2))
	assert_eq(tiles.size(), 6)

func test_get_tiles_origin_offsets_correctly() -> void:
	var tiles := _grid.get_tiles(Vector2i(5, 5), Vector2i(2, 2))
	assert_true(tiles.has(Vector2i(5, 5)))
	assert_true(tiles.has(Vector2i(6, 5)))
	assert_true(tiles.has(Vector2i(5, 6)))
	assert_true(tiles.has(Vector2i(6, 6)))

# ── is_in_bounds ──────────────────────────────────────────────────────────────

func test_in_bounds_valid_placement() -> void:
	assert_true(_grid.is_in_bounds(Vector2i(0, 0), Vector2i(2, 2)))

func test_in_bounds_at_grid_edge() -> void:
	assert_true(_grid.is_in_bounds(Vector2i(18, 18), Vector2i(2, 2)))

func test_out_of_bounds_negative_origin() -> void:
	assert_false(_grid.is_in_bounds(Vector2i(-1, 0), Vector2i(2, 2)))

func test_out_of_bounds_exceeds_grid_x() -> void:
	assert_false(_grid.is_in_bounds(Vector2i(19, 0), Vector2i(2, 2)))

func test_out_of_bounds_exceeds_grid_y() -> void:
	assert_false(_grid.is_in_bounds(Vector2i(0, 19), Vector2i(2, 2)))

func test_out_of_bounds_exactly_one_over() -> void:
	# Grid is 20×20, origin 19 + footprint 2 = 21 — out of bounds
	assert_false(_grid.is_in_bounds(Vector2i(19, 0), Vector2i(2, 1)))

# ── can_place ─────────────────────────────────────────────────────────────────

func test_can_place_on_empty_grid() -> void:
	assert_true(_grid.can_place(Vector2i(0, 0), Vector2i(2, 2)))

func test_cannot_place_out_of_bounds() -> void:
	assert_false(_grid.can_place(Vector2i(19, 19), Vector2i(2, 2)))

func test_cannot_place_on_occupied_tile() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	assert_false(_grid.can_place(Vector2i(0, 0), Vector2i(2, 2)))

func test_cannot_place_partial_overlap() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	# Offset by 1 — shares one tile
	assert_false(_grid.can_place(Vector2i(1, 1), Vector2i(2, 2)))

func test_can_place_adjacent_no_overlap() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	assert_true(_grid.can_place(Vector2i(2, 0), Vector2i(2, 2)))

# ── reserve ───────────────────────────────────────────────────────────────────

func test_reserve_marks_tiles_occupied() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	assert_true(_grid.is_tile_occupied(Vector2i(0, 0)))
	assert_true(_grid.is_tile_occupied(Vector2i(1, 0)))
	assert_true(_grid.is_tile_occupied(Vector2i(0, 1)))
	assert_true(_grid.is_tile_occupied(Vector2i(1, 1)))

func test_reserve_records_placement() -> void:
	_grid.reserve(Vector2i(3, 3), Vector2i(2, 2), "bldg_a", "civic")
	assert_eq(_grid.get_placement_count(), 1)

func test_reserve_multiple_placements() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.reserve(Vector2i(5, 5), Vector2i(2, 2), "bldg_b", "civic")
	assert_eq(_grid.get_placement_count(), 2)

func test_reserve_emits_building_placed_signal() -> void:
	watch_signals(EventBus)
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	assert_signal_emitted(EventBus, "building_placed")

func test_get_occupant_returns_building_id() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg_a", "civic")
	assert_eq(_grid.get_occupant(Vector2i(0, 0)), "bldg_a")

func test_unoccupied_tile_returns_empty_string() -> void:
	assert_eq(_grid.get_occupant(Vector2i(9, 9)), "")

# ── release ───────────────────────────────────────────────────────────────────

func test_release_frees_tiles() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.release("bldg_a")
	assert_false(_grid.is_tile_occupied(Vector2i(0, 0)))
	assert_false(_grid.is_tile_occupied(Vector2i(1, 1)))

func test_release_removes_placement_record() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.release("bldg_a")
	assert_eq(_grid.get_placement_count(), 0)

func test_release_only_removes_target_building() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.reserve(Vector2i(5, 5), Vector2i(2, 2), "bldg_b", "civic")
	_grid.release("bldg_a")
	assert_false(_grid.is_tile_occupied(Vector2i(0, 0)))
	assert_true(_grid.is_tile_occupied(Vector2i(5, 5)))
	assert_eq(_grid.get_placement_count(), 1)

func test_can_place_again_after_release() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.release("bldg_a")
	assert_true(_grid.can_place(Vector2i(0, 0), Vector2i(2, 2)))

# ── clear ─────────────────────────────────────────────────────────────────────

func test_clear_removes_all_placements() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.reserve(Vector2i(5, 5), Vector2i(2, 2), "bldg_b", "civic")
	_grid.clear()
	assert_eq(_grid.get_placement_count(), 0)
	assert_false(_grid.is_tile_occupied(Vector2i(0, 0)))
