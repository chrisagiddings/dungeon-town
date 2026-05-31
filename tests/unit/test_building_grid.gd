extends GutTest
## Unit tests for BuildingGrid.

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
	assert_false(_grid.can_place(Vector2i(1, 1), Vector2i(2, 2)))

func test_can_place_adjacent_no_overlap() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	assert_true(_grid.can_place(Vector2i(2, 0), Vector2i(2, 2)))

# ── reserve and instance IDs ──────────────────────────────────────────────────

func test_reserve_returns_non_empty_instance_id() -> void:
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	assert_ne(iid, "")

func test_reserve_instance_id_contains_data_id() -> void:
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	assert_true(iid.begins_with("bldg_a"), "instance_id should start with data_id")

func test_reserve_two_same_type_get_unique_ids() -> void:
	var iid1 := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	var iid2 := _grid.reserve(Vector2i(5, 5), Vector2i(2, 2), "bldg_a", "civic")
	assert_ne(iid1, iid2, "Two placements of the same building should get distinct instance IDs")

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

func test_get_occupant_returns_instance_id() -> void:
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg_a", "civic")
	assert_eq(_grid.get_occupant(Vector2i(0, 0)), iid)

func test_unoccupied_tile_returns_empty_string() -> void:
	assert_eq(_grid.get_occupant(Vector2i(9, 9)), "")

# ── instance queries ──────────────────────────────────────────────────────────

func test_get_data_id_for_instance_returns_data_id() -> void:
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "lodging_t1", "hospitality")
	assert_eq(_grid.get_data_id_for_instance(iid), "lodging_t1")

func test_get_placement_for_instance_returns_correct_origin() -> void:
	var iid := _grid.reserve(Vector2i(3, 4), Vector2i(2, 2), "bldg_a", "civic")
	var p   := _grid.get_placement_for_instance(iid)
	assert_eq(p["origin"], Vector2i(3, 4))

func test_get_placement_for_unknown_instance_returns_empty() -> void:
	var p := _grid.get_placement_for_instance("does_not_exist")
	assert_true(p.is_empty())

# ── release ───────────────────────────────────────────────────────────────────

func test_release_frees_tiles() -> void:
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.release(iid)
	assert_false(_grid.is_tile_occupied(Vector2i(0, 0)))
	assert_false(_grid.is_tile_occupied(Vector2i(1, 1)))

func test_release_removes_placement_record() -> void:
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.release(iid)
	assert_eq(_grid.get_placement_count(), 0)

func test_release_only_removes_target_building() -> void:
	var iid_a := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.reserve(Vector2i(5, 5), Vector2i(2, 2), "bldg_b", "civic")
	_grid.release(iid_a)
	assert_false(_grid.is_tile_occupied(Vector2i(0, 0)))
	assert_true(_grid.is_tile_occupied(Vector2i(5, 5)))
	assert_eq(_grid.get_placement_count(), 1)

func test_can_place_again_after_release() -> void:
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.release(iid)
	assert_true(_grid.can_place(Vector2i(0, 0), Vector2i(2, 2)))

func test_release_two_same_type_only_removes_one() -> void:
	var iid1 := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.reserve(Vector2i(5, 5), Vector2i(2, 2), "bldg_a", "civic")
	_grid.release(iid1)
	assert_false(_grid.is_tile_occupied(Vector2i(0, 0)))
	assert_true(_grid.is_tile_occupied(Vector2i(5, 5)))
	assert_eq(_grid.get_placement_count(), 1)

# ── clear ─────────────────────────────────────────────────────────────────────

func test_clear_removes_all_placements() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "bldg_a", "civic")
	_grid.reserve(Vector2i(5, 5), Vector2i(2, 2), "bldg_b", "civic")
	_grid.clear()
	assert_eq(_grid.get_placement_count(), 0)
	assert_false(_grid.is_tile_occupied(Vector2i(0, 0)))

func test_clear_resets_instance_counter() -> void:
	_grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg_a", "civic")
	_grid.clear()
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(1, 1), "bldg_a", "civic")
	assert_true(iid.ends_with("_0001"), "Counter should reset to 1 after clear")
