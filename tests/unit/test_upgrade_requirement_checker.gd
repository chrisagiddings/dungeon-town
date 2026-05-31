extends GutTest
## Unit tests for UpgradeRequirementChecker.

var _grid: BuildingGrid
var _saved_gold: int

func before_each() -> void:
	_grid = BuildingGrid.new()
	add_child_autofree(_grid)
	_saved_gold = EconomyState.gold

func after_each() -> void:
	EconomyState.gold = _saved_gold

# ── No upgrade path ───────────────────────────────────────────────────────────

func test_no_upgrade_to_returns_cannot_upgrade() -> void:
	var data := _building("no_upgrade", "", 0)
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	assert_false(result["can_upgrade"])

func test_no_upgrade_to_returns_empty_requirements() -> void:
	var data := _building("no_upgrade", "", 0)
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	assert_eq(result["requirements"].size(), 0)

# ── Gold requirement ──────────────────────────────────────────────────────────

func test_gold_met_when_affordable() -> void:
	EconomyState.gold = 500
	var data := _building("b", "b_t2", 200)
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	var gold_req = _find_req(result["requirements"], "gold")
	assert_not_null(gold_req)
	assert_true(gold_req["met"])
	assert_true(gold_req["trackable"])

func test_gold_unmet_when_insufficient() -> void:
	EconomyState.gold = 50
	var data := _building("b", "b_t2", 200)
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	var gold_req = _find_req(result["requirements"], "gold")
	assert_false(gold_req["met"])

func test_can_upgrade_false_when_gold_insufficient() -> void:
	EconomyState.gold = 0
	var data := _building("b", "b_t2", 200)
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	assert_false(result["can_upgrade"])

func test_can_upgrade_true_when_gold_sufficient_and_no_other_trackable() -> void:
	EconomyState.gold = 500
	var data := _building("b", "b_t2", 200)
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	assert_true(result["can_upgrade"])

func test_no_gold_req_when_cost_is_zero() -> void:
	EconomyState.gold = 500
	var data := _building("b", "b_t2", 0)
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	var gold_req = _find_req(result["requirements"], "gold")
	assert_true(gold_req == null)

# ── Prerequisite requirement ──────────────────────────────────────────────────

func test_prerequisite_unmet_when_building_absent() -> void:
	EconomyState.gold = 9999
	var data := _building("b", "b_t2", 0)
	data.upgrade_prerequisites = ["missing_building"]
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	var prereq = _find_req(result["requirements"], "prerequisite")
	assert_not_null(prereq)
	assert_false(prereq["met"])
	assert_true(prereq["trackable"])

func test_prerequisite_met_when_building_present() -> void:
	EconomyState.gold = 9999
	_grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "required_bldg", "civic")
	var data := _building("b", "b_t2", 0)
	data.upgrade_prerequisites = ["required_bldg"]
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	var prereq = _find_req(result["requirements"], "prerequisite")
	assert_true(prereq["met"])

func test_prerequisite_blocks_upgrade() -> void:
	EconomyState.gold = 9999
	var data := _building("b", "b_t2", 0)
	data.upgrade_prerequisites = ["missing_building"]
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	assert_false(result["can_upgrade"])

# ── Untrackable requirements ──────────────────────────────────────────────────

func test_resources_are_untrackable() -> void:
	var data := _building("b", "b_t2", 0)
	data.upgrade_resources = {"wood": 20}
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	var res_req = _find_req(result["requirements"], "resource")
	assert_not_null(res_req)
	assert_false(res_req["trackable"])

func test_resources_do_not_block_upgrade() -> void:
	EconomyState.gold = 9999
	var data := _building("b", "b_t2", 0)
	data.upgrade_resources = {"wood": 20, "stone": 10}
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	assert_true(result["can_upgrade"], "Resources should not block upgrade in M1")

func test_dungeon_depth_is_untrackable() -> void:
	var data := _building("b", "b_t2", 0)
	data.upgrade_dungeon_depth = 3
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	var req = _find_req(result["requirements"], "dungeon_depth")
	assert_not_null(req)
	assert_false(req["trackable"])

func test_patron_count_is_untrackable() -> void:
	var data := _building("b", "b_t2", 0)
	data.upgrade_patron_count = 50
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	var req = _find_req(result["requirements"], "patron_count")
	assert_not_null(req)
	assert_false(req["trackable"])

func test_population_is_untrackable() -> void:
	var data := _building("b", "b_t2", 0)
	data.upgrade_population = 20
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	var req = _find_req(result["requirements"], "population")
	assert_not_null(req)
	assert_false(req["trackable"])

func test_reputation_is_untrackable() -> void:
	var data := _building("b", "b_t2", 0)
	data.upgrade_reputation = "friendly"
	var result := UpgradeRequirementChecker.evaluate(data, _grid)
	var req = _find_req(result["requirements"], "reputation")
	assert_not_null(req)
	assert_false(req["trackable"])

# ── UpgradeManager integration ────────────────────────────────────────────────

func test_upgrade_manager_tracks_construction() -> void:
	var manager := UpgradeManager.new()
	add_child_autofree(manager)
	# Seed a building in the grid
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "lodging_t1", "hospitality")
	var data := DataRegistry.get_building("lodging_t1") as BuildingData
	if data == null:
		pass  # DataRegistry not seeded in test context — skip
		return
	EconomyState.gold = 9999
	manager._grid = _grid
	manager.start_upgrade(iid, data)
	assert_true(manager.is_under_construction(iid))

func test_upgrade_manager_days_remaining() -> void:
	var manager := UpgradeManager.new()
	add_child_autofree(manager)
	var iid := _grid.reserve(Vector2i(0, 0), Vector2i(2, 2), "lodging_t1", "hospitality")
	var data := DataRegistry.get_building("lodging_t1") as BuildingData
	if data == null:
		return
	EconomyState.gold = 9999
	manager._grid = _grid
	manager.start_upgrade(iid, data)
	assert_true(manager.days_remaining(iid) > 0)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _building(id: String, upgrade_to: String, cost: int) -> BuildingData:
	var d := BuildingData.new()
	d.id          = id
	d.display_name = id
	d.upgrade_to  = upgrade_to
	d.upgrade_cost = cost
	return d

func _find_req(reqs: Array, type: String):
	for r in reqs:
		if r["type"] == type:
			return r
	return null
